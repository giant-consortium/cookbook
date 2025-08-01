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

1. **GWAS output** is from **REGENIE** (compressed or uncompressed).
2. **Genomic positions** are in **build 38 (hg38)**.
3. **Singularity** can be run in your HPC environment.

## Program Overview

Below is a summary of the programs and their functions:

- `1_clean_gwas.R` – Prepares REGENIE GWAS output for **EasyX**.  
- `2_allele_frequency_check.R` – Compares allele frequencies across six different genetic ancestries (**AFR**, **AMR**, **MID**, **EUR**, **EAS**, and **SAS**).  
- `3_update_cfg_and_run_easyx.R` – Updates the EasyX configuration file with your input data and threshold parameters, and then runs EasyX.  
- `4_assoc_p_vs_af_diffs.R` – Investigates whether associations are driven by a specific subpopulation (e.g., Finnish among Europeans).  
- `5_report_wrapper.Rmd` – Reads outputs from the previous programs and summarizes the findings in a report.

---

## Quick Start

### Step 1: Clone the GitHub Repository

Start by accessing your working directory in your HPC session and cloning the repository:

```bash
# Set your working directory
wd=your_wd
cd $wd

# Clone the development branch (currently in use)
git clone --branch tmp_wd --single-branch https://github.com/giant-consortium/post_assoc_checks.git

# If you want to install the full repository use
git clone https://github.com/giant-consortium/post_assoc_checks.git
```
After cloning, you will see the following structure:

- `POST_ASSOC_PIPELINE.sh` - Main script to run the pipeline. Once parameters are configured and the Singularity image is downloaded, you're good to go!
- `post_assoc_checks-main` - Working directory where analyses are performed and results are saved.
- `Dockerfile` - Used to build the Docker and Singularity images.
- `parameters` - Configuration file where you define paths and input files.

### Step 2: Download the Singularity Image

If your HPC environment supports gsutil, you can download the Singularity image from the Google Cloud bucket:

```bash
# Enter the repository
cd your_wd/post_assoc_checks

# Log in to Google Cloud
gsutil auth login

# Download the Singularity image
gsutil cp https://console.cloud.google.com/storage/browser/_details/giant_deeper_imputation/singularity_containers/post_assoc_qc_latest.sif?pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&inv=1&invt=Ab1weA post_assoc_qc_latest.sif
```
> **🔁Note:** If your HPC does not support `gsutil`, you can manually download the file from the  
> [**GIANT Singularity Containers page**](https://console.cloud.google.com/storage/browser/giant_deeper_imputation/singularity_containers).  
> Look for the file: **`post_assoc_qc_latest.sif`**, and save it.

```bash
# Enter the repository
cd your_wd/post_assoc_checks

# Download the file (replace <URL> with the actual download link)
wget <URL>
```

### Step 3: Download TopMed Imputed Allele Frequencies (Build 38)

One of the reference datasets used for allele frequency QC is hosted in a tarball on the Google Cloud bucket. This data must be placed in the ref_data folder with the proper structure.

```bash
# Go to the ref_data directory
cd your_wd/post_assoc_checks/post_assoc_checks-main/ref_data/

# Download the reference data tarball
gsutil cp https://console.cloud.google.com/storage/browser/_details/giant_deeper_imputation/parsed_topmed_imputed_allele_freq_4_easyx.tar.gz?pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&inv=1&invt=Ab1weA parsed_topmed_imputed_allele_freq_4_easyx.tar.gz

# Extract it directly into the current folder (no subfolder)
tar -xvf parsed_topmed_imputed_allele_freq_4_easyx.tar.gz --strip-components=1
```

> **🔁Note:** If your HPC does not support `gsutil`, you can manually download the file from the  
> [**GIANT Deeper Imputation page**](https://console.cloud.google.com/storage/browser/giant_deeper_imputation/).  
> Look for the file: **`parsed_topmed_imputed_allele_freq_4_easyx.tar.gz`**, and save it.

```bash
# Go to the ref_data directory
cd your_wd/post_assoc_checks/post_assoc_checks-main/ref_data/

# Download the file (replace <URL> with the actual download link)
wget <URL>

# Extract it directly into the current folder (no subfolder)
tar -xvf parsed_topmed_imputed_allele_freq_4_easyx.tar.gz
```
❗ I think we do not want to include --strip-components=1

### Step 4: Run the Pipeline
Once all required data has been downloaded and stored in the appropriate folders, you're ready to run the post-association checks pipeline.

Before running the pipeline, you must edit the parameters file located in:

```bash
your_wd/post_assoc_checks/
```

Only three fields are required:
1. Full path to the REGENIE GWAS output
2. Full path to the desired output directory
3. A short name for the output files

Example parameter file:

```bash
INPUT_GWAS_TOTAL_PATH=""
OUTPUT_DIR=""
OUTPUT_NAME=""
```

### Step 5: Set the Working Directory
The working directory must currently be set manually inside the POST_ASSO_PIPELINE.sh script. (In a future version, this will likely become a command-line parameter.)

Open the script and modify the first line:
```bash
your_wd=""
```
⚠️ Important: This should point to the working directory inside the container.

### Step 6: Run the Pipeline
Make sure Singularity is available in your HPC environment:

```bash
module load singularity/3.8.7
```

Then navigate to your working directory and run the pipeline:

```bash
# Move to your working directory
cd /your_wd/post_assoc_checks/

# Run the pipeline
bash POST_ASSO_PIPELINE.sh
```
