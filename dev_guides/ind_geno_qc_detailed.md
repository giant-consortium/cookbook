---
---

# Sample Variant QC Pipeline — Implementation Guide

See also: [Pipeline overview and QC thresholds](./../ind_geno_qc.html) · [Homepage](./../index.html) · [Workflow diagram](./../diagrams/overview/Overview_SampleVariantQC_Pipeline.png)

---

## Contents

| # | Section | Description |
|---|---------|-------------|
| — | [Runner script](#runner) | Entry point — downloads data, builds image, runs pipeline |
| — | [Reference datasets](#reference) | 1KG/HGDP reference data used for ancestry and QC |
| — | [Development environment](#environment) | Dockerfile and tool versions |
| 0 | [Setup and Format Conversion](./ind_geno_qc_step0.html) | `Step0_Setup.sh` — format conversion, directory setup |
| 1 | [Build Detection and Liftover](./ind_geno_qc_step1.html) | `Step1_CheckBuild.sh` — hg38/hg37 detection, liftover |
| 2 | [Pre-QC Statistics](./ind_geno_qc_step2.html) | `Step2_PreQC.sh` — call rates, HWE, sex check |
| 3 | [Basic Sample and Variant-Level QC](./ind_geno_qc_step3.html) | `Step3_BasicQC.sh` — MAF, MAC, HWE, heterozygosity filters |
| 4 | [SNP Intersection and LD Pruning](./ind_geno_qc_step4.html) | `Step4_SNPIntersectForPCA.sh` — variant harmonisation |
| 5 | [Relatedness Estimation](./ind_geno_qc_step5.html) | `Step5_KinshipTest.sh` — KING via PLINK2 |
| 6 | [Principal Component Analysis](./ind_geno_qc_step6.html) | `Step6_PCA.sh` — FlashPCA, study projection onto reference |
| 7 | [Ancestry Prediction](./ind_geno_qc_step7.html) | `Step7_AncestryModel.sh` — MANCS / Random Forest |
| 8 | [Ancestry-Specific PCA](./ind_geno_qc_step8.html) | `Step8_AncestrySpecificPCA.sh` — per-ancestry projections |
| 9 | [Cleanup and Reporting](./ind_geno_qc_step9.html) | `CleanUp.sh` — final dataset, PDF report |

---

<a id="runner"></a>

## SAMPLE_VARIANT_QC_RUNNER.sh

This file configures paths, performs data downloads, and builds the Docker image. Once built, it calls the Docker image with the passed parameters and executes the complete workflow.

**Key Steps:**

1. **Set mount paths** to study dataset, reference data, build check data and output
2. **Check Docker installation** and verify Docker is running
3. **Download reference data** if not present or if `--force_data_download` flag is set
4. **Build Docker image** if not present or if `--force_build` flag is set
5. **Execute containerized pipeline** with mounted data and parameters

**Performance Notes:**

- Reference data download: ~15 minutes
- Docker image build: ~30 minutes
- Dangling images and volumes are removed during rebuild to save disk space

**Configuration:**

- Mount paths defined in `config/mounts.txt`
- Environment variables set via `config/parameters.txt`
- Both files can be modified between runs without rebuilding the image

---

<a id="reference"></a>

## Reference Datasets

**Data Source:** 1000 Genomes (1KG) and Human Genome Diversity Project (HGDP) datasets, harmonized by gnomAD

**Location:** `gs://gcp-public-data--gnomad/release/3.1.2/mt/genomes/gnomad.genomes.v3.1.2.hgdp_1kg_subset_dense.mt`

**Processing Pipeline:**

1. **Sample filtering:** Excluded low-quality and related samples identified by gnomAD, resulting in **3,280 samples**
2. **Variant QC using PLINK2:**
   - Minor Allele Frequency ≥ 1%
   - Hardy-Weinberg Equilibrium p-value > 1e-6
   - Variant call rate ≥ 98%
   - SNPs only (A,C,G,T restriction)
3. **Final dataset:** **8.15M high-quality variants**
4. **Build availability:** hg38 (primary) and hg37 (liftover)

---

<a id="environment"></a>

## Development Environment (Dockerfile)

**Base System:** Ubuntu 22.04

**Core Tools:**

- **Python3** with pandas, numpy, matplotlib, scipy, json, sklearn
- **R** with data.table, kableExtra, knitr, rmarkdown, pandoc
- **FlashPCA** with dependencies (eigen3, boost, spectra)
- **PLINK2** and **PLINK1.9**

**Installation:** All dependencies installed via apt-get, scripts made executable with chmod
