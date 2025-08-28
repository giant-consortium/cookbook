---
---
<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./index.html">⬅️ Return to Homepage</a>
  <a href="./index.html"> 🎉 Upload your Results! 🎉</a>
</div>

# Post Association Checks

## Introduction

This suite of programs is designed to automatically perform quality control (QC) of GWAS results. Most of the analyses are based on QC steps performed by **EasyX**, an R package that combines functions from **EasyStrata** and **EasyQC**.

## Assumptions

Before running the pipeline, ensure the following:

1. **GWAS output** is from **REGENIE** (uncompressed).
2. **Genomic positions** are in **build 38 (hg38)**.
3. **Apptainer** or **Singularity** can be run in your HPC environment.

## Program Overview

Below is a summary of the programs that use EasyX and their functions:

- `1_clean_gwas.R` – Prepares REGENIE GWAS output for **EasyX**.  
- `2_allele_frequency_check.R` – Compares allele frequencies across six different genetic ancestries (**AFR**, **AMR**, **MID**, **EUR**, **EAS**, and **SAS**).  
- `3_update_cfg_and_run_easyx.R` – Updates the EasyX configuration file with your input data and threshold parameters, and then runs EasyX.  
- `4_report_wrapper.Rmd` – Reads outputs from the previous programs and summarizes the findings in a report.

Additionall, with effects_vs_loadings.R, the program also checks whether associations are driven by a specific subpopulation (e.g., Finnish among Europeans).  

---

## Quick Start

### Step 1: Clone the GitHub Repository

Start by accessing your working directory in your HPC session and cloning the repository:

This pipeline is still under development, we propose you download our temporal working branch: 
```bash
git clone --branch tmp_wd --single-branch https://github.com/giant-consortium/post_assoc_checks.git
```

Or download the main branch with:

```bash
git clone https://github.com/giant-consortium/post_assoc_checks.git
cd post_assoc_checks
```
Alternatively, download it as a zip and transfer it:
```
unzip  post_assoc_checks-main.zip
cd post_assoc_checks-main
```

### STEP 2: Setting-up working directory:

To run the pipeline you will only require to:

1) Move GWAS to a folder nested in your working directory
2) Update the parameters file
3) Download the container data (singularity or apptainer images).

#### 2.1 move data to a test data folder:

Singularity seems to not be able to access the data unless it is in nested in the working directory.
To avoid issues, make a new folder "test_data" in your working directory 

```
cp path_to_your_gwas test_data/.
```

#### 2.2 UPDATE parameters file:

The parameter file contains variables that reference input and output data.
We recommend having a specific folder per GWAS QC-ed. 
Here is my example:

```
WD="/maps/projects/kilpelainen-AUDIT/data/team_projects/giant_pc_loadings_tests/post_assoc_checks-tmp_wd"
INPUT_GWAS_TOTAL_PATH="/maps/projects/kilpelainen-AUDIT/data/team_projects/giant_pc_loadings_tests/post_assoc_checks-tmp_wd/test_data/STUDYA_HEIGHT.regenie.gz"
OUTPUT_DIR="/maps/projects/kilpelainen-AUDIT/data/team_projects/giant_pc_loadings_tests/post_assoc_checks-tmp_wd/test_results/height/"
OUTPUT_NAME="height"
REF_PATH="/maps/projects/kilpelainen-AUDIT/data/team_projects/giant_pc_loadings_tests/post_assoc_checks-tmp_wd/ref_data/"
```

Importantly, the output folder should exist! The code does not generate them for you:

```
#In my working directory I created the output:
mkdir test_results/height
```

#### 2.3 Obtain container:

You can do so in several ways.

If you have singularity and sudo permissions:

```
sudo singularity pull post_assoc_qc_latest.sif docker://mariogu5/post_assoc_qc:latest
```

If you do not...

```
wget https://storage.googleapis.com/giant_deeper_imputation/singularity_containers/post_assoc_qc_latest.sif 
```

### STEP 3: run the pipeline!!

Note that the minimum requirement to run the pipeline is having apptainer or singluarity available in your HPC environment. 
My HPC works with modules so, for the bash script to work, I require to do the following:

```
module load singularity/3.8.7
```

Keep in mind what you should do to have singularity or apptainer accessible in your environment! Once that is done:

```
bash POST_ASSO_PIPELINE.sh
```

