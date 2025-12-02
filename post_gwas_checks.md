---
---
<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./index.html">⬅️ Return to Homepage</a>
  <a href="./index.html"> 🎉 Upload your Results! 🎉</a>
</div>

# Post Association Checks

## Introduction

This repository contains scripts for performing quality checks on association analysis data, both pre- and post-meta-analysis.

## Assumptions

Before running the pipeline, ensure the following:

1. **GWAS output** is from **REGENIE**.
2. **Genomic positions** are in **build 38 (hg38)**.
3. **Apptainer** or **Singularity** can be run in your HPC environment.

---

## Quick Start

### STEP 1: Download the Repository

Navigate to your working directory and download the repository:

```
git clone https://github.com/giant-consortium/post_assoc_checks.git
cd post_assoc_checks
```

Alternatively, you can download the repository as a ZIP file and extract it:

```
unzip  post_assoc_checks-main.zip
cd post_assoc_checks-main
```

### STEP 2: Set Up Your Working Directory

To run the pipeline, you need to:

1) Move your GWAS data into a folder nested within your working directory.
2) Update the parameters file.
3) Download the required container (Singularity or Apptainer image).

#### 2.1 Organize GWAS Data

Singularity may not access data outside your working directory. To avoid issues, create a folder named test_data inside your working directory and copy your GWAS file there:

```
cp path_to_your_gwas test_data/.
```

#### 2.2 Update the Parameters File

The parameters file specifies paths for input and output data. We recommend maintaining a separate folder for each GWAS QC run. Here’s an example:

```
# Absolute directory path to GWAS input:
gwas_results="/maps/projects/kilpelainen-AUDIT/people/zlc436/giant_test_17112025/STUDYA_HEIGHT.regenie.gz"

#Output directory and name:
output_dir="/maps/projects/kilpelainen-AUDIT/people/zlc436/giant_test_17112025/post_assoc_checks/test_results/height/"

# Absolute path to parent directory containing 1000G+HGDP genotypes (hgdp_1kg_hg38_ref_data/) and subject lists (hgdp_1kg_population_labels/)
# These directories and  will exist if you have run the individual and genotype QC pipeline
# If unsure or have not run the indiviudual and genotype QC pipeline, leave blank
kg_hgdp_ref_dir=""

# Absolute ath of reference data for EasyX. If you have not run this pipeline before, leave blank
easyx_ref_dir=""
```

#### 2.3 Download the Container

You can obtain the container in multiple ways:

If you have Singularity and sudo permissions:

```
sudo singularity pull post_assoc_qc_latest.sif docker://mariogu5/post_assoc_qc:latest
```

If you don’t have sudo permissions:

```
wget https://storage.googleapis.com/giant_deeper_imputation/singularity_containers/post_assoc_qc_latest.sif 
```

### STEP 3: Run the Pipeline

The pipeline requires Apptainer or Singularity in your HPC environment.

Example (using modules):

```
module load apptainer/1.4.0-rc
bash POST_ASSO_PIPELINE.sh --apptainer
```

If running via a job scheduler, it is recommended to first navigate to the working directory. Example SLURM/SGE script (queue_post_assoc) calling the pipeline:

```
#! /bin/bash
#SBATCH -J 'pipeline_test_17102025'
#SBATCH --cpus-per-task=8
#SBATCH --output=pipeline_%j.log
#SBATCH --error=pipeline_%j.err

module load apptainer/1.4.0-rc

cd /projects/kilpelainen-AUDIT/people/zlc436/giant_test_14112025/post_assoc_checks

bash POST_ASSO_PIPELINE.sh --apptainer
```
