---
title: "Phenotype Pipeline"
---

## Overview

This repository provides a containerized pipeline for QC and deriviation of phenotype data for subsequent GWAS analysis.

## Quick Start

1. **Ensure all required containers are available**  
   Confirm that the necessary container images (Docker, Singularity, or Apptainer) are downloaded and accessible on your system.

2. **Edit `parameters.txt`** to set filenames and options for your data. This includes mapping column names to data labels that can be interpreted by the pipeline.


3. ** Run the bash script that will run the docker
```
bash PHENOTYPE_PIPELINE.sh
```

The output from this workflow will include:
 * a file for REGENIE containing values of ancestry-specific male and female inverse-normalised residuals. 
 * a file for REGENIE containing continuous and categorical covariates specific to genotyping that were not incoporated into the residuals (if applicable)
 * tab delimited summaries of the phenotypes processed for GWAS
 * visualisation of raw, QCd', residualsised, and inverse-normalised values
 * sample lists for REGENIE that correspond to ancestry- and sex-stratified GWAS analysis

 

