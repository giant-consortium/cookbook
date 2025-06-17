# Post association checks

## INTRODUCTION

This suite of programs is designed to automatically perform QC of GWAS. Most of the the analyses are based on QC performed by EasyX, an R package that combines functions from EasyStrata and EasyQC.

The suite consists of 5 programs:

- **1_clean_gwas.R** – Prepares REGENIE GWAS output for **EASYX**.  
- **2_allele_frequency_check.R** – Compares allele frequencies across six different genetic ancestries (**AFR**, **AMR**, **MID**, **EUR**, **EAS**, and **SAS**).  
- **3_update_cfg_and_run_easyx.R** – **EasyX** is called via a configuration file with information on the GWAS input and parameter thresholds. The program automatically updates the configuration file with your input data and runs **EasyX**.  
- **4_assoc_p_vs_af_diffs.R** – Compares whether associations are driven by a specific subpopulation among the individuals from a certain genetic ancestry (i.e., Finnish among European).  
- **5_report_wrapper.Rmd** – A script that reads the output of the previous programs and summarizes the findings.

### Clone GitHub repo    

```bash
 git clone https://github.com/giant-consortium/post_assoc_checks.git
```

### STEP 1: get the pipeline ready to run:

Once you have downloaded the repository you should have the following items:

- **POST_ASSOC_PIPELINE.sh** - the commands to run the suite of programs. Once parameters are changed and you have a Singularity image downloaded, you are good to go!
- **post_assoc_checks-main** - working directory where analyses are performed and results are saved
- **Dockerfile** - a copy of the filte utilized to build the Docker and Singularity images.
- **parameters** - the file where you assign the path and files utilized as input.

**What else is needed?**

You need a singularity image with the programs and libraries required by our suite of programs. 

Download the singularity image post_assoc_qc.sif and download it in the repository folder.

```bash
 wd=my_path/post_assoc_checks/
 cd $wd
 gcloud ---
```

### STEP 2: run the pipeline!

```bash
 bash POST_ASS_PIPELINE.sh
```

### post_assoc_checks-main structure
