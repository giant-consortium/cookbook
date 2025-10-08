---
---
<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./index.html">⬅️ Return to Homepage</a>
  <a href="./pre_phasing_checks.html">Go to Step 2 [Pre-Phasing Checks]➡️</a>
</div>

# Sample Variant QC Pipeline

## Overview

This repository provides a containerized pipeline for sample variant quality control (QC), ancestry prediction, and per-chromosome QC reporting. The containers are downloaded as a part of the pipeline. The end user modifies execution parameters in parameters.txt, and specifies the application used to run the container as an argument while running the bash script (SAMPLE_VARIANT_QC_RUNNER.sh)

## Requirements

- Docker, Singularity or Apptainer
- Bash shell

## Quick Start

1. **Clone the GitHub repository:**

   ```
   git clone git@github.com:giant-consortium/sample_variant_qc.git
   cd sample_variant_qc
   chmod +x SAMPLE_VARIANT_QC_RUNNER.sh
   ```

2. **Edit `parameters.txt`** to set paths and options for your data. The path_to_data and study_name are altered in every execution. Always set study_name to match the base name of your PLINK files (no file extensions).

   ```bash
   E.g. If your files are named STUDY4_SAS.bed, STUDY4_SAS.bim, STUDY4_SAS.fam
   study_name=STUDY4_SAS
   ```

   NOTE: If these are stored in a compressed form (.tar.gz) or in alternate formats (.ped/.map, .bgen) the conversion to PLINK is done automatically. Do not include the file extension in the study_name parameter.

3. **Run the pipeline:**

   ```bash
   # With Docker
   ./SAMPLE_VARIANT_QC_RUNNER.sh --docker

   # With Singularity
   ./SAMPLE_VARIANT_QC_RUNNER.sh --singularity

   # With Apptainer
   ./SAMPLE_VARIANT_QC_RUNNER.sh --apptainer

   # To force data download:
   ./SAMPLE_VARIANT_QC_RUNNER.sh --docker --force_data_download
   ```

4. **Outputs** will be saved in a sub-folder named `study_name` at the path specified by `path_to_output` in `parameters.txt`. This sub-folder contains the following:

- PreQCStats: Pre-QC Statistics and report
- PreQCStats_PerChromosome
- PostQCStats_PerChromosome
- Kinship: Includes analysis results and report
- PCA: Includes analysis results and report
- Ancestry : Includes ancestry assignment results and report
- AncestrySpecificPCA: Ancestry-stratified PCA analysis
- Logs
- Reports: PDF reports from all substeps, includes a collated version

## Troubleshooting

- Check the log files in the `./output/study_name/Logs` directory for errors.
- Ensure all required paths in `parameters.txt` are correct and accessible.
- Stepwise outputs are in the `./output/study_name/` directory.
- For container issues, verify your container runtime is installed and running.
