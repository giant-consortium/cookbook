---
layout: default
---

<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./../ind_geno_qc.html">⬅️ Back to Sample &amp; Genotype QC</a>
</div>

# Handling Studies Genotyped on Multiple Arrays

See also: [Sample & Genotype QC Pipeline](./ind_geno_qc_detailed.html) · [Multi-array post-impute merge container README](https://github.com/giant-consortium/sample_variant_qc/tree/main/containers/multi_array_post_impute_merge#readme) · [GWAS Pipeline](./../gwas.html)

A study genotyped on more than one array (or recruited in separate batches) needs each
batch QC'd and imputed on its own, then merged and re-PC'd after imputation before
GWAS. This page covers that end-to-end flow.

---

## Contents

| # | Section | Description |
| --- | --------- | ------------- |
| 1 | [Genotype QC](#genotype-qc) | Run per batch, separately |
| 2 | [Phenotype QC](#phenotype-qc) | Run once, across all batches |
| 3 | [Imputation](#imputation) | TOPMed, per batch, separately |
| 4 | [Post-impute merge & ancestry-specific PCA](#post-impute-merge) | `containers/multi_array_post_impute_merge/` |
| 5 | [Adding the batch covariate](#batch-covariate) | Manual step, after the container runs |
| 6 | [GWAS](#gwas) | Runs on the original per-batch VCFs, not the merged output |

---

<a id="genotype-qc"></a>

## 1. Genotype QC

Run the [Sample & Genotype QC Pipeline](./ind_geno_qc_detailed.html) on **each batch
separately**. Build conversion (hg38), strand alignment, and palindromic SNP
resolution are all handled by the pipeline, so these don't need to be done manually
before merging.

The QC'd PLINK files feed into the [Pre-phasing Pipeline](./../pre_phasing_checks.html).
The output from the pre-phasing step is then uploaded to an imputation server.

---

<a id="phenotype-qc"></a>

## 2. Phenotype QC

Run the Phenotype QC Pipeline on **all batches together**.

---

<a id="imputation"></a>

## 3. Imputation

Run [Imputation](./topmed_imputation.html) for **each batch separately**. The inputs
are the VCFs produced by the [Pre-phasing Pipeline](./../pre_phasing_checks.html) at:

```
<out_dir>/vcfs_for_phasing_imputation/
```

TOPMed returns encrypted result archives. See
[TOPMed Imputation: Decrypting results](./topmed_imputation.html#decrypt) for how to
open them by hand. Alternatively, pass the password straight to the post-impute merge container
below (`path_to_topmed_zip_password_file`), which unpacks `chr<N>.zip` automatically.
Imputed output is one gzipped VCF per chromosome (`chr1`-`chr22`, `chrX`).

---

<a id="post-impute-merge"></a>

## 4. Post-impute merge & ancestry-specific PCA

**Container:** [`containers/multi_array_post_impute_merge/`](https://github.com/giant-consortium/sample_variant_qc/tree/main/containers/multi_array_post_impute_merge) ·
**Scripts:** `run_postimpute_pipeline.sh` (unpack, merge, variant selection, region
exclusion, duplicate/kinship check), `Step9_postimpute_AncestrySpecificPCA.sh`
(ancestry-specific PCA)

Per-batch PCs are no longer valid once batches are merged, and a naive pooled merge +
pooled PCA has two problems: it mixes ancestries (so the top PCs mostly just recover
ancestry, not within-ancestry structure useful as a GWAS covariate) and it leaves
within-cohort relatedness unadjusted. The `multi_array_post_impute_merge` container
handles both: PCs are computed **per ancestry only**, on each ancestry's own unrelated
subset, with related samples projected back on afterwards. Run it instead of merging
and re-PC'ing by hand.

### Running it

```bash
git clone git@github.com:giant-consortium/sample_variant_qc.git -b multi_array_tester --single-branch
cd sample_variant_qc/containers/multi_array_post_impute_merge
# edit parameters.txt: path_to_batches, path_to_ancestry_predictions,
# path_to_output, study_name, chromosomes
chmod +x POST_IMPUTE_MERGE_RUNNER.sh
./POST_IMPUTE_MERGE_RUNNER.sh        # defaults to --apptainer; or --docker / --singularity
```

`multi_array_tester` is the stable branch; development happens on `multi_array_post_impute_merge`, which may be ahead of it. The `parameters.txt` in this folder ships pointed at the bundled example (`test_inputs/example`), so run it unedited first to confirm your setup, then compare the output against `test_inputs/example/EXPECTED_RESULTS.md`.

`path_to_ancestry_predictions` is **required** and is a tab-separated file with a
header row and two columns, `IID` then `ancestry` (e.g. each batch's `<study_name>_AncestryPredictions.txt` from its own Sample & Genotype QC run, Step 8). Only columns 1 and 2 are read, so that file can be passed in unchanged. Unlike the single-study
pipeline, this container does not predict ancestry itself -- there's no reference-panel
projection step here, because ancestry predictions are supplied as an input.

### Pipeline steps

0. **Unpack TOPMed results**, if delivered as password-protected `.zip` files (one-time, before any chromosome is touched).

Then, per chromosome:

1. **(optional, on by default) per-cohort R2 filter** -- each batch's own VCF is filtered to that batch's own well-imputed variants (real, per-batch `INFO/R2`) before merging, since after merging those INFO fields are stripped and no longer reliable. Threshold: `info_thresh` (default `0.8`); toggle with `per_cohort_r2_filter_enabled`.
2. **Merge** all batches (`bcftools merge --merge none`), set canonical `chr:pos:ref:alt` IDs, strip the now-stale per-batch INFO fields.
3. **Select PCA-candidate variants**: recompute AF fresh on the pooled, merged genotypes and keep biallelic SNPs above `maf_thresh` (default 0.01).
4. **Convert to PLINK** and **exclude long-range-LD/problematic regions** (MHC, chr8/chr17 inversions, etc.) -- this does not LD-prune; pruning is deferred entirely to step 7.

Then, once every chromosome is done:

5. **Combine** the per-chromosome PCA-candidate sets into one genome-wide set.
6. **KING kinship + duplicate removal**: catches the same person recruited into more than one batch/array (kinship ≥ `duplicate_kinship_cutoff`, default 0.354).
7. **Ancestry-specific PCA** (`Step9_postimpute_AncestrySpecificPCA.sh`), per ancestry group:
   - Remove ancestry-specific relatives (KING kinship ≥ `pca_kinship_cutoff`, default 0.0625, i.e. up to 3rd-degree) → that ancestry's unrelated subset.
   - LD-prune the unrelated subset (`prune_window_size`/`prune_num_snps`/`prune_r2_thresh`, default `200 50 0.2`) -- this is the only LD pruning anywhere in the pipeline. Skipped below `prune_min_samples` unrelated samples (default 50), to avoid unstable LD estimates.
   - Run FlashPCA on the pruned, unrelated subset (`ancestry_num_pcs`, default 10).
   - Project the removed relatives back onto that ancestry's PC space.
   - Consolidate all ancestries into `<study_name>_combined_ancestry_pca.tsv`.

All of the parameters above are set in `parameters.txt`, not hard-coded.

### Why this design

- **Relatedness-aware PCA.** Given relatedness within some cohorts, PCs should not be
  computed on everyone and left unadjusted. Removing ancestry-specific relatives before
  PCA and projecting them back on afterwards resolves this.

### Outputs

Under `path_to_output`:

| Path | Contents |
| --- | --- |
| `merged/<STUDY>_merged_chr<N>.vcf.gz` | Per-chromosome merged VCFs (not pruned) |
| `<STUDY>_genomewide_candidates_deduped.*` | Genome-wide PCA-candidate PLINK set, region-excluded and duplicate/MZ-twin-deduplicated (not yet LD-pruned) |
| `Kinship/<STUDY>.kin0`, `Kinship/<STUDY>_king_remove_list.txt` | KING kinship output and duplicate/MZ-twin remove-list |
| `Ancestry/`, `AncestrySpecificPCA/` | Per-ancestry PCA outputs; see `AncestrySpecificPCA/<STUDY>_combined_ancestry_pca.tsv` for the consolidated result used downstream |
| `logs/` | Per-step logs, including FlashPCA's own log (useful if a PC count got capped) |

---

<a id="batch-covariate"></a>

## 5. Adding the batch covariate

Add a `batch` column to the GWAS covariate file (tab-delimited, `FID` and `IID` as the
first two columns, per the [GWAS pipeline](./../gwas.html)) -- this step is manual and
happens outside the container, using its `AncestrySpecificPCA/<STUDY>_combined_ancestry_pca.tsv`
output as the PC columns:

```bash
# batch_labels.txt: one line per sample (FID, IID, batch).
# Assumes each batch_*_samples.txt has FID and IID as its first two columns.
awk 'BEGIN{OFS="\t"} {print $1, $2, "batch_a"}' batch_a_samples.txt >  batch_labels.txt
awk 'BEGIN{OFS="\t"} {print $1, $2, "batch_b"}' batch_b_samples.txt >> batch_labels.txt

# Append a batch column to the combined ancestry-specific PCs, matched on FID + IID.
# Samples missing from every batch list get NA; check for those before running GWAS.
awk 'BEGIN{OFS="\t"}
     NR==FNR { batch[$1 "\t" $2] = $3; next }
     FNR==1  { print $0, "batch"; next }
     { key = $1 "\t" $2; print $0, (key in batch ? batch[key] : "NA") }' \
  batch_labels.txt AncestrySpecificPCA/<STUDY>_combined_ancestry_pca.tsv > covariates_with_batch.tsv
```

In `parameters_gwas.txt`, add `batch` to the **categorical** covariates list. This is a
comma-separated list with no spaces. Append `batch` to whatever columns are already
specified (e.g. ancestry group):

```
cat_covar_col=ancestry,batch
```

---

<a id="gwas"></a>

## 6. GWAS


