---
---
<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./index.html">⬅️ Return to Homepage</a>
  <a href="gwas.html">Go to Step 5 [GWAS]➡️</a>
</div>

# Pre-phasing/imputation Pipeline 

## Overview

This repository provides a containerized pipeline for data preparation for phasing and imputation on either the TOPmed imputation server or UK Biobank RAP. The pipeline is distributed as a .sif file that can be run using apptainer/singularity.
Presently (July 2025) only checks against TOPmed are implemented.

We are asking studies of predominately European and South Asian genetic ancestry to impute to the latest UK Biobank haplotype reference panel. Studies of other genetic ancestries should impute to TOPMed.

## Usage

1. **Clone the pre-phasing/imputation report from GitHub**

   ```
   git clone git@github.com:giant-consortium/pre_phasing.git
   ```

2. **Edit `parameters.txt` to set paths and options for your data**. There are three parameters that need to be set in the `parameters.txt` file.
 
   ```
   # Imputation reference panel - TOPMED or UKB
   REF_PANEL=["TOPMED"|"UKB"]

   # Directory containing plink data and prefix
   PLINK_PREFIX="/path/to/plink_files"

   # Output directory for VFCs for phasing/imputatioon
   OUT_DIR="/path/to/output/directory"
   ```

3. **Run the pipeline:**

   ```
   bash PREPHASING_PIPELINE.sh
   ```

4. **Outputs** will be saved in the directory specified by `OUT_DIR` in `parameters.txt` with the final VCFs for phasing and imputation saved in the subdirectory `vcfs_for_phasing_imputation`.


