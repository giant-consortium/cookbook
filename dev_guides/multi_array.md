---
layout: default
---

<style>
  table { font-size: 0.85em; }
  table th, table td { padding: 4px 8px; }
</style>

<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./../ind_geno_qc.html">⬅️ Return to Sample &amp; Genotype QC</a>
  <a href="./../gwas.html">GWAS Pipeline ➡️</a>
</div>

# Multi-Array Post-Imputation Merge & Ancestry PCA

A containerized pipeline for a study genotyped on more than one array, or recruited in separate batches. It merges the per-batch TOPMed-imputed VCFs, computes the GWAS input VCF, removes duplicate samples across batches, and computes ancestry-specific PCs. Requires Docker, Singularity, or Apptainer; 8 GB+ RAM; 50 GB+ storage; Linux/macOS (Windows via WSL). `wget` is needed on the host (macOS: `brew install wget`).

## Contents

- [Quick Start](#quick-start)
- [Merging Per-Batch Ancestry Predictions](#ancestry-merge)
- [Input / Output](#input-output)
- [Default Thresholds](#default-thresholds)
- [Pipeline Overview](#pipeline-overview)
- [GWAS Handoff](#gwas-handoff)
- [Reference Data](#reference-data)
- [Optional Steps](#optional-steps)
- [Troubleshooting](#troubleshooting)

---

<a id="quick-start"></a>

## Quick Start

Before this container, run each batch separately through [Sample & Genotype QC](./../ind_geno_qc.html), [Pre-phasing](./../pre_phasing_checks.html), and [TOPMed Imputation](./topmed_imputation.html). Then combine the per-batch ancestry predictions into one file ([see below](#ancestry-merge)).

1. **Clone the stable branch:**

   ```bash
   git clone git@github.com:giant-consortium/sample_variant_qc.git -b multi_array_tester --single-branch
   cd sample_variant_qc
   chmod +x POST_IMPUTE_MERGE_RUNNER.sh
   ```

   `multi_array_tester` contains only this container, with the repository root as the pipeline folder. The single-study pipeline is on the `main` branch.

2. **Run the example** to check your setup. It uses the bundled two-batch dataset, and the output goes to `./output`:

   ```bash
   ./POST_IMPUTE_MERGE_RUNNER.sh
   ```

   Compare the results with `test_inputs/example/EXPECTED_RESULTS.md`.

3. **Edit `parameters.txt`** for your study. At minimum set:

   ```bash
   study_name=YOUR_STUDY
   study_anc_expectation=HET          # HOM (predominantly one ancestry) or HET (mixed)
   path_to_batches=/absolute/path/to/batches
   path_to_ancestry_predictions=/absolute/path/to/ancestry_predictions.txt
   path_to_output=/absolute/path/to/output
   chromosomes=                       # blank = all chromosomes found; or e.g. 1,2,X
   ```

   Use absolute paths. `chromosomes` takes a comma-separated list with no spaces, so it needs no quotes. See [Choosing chromosomes](#chromosomes) below.

   <a id="chromosomes"></a>

   ### Choosing chromosomes

   | Setting | Runs |
   | --- | --- |
   | `chromosomes=` (blank) | Every chromosome found in the first batch folder (`chr<N>.dose.vcf[.gz]`). Use for a full run. |
   | `chromosomes=1,2,X` | Only the listed chromosomes. Use to re-run a subset. |

   Accepted values are 1 to 22, X, Y, and M, with or without a `chr` prefix. Every listed chromosome must exist in every batch, or the run stops before processing starts. To see what each batch contains before you run:

   ```bash
   # Run from the folder that contains the batch folders
   for b in batch_a batch_b; do
     echo "$b: $(ls $b | sed -nE 's/^chr([0-9XYM]+)\.dose\.vcf(\.gz)?$/\1/p' | sort -uV | tr '\n' ' ')"
   done
   ```

   Each line lists the chromosomes in one batch, for example `batch_a: 1 2 3 ... 22 X`. Any chromosome missing from a batch must be removed from `chromosomes`, or added to that batch.

4. **Run the pipeline:**

   ```bash
   ./POST_IMPUTE_MERGE_RUNNER.sh
   ```

   | Flag | Description |
   |------|-------------|
   | `--docker` | Run using Docker |
   | `--singularity` | Run using Singularity |
   | `--apptainer` | Run using Apptainer *(default)* |
   | `--get_update` | Re-download the container image instead of using the cached copy. Use this after a new build. |
   | `--parameters-file FILE` | Use a study-specific parameters file kept outside this folder |

   The first run downloads the container image (about 1.7 GB) and caches it. The Docker image comes from the `docker_containers/` folder of the GIANT storage bucket, and the Apptainer/Singularity image from `singularity_containers/`.

### What You'll Get

After the pipeline completes, the GWAS input and PCs are in `<path_to_output>`:

- **`GWAS_input/<study_name>_GWAS_input.vcf.gz`** → The GWAS input: all chromosomes combined, not LD-pruned
- **`AncestrySpecificPCA/<study_name>_combined_ancestry_pca.tsv`** → PCs for all ancestries, for the GWAS covariates
- **`AncestrySpecificPCA/<study_name>_<ancestry>_PCA.txt`** → PCs for one ancestry group

> **Note:** `merged/` holds per-chromosome merged VCFs with no MAF or HWE filter. Do not use them for GWAS; use `GWAS_input/`.

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

- `ancestry_predictions.txt` is the pipeline input, with one row per IID.
- `ancestry_predictions.merge_log.txt` is the merge record. It lists each input file and its sample count, the rows read, the IIDs written, duplicate rows collapsed, and any conflicts. Keep it with the run.
- The same IID in two batches with the **same** label is collapsed to one row. The same IID with **different** labels stops the merge; each conflict is listed as a `CONFLICT` line in the log.

The pipeline also logs the ancestry file's path, the sample count, and the count per ancestry. It refuses to run if any IID appears twice in the file.

Set `path_to_ancestry_predictions` to `ancestry_predictions.txt`.

Check the merged file before you run the pipeline:

```bash
head -3 ancestry_predictions.txt                 # header, then the first two samples
tail -n +2 ancestry_predictions.txt | wc -l      # number of samples
tail -n +2 ancestry_predictions.txt | cut -f2 | sort | uniq -c   # samples per ancestry
```

---

<a id="input-output"></a>

## Input / Output

### Accepted Inputs

| Input | Location | Required | Notes |
|-------|----------|----------|-------|
| **Per-batch imputed VCFs** | `path_to_batches/<batch>/chr<N>.dose.vcf.gz` (or plain `.dose.vcf`) | Yes | One subfolder per batch. **Every subfolder of `path_to_batches` is treated as a batch**, so keep only batch folders there. Each file needs `GT` and `INFO/R2`. Plain VCFs are bgzipped and indexed automatically. |
| **Ancestry predictions** | `path_to_ancestry_predictions` | Yes | **One** file for all batches. Tab-separated, with a header row, then `IID` and `ancestry` as the first two columns. See [Merging Per-Batch Ancestry Predictions](#ancestry-merge). |
| **Parameters** | `parameters.txt` in this folder | Yes | See [Default Thresholds](#default-thresholds). |

**Requirements on the input data:**

- **Sample IDs must be unique across all batches.** The merge fails on duplicate sample names. The same person in two batches can have two different IIDs; duplicate removal handles that case.
- **Every batch should have every chromosome listed in `chromosomes`.** A batch missing one stops the run before processing starts. See [Choosing chromosomes](#chromosomes).
- **No reference download is needed.** The long-range-LD exclusion list ships inside the container image.

### Final Deliverables

These are the files to use downstream:

| File | Description |
|------|-------------|
| `GWAS_input/<study_name>_GWAS_input.vcf.gz` (+ `.tbi`) | **GWAS input.** All chromosomes combined, not LD-pruned. Biallelic SNPs with R2 above `info_thresh` (applied per batch), MAF above `maf_thresh`, and HWE above the study threshold. Duplicate/MZ samples removed. `AF`, `MAF`, and `HWE` recomputed on the pooled samples. |
| `GWAS_input/chr<N>.vcf.gz` (+ `.tbi`) | The same content, one file per chromosome. Matches the `chr*` pattern the GWAS pipeline expects. |
| `AncestrySpecificPCA/<study_name>_combined_ancestry_pca.tsv` | **Covariates for GWAS.** FID, IID, and PC1 to PC*n* for all ancestries. |
| `AncestrySpecificPCA/<study_name>_<ancestry>_PCA.txt` | PCs for one ancestry group. |

> **Note:** Samples from small ancestry groups may be absent from the combined file if FlashPCA could not compute the full `ancestry_num_pcs` PCs for that group. Use the per-ancestry files if you need those samples.

### Intermediate Outputs (for QC review)

| Path | Description |
|------|-------------|
| `<study_name>_genomewide_candidates_deduped.*` | PLINK set after duplicate removal, before ancestry-specific pruning |
| `Kinship/` | KING kinship output (`<study_name>.kin0`) and the duplicate/MZ remove list (`<study_name>_king_remove_list.txt`) |
| `merged/` | Per-chromosome merged VCFs with no MAF or HWE filter. **Not for GWAS.** |
| `pca_candidates/`, `pca_candidates_plink/` | PCA-candidate variant sets before ancestry-specific LD pruning |
| `logs/` | Per-step logs, including FlashPCA's log |

---

<a id="default-thresholds"></a>

## Default Thresholds

| Metric | Threshold |
|--------|-----------|
| Imputation quality (R2), per batch, before merging | `info_thresh=0.8` (strict: R2 must be above it) |
| Minor allele frequency, pooled after merging | `maf_thresh=0.01` (MAF must be above it) |
| HWE p-value | `HOM`: > 1e-6 (`study_anc_expectation=HOM`). `HET`: > 1e-12 (`study_anc_expectation=HET`). Set `use_custom_hwe_thresh=TRUE` and `variant_hwe_thresh` to override. |
| Duplicate / MZ twin kinship (KING) | `duplicate_kinship_cutoff=0.354`. Those samples are removed from the GWAS input. |
| Relatives for ancestry PCA (KING) | `pca_kinship_cutoff=0.0625` (up to 3rd degree). Removed before PCA and projected back on afterwards. |
| LD pruning (ancestry PCA only) | `prune_window_size=200`, `prune_num_snps=50`, `prune_r2_thresh=0.2`. Skipped when an ancestry has fewer than `prune_min_samples=50` unrelated samples. |
| Long-range LD regions | Excluded from the PCA path only (`exclude_long_range_ld=true`). Not excluded from the GWAS input. |
| Number of PCs | `ancestry_num_pcs=15` per ancestry group, matching the single-study ancestry PCA (`num_pcs=15`) |

*All thresholds are customizable in `parameters.txt`.*

---

<a id="pipeline-overview"></a>

## Pipeline Overview

| Step | Script | What it does |
|------|--------|-------------|

1. For each chromosome, filters each batch on `INFO/R2 > info_thresh` before merging.
2. Merges the batches (with bcftools, inside the container; you don't run it yourself), sets IDs to `chr:pos:ref:alt`, and strips the per-batch INFO fields.
3. Recomputes AF, MAF, and HWE on the pooled samples. Keeps biallelic SNPs with MAF and HWE above threshold. This is the per-chromosome GWAS input. **No LD pruning and no long-range-LD exclusion.**
4. Converts the GWAS-filtered variants to PLINK and excludes long-range-LD regions for the PCA set only.
5. Concatenates the chromosomes into `GWAS_input/<study_name>_GWAS_input.vcf.gz`. Every chromosome must contain the same samples in the same order.
6. Runs KING on the combined PCA set, removes duplicate/MZ samples from the PCA set and the GWAS input.
7. For each ancestry group: removes relatives, LD-prunes the unrelated samples, runs FlashPCA, projects the relatives back on, and writes the combined PC file.

---

<a id="gwas-handoff"></a>

## GWAS Handoff

Run the GWAS on the container's GWAS input, not on the per-batch VCFs. See the [GWAS Pipeline](./../gwas.html) page for the full setup. For this study:

- **Genotypes:** set `path_to_imputed_data` to `<path_to_output>/GWAS_input` and `imputed_file_pattern=chr*`. The combined `<study_name>_GWAS_input.vcf.gz` does not match `chr*`, so the GWAS reads the per-chromosome files. Set `genotype_output_format` to `pgen` (default, hard calls) or `bgen` (keeps continuous dosages).
- **Covariates:** use `AncestrySpecificPCA/<study_name>_combined_ancestry_pca.tsv`, plus the batch covariate below.

### Adding the Batch Covariate

Add a `batch` column to the GWAS covariate file. The first two columns must be `FID` and `IID`. In this pipeline FID is set equal to IID.

Create one sample list per batch from any chromosome file in that batch:

```bash
# Reads the sample names from the VCF header; no bcftools needed on your machine.
zcat -f batch_a/chr1.dose.vcf.gz | awk -F'\t' 'BEGIN{OFS="\t"} /^#CHROM/ {for(i=10;i<=NF;i++) print $i, $i; exit}' > batch_a_samples.txt
zcat -f batch_b/chr1.dose.vcf.gz | awk -F'\t' 'BEGIN{OFS="\t"} /^#CHROM/ {for(i=10;i<=NF;i++) print $i, $i; exit}' > batch_b_samples.txt
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
  batch_labels.txt <path_to_output>/AncestrySpecificPCA/<study_name>_combined_ancestry_pca.tsv > covariates_with_batch.tsv
```

In the GWAS parameters file, add `batch` to the **categorical** covariates. This is a comma-separated list with no spaces:

```
cat_covar_col=ancestry,batch
```

---

<a id="reference-data"></a>

## Reference Data

- The long-range-LD exclusion list (`/data/hg38_exclusion_list.txt`, MHC and other standard blocks) ships inside the container image. It is not downloaded at run time.
- No other reference data is needed. Ancestry-specific PCA uses only the study's own samples.

---

<a id="optional-steps"></a>

## Optional Steps

These are only needed for specific setups. Skip them if they don't apply to you.

### Unzipping TOPMed Results (optional)

The pipeline unpacks TOPMed `chr<N>.zip` files itself when you set `path_to_topmed_zip_password_file`. Unpack them by hand only if you want to check the files first. This needs `7z`. Install it with one of:

```bash
brew install p7zip                          # macOS
conda install -c conda-forge p7zip          # any system with conda
sudo apt install p7zip-full                 # Debian/Ubuntu
# No package manager: download the static Linux binary (it is named 7zz)
wget https://github.com/ip7z/7zip/releases/download/26.02/7z2602-linux-x64.tar.xz
tar xf 7z2602-linux-x64.tar.xz 7zz && chmod +x 7zz
mkdir -p ~/bin && mv 7zz ~/bin/      # ~/bin must be on your PATH
```

```bash
# Run from the folder that contains the batch folders. The password is typed, not stored.
SEVENZ=$(command -v 7z || command -v 7zz)   # 7zz is the name of the wget binary
[ -n "$SEVENZ" ] || { echo "7z not found: install it first (see above)"; exit 1; }
printf "TOPMed zip password: "; read -rs PW; echo
for batch in batch_a batch_b; do
  for z in "$batch"/chr*.zip; do
    [ -e "$z" ] || continue
    "$SEVENZ" x -p"$PW" -o"$batch" -y "$z" > /dev/null
  done
done
unset PW
```

The files must end up directly in each batch folder (`batch_a/chr1.dose.vcf.gz`), which is where the pipeline looks. The TOPMed imputation page extracts into `chr<N>_imputed/` subfolders instead, so do not use that layout here.

All output paths are relative to `path_to_output`.

### Pre-Merging Batches (optional)

The pipeline merges the batches itself, so most people don't need this. Pre-merge only if you want to check the merged genotypes before the pipeline runs, or to keep the merge outside the container. It does the same two steps the pipeline does: a per-batch `INFO/R2` filter at `info_thresh`, then a `bcftools merge --merge none`. This needs `bcftools` and `tabix` on your computer. The container doesn't need them for this step.

Each run writes to a new folder named with the date and time, such as `premerged_20261010_125620/`. That folder holds only this run's output, so old runs never end up in your pipeline input. Point `path_to_batches` at that folder.

```bash
# Run from the folder that contains the batch folders (batch_a/, batch_b/, ...).
info_thresh=0.8                     # must match info_thresh in parameters.txt
batches="batch_a batch_b"           # one subfolder per batch
chroms="1 2"                        # must match chromosomes in parameters.txt
stamp=$(date +%Y%m%d_%H%M%S)
out_root="premerged_${stamp}"       # new folder every run: holds only this run's output
work="premerge_work/${stamp}"       # scratch, outside the input folder

mkdir "$out_root" && mkdir -p "$out_root/merged" "$work"
for chr in $chroms; do
  filtered=()
  for b in $batches; do
    in="$b/chr${chr}.dose.vcf.gz"
    [ -f "$in" ] || in="$b/chr${chr}.dose.vcf"
    [ -f "$in" ] || { echo "ERROR: no chr${chr} file in $b" >&2; exit 1; }
    f="$work/${b}.chr${chr}.r2.vcf.gz"
    bcftools view -i "INFO/R2>${info_thresh}" -Oz -o "$f" "$in"
    tabix -f -p vcf "$f"
    filtered+=("$f")
  done
  bcftools merge --merge none -Oz -o "$out_root/merged/chr${chr}.dose.vcf.gz" "${filtered[@]}"
  tabix -f -p vcf "$out_root/merged/chr${chr}.dose.vcf.gz"
  echo "chr${chr}: $(bcftools index -n "$out_root/merged/chr${chr}.dose.vcf.gz") records, $(bcftools query -l "$out_root/merged/chr${chr}.dose.vcf.gz" | wc -l) samples"
done
echo "Set path_to_batches=${out_root}/"
```

Then set these in `parameters.txt`:

- `path_to_batches=premerged_<date>_<time>/`, the folder the snippet printed. The pipeline sees one batch, so it skips the merge and only re-IDs the variants.
- `per_cohort_r2_filter_enabled=false`. The R2 filter already ran above. Leaving it on would filter a second time.
- `chromosomes=` the same list you used above.
- `path_to_ancestry_predictions=` still needed, as usual. See [Merging Per-Batch Ancestry Predictions](#ancestry-merge).

Limits to check before you use this route:

- **Sample names must be unique across batches.** `bcftools merge` stops on duplicate sample names. Rename duplicates first (`bcftools reheader --samples`), or use the pipeline's own merge, which has the same requirement.
- **The batch covariate is lost.** After pre-merging, the pipeline sees one batch. If your GWAS needs a batch covariate, keep your own batch list (see [Adding the Batch Covariate](#gwas-handoff)).
- **`info_thresh` and the R2 filter must match.** Change them in both places, or the two filters disagree.

---

<a id="troubleshooting"></a>

## Troubleshooting

- Check `<path_to_output>/logs/` for error messages first.
- Verify all paths in `parameters.txt` are correct and accessible.
- `Duplicate sample names`: the same IID appears in two batches. Rename one of them, or check the batch folders.
- `sample list in ... differs from the first chromosome`: a batch is missing a chromosome.
- `ancestry-predictions file lists these IIDs more than once`: merge the per-batch files with the snippet above, and resolve any conflicts it reports.
- Batch covariate contains `NA`: some samples are not in any batch list. Check the batch lists against the GWAS input.
