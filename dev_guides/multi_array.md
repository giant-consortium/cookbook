---
layout: default
---

<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./../ind_geno_qc.html">⬅️ Back to Sample &amp; Genotype QC</a>
</div>

# Handling Studies Genotyped on Multiple Arrays

## Genotype QC

Run the [Sample & Genotype QC Pipeline](./../ind_geno_qc.html) on **each batch separately**. Build conversion (hg38), strand alignment, and palindromic SNP resolution are all handled by the pipeline, so these don't need to be done manually before merging.

The QC'd PLINK files feed into the [Pre-phasing Pipeline](./../pre_phasing_checks.html). The output from the pre-phasing step is then uploaded to an imputation server.

## Phenotype QC

Run the Phenotype QC Pipeline on **all batches together**.

## Imputation

Run [Imputation](./topmed_imputation.html) for **each batch separately**. The inputs are the VCFs produced by the [Pre-phasing Pipeline](./../pre_phasing_checks.html) at:

```
<out_dir>/vcfs_for_phasing_imputation/
```

TOPMed returns encrypted result archives. See [TOPMed Imputation: Decrypting results](./topmed_imputation.html#decrypt) for how to open them. Imputed output is one gzipped VCF per chromosome (`chr1`-`chr22`, `chrX`).

## Merging imputed data

Merge per-batch imputed VCFs chromosome by chromosome with `bcftools merge`. By default this takes a union of all variant sites, so variants present in only one batch will show as missing (`.`) for samples from other batches. REGENIE handles missing dosages correctly.

```bash
for chr in {1..22} X; do

  # 1. Perform the merge
  bcftools merge \
    batch_a/chr${chr}.dose.vcf.gz \
    batch_b/chr${chr}.dose.vcf.gz \
    --merge none \
    -Oz -o merged_chr${chr}.vcf.gz

  # 2. Update markername to chr:pos:ref:alt as defined in VCF.
  #    This will make it easier to deal with variants lated
  bcftools annotate \
    --set-id '%CHROM:%POS:%REF:%ALT' merged_chr${chr}.vcf.gz \
    -Oz -o merged_chr${chr}.vcf.gz

  # 3. Remove the data from the INFO fields which are based on the first VCF merged only.
  bcftools annotate \
    -x INFO/AF,INFO/MAF,INFO/AVG_CS,INFO/R2 merged_chr${chr}.vcf.gz \
    -Oz -o merged_chr${chr}.vcf.gz

  # 4. Index the vcf
  tabix -p vcf merged_chr${chr}.vcf.gz

done
```

`--merge none` keeps multiallelic sites as separate records rather than collapsing them.



## Recalculating PCs on the merged dataset

Per-batch PCs are no longer valid after merging. Re-run FlashPCA on the merged data using 15 PCs, to match the [Sample Variant QC pipeline](./ind_geno_qc_step6.html).

FlashPCA needs a BED file, so filter to well-imputed common variants and convert dosages to hard calls first.

**1. Use `qctool` to create a list of variants we want to priortise for PCA: INFO > 0.8, MAF > 1%, imputed in everyone. 

```bash
for chr in {1..22}; do
  
  # a. use qctool to generate the required metrics
  qctool -g merged_chr${chr}.vcf.gz \
    -filetype vcf \
    -vcf-genotype-field GP \
    -snp-stats \
    -osnp merged_chr${chr}.snpstats

  # b. identify variants meeting the inclusion criteria 
  awk -v n="$N" '{ 
    if (NF == 26 && 
        $14>0.01 && 
        $17>0.8 && 
        $19<1/n) {
        print $2
    } 
  }' merged_chr${chr}.snpstats > merged_chr${chr}_variant_list_to_prune.txt

  # c. run plink to generate the bed file
  plink2 --vcf merged_chr${chr}.vcf.gz \
    --extract merged_chr${chr}_variant_list_to_prune.txt \
    --make-bed \
    --out merged_chr${chr}_for_pca.txt

done
```

Contact Andy Wood for an alternative script if you are unable to generate the INFO scores and other metrics using QCtool.


**2. Merge chromosomes:**

Place the file prefixes for each chromosome on a separate line (e.g. `plink_list.txt`). Then:

```bash
plink2 --pmerge-list plink_list.txt bfile \
  --make-bed \
  --out pca_merged
```

**3. LD pruning:**

```bash
plink2 --bfile pca_merged \
  --indep-pairwise 1000 100 0.1 \
  --out pca_pruned

plink2 --bfile pca_merged \
  --extract pca_pruned.prune.in \
  --make-bed \
  --out pca_pruned_final
```

**4. Run FlashPCA:**

```bash
flashpca --bfile pca_pruned_final \
  --ndim 15 \
  --outpc merged_pcs.txt \
  --outvec merged_eigenvectors.txt \
  --outval merged_eigenvalues.txt
```

## Adding the batch covariate

Add a `batch` column to the GWAS covariate file (tab-delimited, `FID` and `IID` as the first two columns, per the [GWAS pipeline](./../gwas.html)):

```bash
# Example: create batch labels per sample, then join to existing covariate file
# Assumes each batch has a sample list: batch_a_samples.txt, batch_b_samples.txt

awk 'BEGIN{OFS="\t"} {print $1, $2, "batch_a"}' batch_a_samples.txt > batch_labels.txt
awk 'BEGIN{OFS="\t"} {print $1, $2, "batch_b"}' batch_b_samples.txt >> batch_labels.txt

# Join batch labels with merged PCs
join -t $'\t' -1 2 -2 2 \
  <(sort -k2 existing_covariates.txt) \
  <(sort -k2 batch_labels.txt) \
  > covariates_with_batch.txt
```

In `parameters_gwas.txt`, add `batch` to the **categorical** covariates list. This is a comma-separated list with no spaces — append `batch` to whatever columns are already specified (e.g. ancestry group):

```
cat_covar_col=ancestry,batch
```
