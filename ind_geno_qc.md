# Individual and Genotyping QC

[Go to Individual Genotype QC Steps](ind_geno_qc_steps.md)

## Pipeline Execution

Select the execution case description that best describes the setup for the machine on which the genotype and phenotype data is located:

| CASE | ROOT ACCESS | DOCKER | SINGULARITY |
|------|-------------|--------|-------------|
| A    | YES/NO      | YES    | YES/NO      |
| B    | NO          | NO     | YES         |
| C    | NO          | NO     | NO          |

### Case A: System with Docker

#### **Prerequisites**

- Docker [Installation Link](https://docs.docker.com/get-started/get-docker/)
- git (Preferrably in Command-Line)[Installation Link](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

Check installation using:

```bash
# Test Docker installation
docker --version

# Test Git installation
git --version
```

#### **Execution Steps**

1. Download the codebase from GitHub

    a. Open terminal (in Mac or Linux)
    b. cd to directory in which you want to run the install

    ```bash
    git clone https://github.com/giant-consortium/sample_variant_qc.git
    cd sample_variant_qc
    ```

2. Update the configuration files in the `config` folder:

    a. Open the `mounts.txt` file and update the `path_to_data` variable to point to the dataset location on your local machine.

    b. Open the `mounts.txt` file and update the `path_to_output` variable to point to the desired output location on your local machine.

    c. Open the `parameters.txt` file and update the `study_name` variable to specify the study name (this is the prefix for the genotype files).

    c. Review other parameters in the configuration files and modify them if necessary. Default settings can be used unless specific changes are required for your analysis.

3. Run the installations and build the Docker
    <!--lint disable-->

    <!--lint enable-->
    If this is the first execution of this pipeline, give execution permissions to the running script

    ```bash
    chmod 777 run_docker.sh
    ```

    We're now ready to run the pipeline.

    ```bash
    ./RUNNER.sh
    ```

    If the user has another study dataset, simply change the configurations as described in Step 2, and re-run the pipeline using:

    ```bash
    ./RUNNER.sh
    ```

    If the user wants to re-build the docker image:

    ```bash
    ./RUNNER.sh --force_build True
    ```

    If the user wants to re-download the datasets:

    ```bash
    ./RUNNER.sh --force_data_download True
    ```

### Case B: System with Singularity

#### **Prerequisites**

#### **Execution Steps**




### Case C: System with Singularity

#### **Prerequisites**

#### **Execution Steps**

#### **NOTES About the Pipeline**

``` markdown
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
```
