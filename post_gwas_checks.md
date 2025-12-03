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

# Post Association Checks
This repository contains scripts for performing quality checks on association analysis data, both pre- and post-meta-analysis.

## STEP 1: Download the Repository

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

## STEP 2: Set Up Your Working Directory

To run the pipeline, you need to:

1) Move your GWAS data into a folder nested within your working directory.
2) Update the parameters file.
3) Download the required container (Singularity or Apptainer image).

### 2.1 Organize GWAS Data

Singularity may not access data outside your working directory. To avoid issues, create a folder named test_data inside your working directory and copy your GWAS file there:

```
cp path_to_your_gwas test_data/.
```

### 2.2 Update the Parameters File

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

### 2.3 Download the Container

You can obtain the container in multiple ways:

If you have Singularity and sudo permissions:

```
sudo singularity pull post_assoc_qc_latest.sif docker://mariogu5/post_assoc_qc:latest
```

If you don’t have sudo permissions:

```
wget https://storage.googleapis.com/giant_deeper_imputation/singularity_containers/post_assoc_qc_latest.sif 
```

## STEP 3: Run the Pipeline

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

# OPTIONAL: Running the Pipeline for Multiple GWAS Files 

If you need to process multiple GWAS summary statistics files, this repository includes an optional wrapper that automatically runs the Post Association Checks pipeline on each file. You can run GWAS sequentially or in parallel, without manually editing parameter files for each run.

## OPTION 1: Run GWAS Sequentially (one after the other)

What This Wrapper Does:
1. Reads a list of GWAS files from a user-provided text file (gwas_list.txt)
2. Creates a dedicated output folder for each GWAS
3. Automatically generates an updated parameters file for each GWAS
4. Runs the standard POST_ASSO_PIPELINE.sh pipeline for each file
5. Stores all results under a shared directory (all_results/)

Nothing in the main pipeline is modified; the wrapper simply automates input preparation and sequential execution.

## Files Provided for Multi-GWAS Support

Inside post_assoc_checks/, you will find:
```
multi_gwas_runner.sh        # wrapper to run all GWAS sequentially
params_template.txt         # template used to auto-generate parameter files
gwas_list.txt               # list your GWAS files here
run_multi_gwas.slurm        # SLURM script (sequential execution)
all_results/                # auto-created output folder
```

### STEP 1: Add Your GWAS Files to gwas_list.txt

Edit post_assoc_checks/gwas_list.txt and list the absolute paths to all GWAS files you want to process. Example:
```
/path/to/HEIGHT.regenie.gz
/path/to/BMI.regenie.gz
/path/to/WHR.regenie.gz
```
Each line corresponds to one GWAS.

### STEP 2: (Optional) Review the Parameter Template

The file params_template.txt contains placeholder values that the wrapper will replace automatically:
```
gwas_results="__GWAS__"
output_dir="__OUTDIR__"
kg_hgdp_ref_dir=""
easyx_ref_dir=""
```
You do not need to modify this unless you want to add optional reference data paths.

### STEP 3: Run the Multi-GWAS Wrapper (Sequential)

Submit the sequential wrapper (for HPC clusters using SLURM):
```
sbatch run_multi_gwas.slurm
```
This runs one GWAS after another. All outputs and parameters are organized in all_results/.

### Output Structure

Outputs are automatically organised under:
```
all_results/
    HEIGHT/
        HEIGHT_parameters.txt
        <pipeline output>
    BMI/
        BMI_parameters.txt
        <pipeline output>
    WHRadjBMI/
        WHRadjBMI_paramers.txt
        <pipeline output>
```

Each GWAS has its own parameters file, own output directory, and independent log files.

### OPTION 2: Run GWAS in Parallel (SLURM Job Array)

This option runs each GWAS as an independent SLURM job. This is recommended for clusters with multiple nodes or cores and allows much faster processing when you have many GWAS.

How This Works:

1. SLURM job arrays submit multiple jobs at once. Each job gets a unique array ID corresponding to a GWAS in your list.
2. Each job creates its own output folder in all_results/<GWAS_NAME>/.
3. Logs (stdout + stderr) are saved per GWAS in the same folder.
4. A parameters file is automatically generated for each GWAS.

### STEP 1: Check Number of GWAS

Count how many GWAS you want to run:
```
wc -l gwas_list.txt
```

### STEP 2: Adjust the SLURM Array Size

Open run_multi_gwas_array.slurm and set the array size to match your number of GWAS. For example, if you have 5 GWAS:
```
#SBATCH --array=1-5
```
Tip: If you have fewer than 100 GWAS, you do not need to modify the --array=1-100 line; it will work, but unused indices will be skipped.

### STEP 3: Adjust SLURM Resource Parameters (if necessary)

Depending on the GWAS size and your HPC cluster:
```
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=12:00:00
```
- Increase --mem if your GWAS is large
- Increase --time if processing takes longer

### STEP 4: Submit the Job Array
```
sbatch run_multi_gwas_array.slurm
```

### Output Structure for Parallel Runs
```
all_results/
    HEIGHT/
        HEIGHT_parameters.txt
        HEIGHT.log
        <pipeline output>
    BMI/
        BMI_parameters.txt
        BMI.log
        <pipeline output>
    WHR/
        WHR_parameters.txt
        WHR.log
        <pipeline output>
```
- Logs for each GWAS are saved as <GWAS_NAME>.log in its output folder.
- The parameters used for each GWAS are saved as <GWAS_NAME>_parameters.txt.
- The pipeline output is fully contained within the GWAS-specific folder.
