---
layout: default
---

<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./../ind_geno_qc.html">⬅️ Back to Sample &amp; Genotype QC</a>
  <a href="./../gwas.html">GWAS Pipeline ➡️</a>
</div>

# Multi-Array Post-Imputation Merge & Ancestry-Specific PCA

Merges per-batch TOPMed-imputed VCFs from a study genotyped on more than one array (or recruited in separate batches). It produces the GWAS input VCF, ancestry-specific PCs, and the files needed for the batch covariate.

Requires Docker, Singularity, or Apptainer; 8 GB+ RAM; 50 GB+ storage; Linux/macOS (Windows via WSL). `wget` is needed on the host (macOS: `brew install wget`).

## Contents

- [Overview](#overview)
- [Branches & Setup](#branches)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Quick Start](#quick-start)
- [Parameters](#parameters)
- [Pipeline Steps](#pipeline-steps)
- [Merging Per-Batch Ancestry Predictions](#ancestry-merge)
- [GWAS Handoff](#gwas-handoff)
- [Troubleshooting](#troubleshooting)

---

<a id="overview"></a>

## Overview

Run these steps before the container:

1. **Sample & Genotype QC** on each batch separately ([Sample & Genotype QC Pipeline](./../ind_geno_qc.html)). This produces a per-batch ancestry predictions file.
2. **Pre-phasing and TOPMed imputation** on each batch separately ([Pre-phasing](./../pre_phasing_checks.html), [TOPMed Imputation](./topmed_imputation.html)).
3. **Combine the per-batch ancestry predictions** into one file ([see below](#ancestry-merge)).

The container then does the rest:

- Filters each batch on imputation quality (R2), merges the batches, and filters the merged data on MAF and HWE. The result is the **GWAS input VCF**, which is not LD-pruned.
- Removes duplicate or MZ-twin samples across batches.
- Computes ancestry-specific PCs (relatives removed, LD pruned, relatives projected back on).

After the container finishes, run the GWAS on the GWAS input VCF with the batch covariate added ([GWAS Handoff](#gwas-handoff)).

---

<a id="branches"></a>

## Branches & Setup

The container lives in the `sample_variant_qc` repository on two branches. Clone the stable branch:

```bash
git clone git@github.com:giant-consortium/sample_variant_qc.git -b multi_array_tester --single-branch
cd sample_variant_qc
```

| Branch | Contents | Use |
| --- | --- | --- |
| `multi_array_tester` | Stable snapshot. Contains only the multi-array container; the repository root is the pipeline folder. | **Clone this to run the pipeline.** |
| `multi_array_post_impute_merge` | Development branch. Contains the container and the single-study pipeline. Can be ahead of `multi_array_tester`. | Developers only |
| `main` | Single-study Sample & Genotype QC pipeline only. Does **not** contain the multi-array container. | Single-study QC |

> **Note:** cloning without `-b multi_array_tester` gives you `main`, which does not contain the multi-array container.

Everything the run needs is at the root of the `multi_array_tester` branch: `POST_IMPUTE_MERGE_RUNNER.sh`, `parameters.txt`, and the pipeline scripts.

---

<a id="inputs"></a>

## Inputs

| Input | Location | Required | Notes |
| --- | --- | --- | --- |
| Per-batch imputed VCFs | `path_to_batches/<batch_name>/chr<N>.dose.vcf.gz` (or plain `.dose.vcf`) | Yes | One subfolder per batch. Each file needs `GT` and `INFO/R2`. Every batch should have the same chromosomes listed in `chromosomes`. |
| TOPMed result archives | `path_to_batches/<batch_name>/chr<N>.zip` | Only if still zipped | Set `path_to_topmed_zip_password_file`. Unpacked automatically. Leave blank if your files are already unzipped. |
| Ancestry predictions | `path_to_ancestry_predictions` | Yes | **One** file for all batches. Tab-separated, with a header row, then `IID` and `ancestry`. See [Merging Per-Batch Ancestry Predictions](#ancestry-merge). |
| Parameters | `parameters.txt` in the container folder | Yes | See [Parameters](#parameters). |

**Requirements on the input data:**

- **Sample IDs must be unique across all batches.** The merge fails on duplicate sample names. The same person in two batches can have two different IIDs. Duplicate removal handles that case.
- **Long-range-LD exclusion list:** no reference download is needed. The exclusion list ships inside the container image.

---

<a id="outputs"></a>

## Outputs

All outputs are written under `path_to_output`.

### GWAS input

Everything in `GWAS_input/` is the GWAS input. Nothing else in the output folder is.

| File | Description |
| --- | --- |
| `GWAS_input/<STUDY>_GWAS_input.vcf.gz` (+ `.tbi`) | **GWAS input.** All chromosomes combined, pre-pruning. Not LD-pruned; long-range-LD regions (including the MHC) are not excluded. Biallelic SNPs with R2 above `info_thresh` (applied per batch), MAF above `maf_thresh`, and HWE p above the study threshold. Duplicate/MZ samples removed. INFO has `AF`, `MAF`, and `HWE` recomputed on the pooled samples. |
| `GWAS_input/chr<N>.vcf.gz` (+ `.tbi`) | The same content, one file per chromosome. Matches the `chr*` file pattern the GWAS pipeline expects. |

### PCs

| File | Description |
| --- | --- |
| `AncestrySpecificPCA/<STUDY>_combined_ancestry_pca.tsv` | **Covariates for GWAS.** FID, IID, PC1 to PCn for all ancestries combined. |
| `AncestrySpecificPCA/<STUDY>_<ancestry>_PCA.txt` | PCs for one ancestry group. |

### Intermediate and QC files

| Path | Description |
| --- | --- |
| `Kinship/<STUDY>.kin0`, `Kinship/<STUDY>_king_remove_list.txt` | KING kinship output and the duplicate/MZ-twin remove-list. |
| `merged/<STUDY>_merged_chr<N>.vcf.gz` | Per-chromosome merged VCFs with no MAF or HWE filter. **Not for GWAS.** |
| `pca_candidates/`, `pca_candidates_plink/`, `<STUDY>_genomewide_candidates_deduped.*` | PCA-candidate variant lists and PLINK sets before ancestry-specific LD pruning. |
| `logs/` | Per-step logs, including FlashPCA's log. |

---

<a id="quick-start"></a>

## Quick Start

To check your setup first, run the pipeline unedited on the bundled example. Then compare against `test_inputs/example/EXPECTED_RESULTS.md`.

```bash
git clone git@github.com:giant-consortium/sample_variant_qc.git -b multi_array_tester --single-branch
cd sample_variant_qc
chmod +x POST_IMPUTE_MERGE_RUNNER.sh
./POST_IMPUTE_MERGE_RUNNER.sh        # defaults to --apptainer; or --docker / --singularity
```

The example writes to `./output`. The first run downloads the container image (about 1.7 GB) and caches it.

Then edit `parameters.txt` for your study. At minimum, set:

```bash
path_to_batches=/path/to/your/batches
path_to_ancestry_predictions=/path/to/ancestry_predictions.txt
path_to_output=/path/to/where/output/should/go
study_name=YOUR_STUDY
chromosomes="1 2 3 ... 22 X"
study_anc_expectation=HET          # HOM or HET; see Parameters
```

Run it again:

```bash
./POST_IMPUTE_MERGE_RUNNER.sh
```

Use `--parameters-file /path/to/copy.txt` to keep a study-specific parameters file outside this folder.

> **Quote multi-word values** such as `chromosomes="1 2"`. Apptainer evaluates `parameters.txt` as a shell script, so an unquoted value like `chromosomes=1 2` fails.

---

<a id="parameters"></a>

## Parameters

All parameters are in `parameters.txt`. Defaults are shown.

| Parameter | Default | Description |
| --- | --- | --- |
| `path_to_batches` | (example data) | Folder with one subfolder per batch. |
| `path_to_ancestry_predictions` | (example data) | Required. The single combined ancestry-predictions file. |
| `path_to_output` | `./output` | Output folder. |
| `study_name` | `STUDY` | Prefix for all output files. |
| `chromosomes` | `"1 2"` (example) | Space-separated list. Quote it. |
| `path_to_topmed_zip_password_file` | blank | Password file for TOPMed `.zip` archives. Blank if already unzipped. |
| `per_cohort_r2_filter_enabled` | `true` | Filter each batch on R2 before merging. |
| `info_thresh` | `0.8` | R2 threshold for the per-batch filter. |
| `maf_thresh` | `0.01` | Keep variants with MAF above this value (pooled, after merging). |
| `study_anc_expectation` | `HET` | `HOM` (predominantly one ancestry, HWE p > 1e-6) or `HET` (mixed, HWE p > 1e-12). |
| `use_custom_hwe_thresh` | `FALSE` | Set `TRUE` to use `variant_hwe_thresh` instead. |
| `variant_hwe_thresh` | (unset) | Custom HWE p-value threshold. Used only when `use_custom_hwe_thresh=TRUE`. |
| `exclude_long_range_ld` | `true` | Exclude long-range-LD regions from the PCA path only. |
| `prune_window_size` / `prune_num_snps` / `prune_r2_thresh` | `200` / `50` / `0.2` | LD pruning, applied per ancestry for PCA only. |
| `prune_min_samples` | `50` | Skip LD pruning below this many unrelated samples in an ancestry. |
| `duplicate_kinship_cutoff` | `0.354` | KING kinship above which a pair is treated as the same person. Those samples are removed from the GWAS input. |
| `pca_kinship_cutoff` | `0.0625` | KING kinship above which relatives are removed before PCA (up to 3rd-degree) and projected back. |
| `ancestry_num_pcs` | `10` | Number of PCs per ancestry group. |

---

<a id="pipeline-steps"></a>

## Pipeline Steps

**Step 0: unpack TOPMed results.** Any `chr<N>.zip` files in a batch folder are unpacked with the password file. This runs once, before any chromosome is processed.

Then, for each chromosome:

1. **Per-batch R2 filter.** Each batch's VCF keeps variants with `INFO/R2` above `info_thresh`. This happens before merging, because the merged file's INFO fields are not reliable.
2. **Merge batches** (`bcftools merge --merge none`), set IDs to `chr:pos:ref:alt`, and remove the per-batch INFO fields.
3. **GWAS filter.** Recompute AF, MAF, and HWE on the pooled genotypes. Keep biallelic SNPs with MAF above `maf_thresh` and HWE p above the study threshold (`study_anc_expectation`, or `variant_hwe_thresh`). The result is written as the per-chromosome GWAS input. **This step does not LD-prune and does not exclude long-range-LD regions.**
4. **PCA candidates.** Take the GWAS-filtered variants, convert them to PLINK, and exclude long-range-LD regions. No LD pruning happens here.

Then, once every chromosome is done:

5. **Concatenate** the per-chromosome GWAS inputs into `GWAS_input/<STUDY>_GWAS_input.vcf.gz`. Every chromosome must contain the same samples in the same order. The pipeline stops with an error if they differ, which happens when a batch is missing a chromosome.
6. **KING kinship and duplicate removal.** Find samples that are duplicates or MZ twins across batches (kinship at or above `duplicate_kinship_cutoff`). Remove them from the PCA set and from the GWAS input.
7. **Ancestry-specific PCA** (`Step9_postimpute_AncestrySpecificPCA.sh`), for each ancestry group:
   - Remove ancestry-specific relatives (kinship at or above `pca_kinship_cutoff`).
   - LD-prune the remaining unrelated samples, using `prune_*`. Skipped below `prune_min_samples`.
   - Run FlashPCA on the pruned, unrelated set (`ancestry_num_pcs` PCs).
   - Project the removed relatives back onto those PCs.
   - Combine all ancestry groups into `<STUDY>_combined_ancestry_pca.tsv`.

---

<a id="ancestry-merge"></a>

## Merging Per-Batch Ancestry Predictions

The pipeline needs **one** ancestry file for all batches: a tab-separated file with a header row, then `IID` and `ancestry` as the first two columns. Extra columns are ignored.

Each batch's Sample & Genotype QC run writes `<study_name>_AncestryPredictions.txt` to `<output>/<study_name>_Outputs/PostSampleVariantQC/`. Copy one per batch into a folder named after the batch, then run this from the folder that contains them. Edit the file list to match your batches:

```bash
out=ancestry_predictions.txt
log=ancestry_predictions.merge_log.txt
files="batch_a/STUDY_AncestryPredictions.txt batch_b/STUDY_AncestryPredictions.txt"

{
  echo "Merged ancestry predictions: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "Inputs:"
  for f in $files; do echo "  $f ($(( $(wc -l < "$f") - 1 )) samples)"; done
} > "$log"

{
  printf "IID\tancestry\n"
  for f in $files; do
    tail -n +2 "$f" | awk -F'\t' 'BEGIN{OFS="\t"} {print $1, $2}'
  done
} | awk -F'\t' '
  NR == 1 { print; next }
  {
    total++
    if ($1 in label) {
      if (label[$1] == $2) { dup++ }
      else { conflict++; print "CONFLICT\t" $1 "\t" label[$1] "\t" $2 > "/dev/stderr" }
    } else {
      label[$1] = $2; written++; print
    }
  }
  END {
    printf "Rows read: %d | IIDs written: %d | duplicate rows collapsed: %d | conflicting IIDs: %d\n", total, written, dup, conflict > "/dev/stderr"
    exit (conflict > 0)
  }' > "$out" 2>> "$log"
status=$?
cat "$log"
if [ "$status" -eq 0 ]; then echo "Wrote $out"; else echo "FAILED: resolve the CONFLICT lines in $log before running the pipeline"; fi
```

**What the snippet does and records:**

- `ancestry_predictions.txt` is the pipeline input. It has one row per IID.
- `ancestry_predictions.merge_log.txt` is the merge record. It lists each input file and its sample count, the number of rows read, the IIDs written, duplicate rows collapsed, and any conflicts. Keep this file with the run.
- The same IID in two batches with the **same** label is collapsed to one row. The same IID with **different** labels stops the merge. Each conflict is listed as a `CONFLICT` line in the log. Resolve these before running the pipeline.

When the pipeline starts, it also writes the ancestry file's path, the sample count, and the count per ancestry to its run log under `logs/`. It refuses to run if any IID appears twice in the file.

Set `path_to_ancestry_predictions` to `ancestry_predictions.txt`.

---

<a id="gwas-handoff"></a>

## GWAS Handoff

Run the GWAS on the container's GWAS input, not on the per-batch VCFs. See the [GWAS Pipeline](./../gwas.html) page for the full setup. For this study:

- **Genotypes:** set `path_to_imputed_data` to `<path_to_output>/GWAS_input` and `imputed_file_pattern=chr*`. The combined `<STUDY>_GWAS_input.vcf.gz` does not match `chr*`, so the GWAS reads the per-chromosome files. Set `genotype_output_format` to `pgen` (hard calls) or `bgen` (keeps continuous dosages).
- **Covariates:** use `AncestrySpecificPCA/<STUDY>_combined_ancestry_pca.tsv`, plus the batch covariate below.

### Adding the batch covariate

Add a `batch` column to the GWAS covariate file. The first two columns must be `FID` and `IID`. In this pipeline FID is always set equal to IID.

Create one sample list per batch from any chromosome file in that batch:

```bash
bcftools query -l batch_a/chr1.dose.vcf.gz | awk 'BEGIN{OFS="\t"} {print $1, $1}' > batch_a_samples.txt
bcftools query -l batch_b/chr1.dose.vcf.gz | awk 'BEGIN{OFS="\t"} {print $1, $1}' > batch_b_samples.txt
```

Then add the batch labels to the PCs, matched on FID and IID:

```bash
# batch_labels.txt: one line per sample (FID, IID, batch).
awk 'BEGIN{OFS="\t"} {print $1, $2, "batch_a"}' batch_a_samples.txt >  batch_labels.txt
awk 'BEGIN{OFS="\t"} {print $1, $2, "batch_b"}' batch_b_samples.txt >> batch_labels.txt

# Append a batch column to the combined ancestry-specific PCs, matched on FID + IID.
# Samples missing from every batch list get NA; check for those before running GWAS.
awk 'BEGIN{OFS="\t"}
     NR==FNR { batch[$1 "\t" $2] = $3; next }
     FNR==1  { print $0, "batch"; next }
     { key = $1 "\t" $2; print $0, (key in batch ? batch[key] : "NA") }' \
  batch_labels.txt <path_to_output>/AncestrySpecificPCA/<STUDY>_combined_ancestry_pca.tsv > covariates_with_batch.tsv
```

In `parameters_gwas.txt`, add `batch` to the **categorical** covariates. This is a comma-separated list with no spaces:

```
cat_covar_col=ancestry,batch
```

---

<a id="troubleshooting"></a>

## Troubleshooting

- `wget: command not found` on macOS: install it with `brew install wget`.
- `Duplicate sample names`: the same IID appears in two batches. Rename one of them, or check the batch folders.
- `sample list in ... differs from the first chromosome`: a batch is missing a chromosome. Either add it or remove that chromosome from `chromosomes`.
- Pipeline cannot find batches or output: avoid symlinks in `path_to_batches` and `path_to_output`. Use real absolute paths.
- Batch covariate contains `NA`: some samples are not in any batch list. Check the batch lists against the GWAS input.
- Logs: check the `logs/` folder under `path_to_output`.
