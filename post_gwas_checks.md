---
---
<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./index.html">⬅️ Return to Homepage</a>
  <a href="./index.html"> 🎉 Upload your Results! 🎉</a>
</div>

# Post Association Checks

## Introduction

This suite of programs is designed to automatically perform **quality control (QC)** of GWAS results.  
Most of the analyses rely on **EasyX**, an R package that combines functions from **EasyStrata** and **EasyQC**.

## Assumptions

Before running the pipeline, ensure the following:

1. **GWAS output** is from **REGENIE** (uncompressed).
2. **Genomic positions** are in **build 38 (hg38)**.
3. **Apptainer** or **Singularity** can be run in your HPC environment.

## Program Overview

Below is a summary of the programs that use EasyX and their functions:

- `1_clean_gwas.R` – Prepares REGENIE GWAS output for **EasyX**.  
- `2_allele_frequency_check.R` – Compares allele frequencies across six genetic ancestries (**AFR**, **AMR**, **MID**, **EUR**, **EAS**, **SAS**).  
- `3_update_cfg_and_run_easyx.R` – Updates the EasyX configuration file with your input data and thresholds, then runs EasyX.  
- `4_report_wrapper.Rmd` – Reads outputs from the previous programs and generates a summary report.  

Additionally, `effects_vs_loadings.R`, checks whether associations are driven by a specific subpopulation (e.g., Finnish among Europeans).  

---

## Quick Start

### Step 1: Clone the GitHub Repository

Navigate to your working directory in your HPC session and clone the repository.  

**Development branch (recommended for testing):**

```bash
git clone --branch tmp_wd --single-branch https://github.com/giant-consortium/post_assoc_checks.git
```

**Main branch:**

```bash
git clone https://github.com/giant-consortium/post_assoc_checks.git
cd post_assoc_checks
```

**Or download as a ZIP and unzip:**
```
unzip post_assoc_checks-main.zip
cd post_assoc_checks-main
```

### STEP 2: Set Up Working Directory

To run the pipeline you will only require to:

1. Move GWAS data to a folder nested in your working directory.
2. Update the parameters file.
3. Download the container image (Singularity or Apptainer).

#### 2.1 Move GWAS Data

Singularity requires that data is nested within your working directory.
Create a test_data folder and copy your GWAS file:

```
mkdir -p test_data
cp /path/to/your/gwas test_data/
```

#### 2.2 Update Parameters File

The parameter file contains variables referencing input/output paths.
We recommend a separate folder per GWAS QC. Example:

```
WD="/maps/projects/kilpelainen-AUDIT/data/team_projects/giant_pc_loadings_tests/post_assoc_checks-tmp_wd"
INPUT_GWAS_TOTAL_PATH="$WD/test_data/STUDYA_HEIGHT.regenie.gz"
OUTPUT_DIR="$WD/test_results/height/"
OUTPUT_NAME="height"
REF_PATH="$WD/ref_data/"
```

**Important**: The output folder must exist beforehand:

```
mkdir -p test_results/height
```

#### 2.3 Obtain Container

If you have Singularity and sudo permissions:
```
sudo singularity pull post_assoc_qc_latest.sif docker://mariogu5/post_assoc_qc:latest
```

Otherwise, download directly:
```
wget https://storage.googleapis.com/giant_deeper_imputation/singularity_containers/post_assoc_qc_latest.sif
```

### Step 3: Run the Pipeline

Ensure Singularity or Apptainer is accessible. For example, if using HPC modules:

```
module load singularity/3.8.7
```

Then execute the pipeline:

```
bash POST_ASSO_PIPELINE.sh
```

