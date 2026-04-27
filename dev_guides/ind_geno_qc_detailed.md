---
---

<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./../index.html">⬅️ Return to Homepage</a>
  <a href="./../pre_phasing_checks.html">Go to Step 2 [Pre-Phasing Checks] ➡️</a>
</div>

# Sample Variant QC Pipeline — Implementation Guide

> For setup instructions, input formats, QC thresholds, and usage guidance, see the [Sample Variant QC Pipeline overview](./../ind_geno_qc.html).

## Workflow Diagram

![Sample Variant QC Pipeline Overview](./../diagrams/overview/Overview_SampleVariantQC_Pipeline.png)

---

## Pipeline Steps

| Step | Name | Script | Details |
| ---- | ---- | ------ | ------- |
| 0 | Setup and Format Conversion | `Step0_Setup.sh` | [View →](./ind_geno_qc_step0.html) |
| 1 | Build Detection and Liftover | `Step1_CheckBuild.sh` | [View →](./ind_geno_qc_step1.html) |
| 2 | Pre-QC Statistics | `Step2_PreQC.sh` | [View →](./ind_geno_qc_step2.html) |
| 3 | Basic Sample and Variant-Level QC | `Step3_BasicQC.sh` | [View →](./ind_geno_qc_step3.html) |
| 4 | SNP Intersection and LD Pruning | `Step4_SNPIntersectForPCA.sh` | [View →](./ind_geno_qc_step4.html) |
| 5 | Relatedness Estimation | `Step5_KinshipTest.sh` | [View →](./ind_geno_qc_step5.html) |
| 6 | Principal Component Analysis | `Step6_PCA.sh` | [View →](./ind_geno_qc_step6.html) |
| 7 | Ancestry Prediction | `Step7_AncestryModel.sh` | [View →](./ind_geno_qc_step7.html) |
| 8 | Ancestry-Specific PCA | `Step8_AncestrySpecificPCA.sh` | [View →](./ind_geno_qc_step8.html) |
| 9 | Cleanup and Reporting | `CleanUp.sh` | [View →](./ind_geno_qc_step9.html) |

---

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

## Development Environment (Dockerfile)

**Base System:** Ubuntu 22.04

**Core Tools:**

- **Python3** with pandas, numpy, matplotlib, scipy, json, sklearn
- **R** with data.table, kableExtra, knitr, rmarkdown, pandoc
- **FlashPCA** with dependencies (eigen3, boost, spectra)
- **PLINK2** and **PLINK1.9**

**Installation:** All dependencies installed via apt-get, scripts made executable with chmod
