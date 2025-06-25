# Sample Variant QC Pipeline (Container-Based Install)

## Overview

This repository provides a containerized pipeline for sample variant quality control (QC), ancestry prediction, and per-chromosome QC reporting. The pipeline is distributed as a Docker image, which can also be converted to a Singularity or Apptainer container for use on HPC systems.

## Quick Start

1. **Ensure all required containers are available**  
   Confirm that the necessary container images (Docker, Singularity, or Apptainer) are downloaded and accessible on your system.

2. **Edit `parameters.txt`** to set paths and options for your data.

3. **Run the pipeline:**

   ```bash
   # With Docker
   ./RUNNER.sh --docker

   # With Singularity
   ./RUNNER.sh --singularity

   # With Apptainer
   ./RUNNER.sh --apptainer

   # To force data download:
   ./RUNNER.sh --docker --force_data_download
   ```

4. **Outputs** will be saved in the directory specified by `path_to_output` in `parameters.txt`.

## Troubleshooting

- Check the log files in the `output/study_name/Logs` directory for errors.
- Ensure all required paths in `parameters.txt` are correct and accessible.
- Check stepwise outputs in the `output/study_name/` directory for errors.
- For container issues, verify your container runtime is installed and running.
