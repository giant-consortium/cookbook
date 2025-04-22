# Individual and Genotyping QC

Based on the level of permissions that the user has, different versions of this pipeline can be run.

### Case 1: Root Access on a Personal Machine

#### **Prerequisites**

- Docker
- Study Files
- git (Preferrably in Command-Line)

#### **Execution Steps**

1. Download the codebase from GitHub

    a. Open terminal (in Mac or Linux)
    b. cd to directory in which you want to run the install

    ```bash
    git clone <https://github.com/giant-consortium/sample_variant_qc.git>
    cd sample_variant_qc
    ```

2. Update the configuration files:

    a. Open the `mounts.txt` file and update the `path_to_data` variable to point to the dataset location on your local machine.

    b. Open the `parameters.txt` file and update the `study_name` variable to specify the study name (this is the prefix for the genotype files).

    c. Review other parameters in the configuration files and modify them if necessary. Default settings can be used unless specific changes are required for your analysis.

    _NOTE on Default Settings:_
    - Variants with minor allele frequency < 1%, Hardy-Weinberg p-value < 1e-50, or >1% missingness are dropped.
    - Samples with >1% missingness or a kinship score > 0.1 are excluded.
    - 15 principal components (PCs) are used for ancestry determination. Individuals are assigned an ancestry label if their confidence exceeds 80%.

    <!--lint disable-->

    <!--lint enable-->

    _NOTE on Reference Data and Build Check Data Downloads:_
    - Time Taken: 5-10 minutes (depends on network speed)
    - Size: ~2.5 GB
    - Reference Data:
        - Datasets: 1KG and HGDP
        - Build: hg38
        - Default Download Path: sub-folder in the current directory called 1_kg_and_hgdp_hg38_ref_data
    - Build Checks:
        - Checks run for hg36, hg37 and hg38
        - If the build found is hg37, **liftover is performed to hg38**
        - Default Download Path: sub-folder in the current directory called BuildCheck

    <!--lint disable-->

    <!--lint enable-->

    _NOTE on Training Algorithms_
    - The pipeline supports three ancestry-label-prediction algorithms:
        1. Multi-Ancestry Nearest Control Selection (MANCS)
        2. Random Forest (RF) with hyperparameter tuning
        3. RF without hyperparameter tuning
    - Use the `training_algorithm` and `rf_hyperparameter_tuning_flag` variables to select the desired algorithm.
    - If hyperparameter tuning is enabled, the user can update the `rf_hyperparameter_grid` to define the search space.

    <!--lint disable-->

    <!--lint enable-->

3. Run the installations and build the Docker
    <!--lint disable-->

    <!--lint enable-->
    If this is the first execution of this pipeline, give execution permissions to the running script

    ```bash
    chmod 777 run_docker.sh
    ```

    We're now ready to run the pipeline.

    ```bash
    ./run_docker.sh
    ```

    If the user wants to re-install the software or re-build the docker image:

    ```bash
    ./run_docker.sh True
    ```
