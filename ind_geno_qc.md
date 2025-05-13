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


#### Building the Singularity Container

    ```bash
    # 1. Give permission to run the docker build scripts
    chmod 777 RUNNER.sh

    # 2. Run the Docker image build script
    ./RUNNER.sh

    # 3. Upload the Docker image to DockerHub
    #       OR (as shown here), tar the local image
    docker save sample_variant_qc:latest -o sample_variant_qc.tar
    # This is a 14 GB file
    # So, gzip it
    # This gives you a 4.8 GB file
    # I was transferring it from my local system to the Server with
    # singularity installed, so this was simpler

    gzip sample_variant_qc.tar
    scp sample_variant_qc.tar.gz seth@login.broadinstitute.org:/cvar/jhlab/seth/DeeperImputation/build_container

    # SSH into server
    cd /cvar/jhlab/seth/DeeperImputation/build_container
    gunzip sample_variant_qc.tar.gz

    # Build Apptainer Image File
    apptainer build sample_variant_qc.sif docker-archive:sample_variant_qc.tar 

    # Build the sandbox
    apptainer build --sandbox sample_variant_qc.sif docker-archive:sample_variant_qc.tar 

    # If you have cache restrictions use:
    export APPTAINER_CACHEDIR=/cvar/jhlab/seth/DeeperImputation/build_container/tmp
    apptainer build --fakeroot sample_variant_qc.sif docker-archive:sample_variant_qc.tar
    apptainer build --fakeroot --sandbox sample_variant_qc_sandbox docker-archive:sample_variant_qc.tar

    $ apptainer --version
    $ docker --version
    $ singularity --version

    apptainer run docker://sylabsio/lolcow:latest
    apptainer pull docker://sylabsio/lolcow

    apptainer build lolcow_tar.sif docker-archive:lolcow.tar
    Apptainer’s container image format (SIF) is generally read-only

    build can produce containers in two different formats, which can be specified as follows:

a compressed read-only Singularity Image File (SIF) format, suitable for production (default)
a writable (ch)root directory called a sandbox, for interactive development ( --sandbox option)

Because build can accept an existing container as a target and create a container in either supported format, you can use it to convert existing containers from one format to another

apptainer build --sandbox alpine/ docker://alpine

To make persistent changes within the sandbox container, use the --writable flag when you invoke your container.

$ apptainer shell --writable alpine/

If you already have a container saved locally, you can use it as a target to build a new container. This allows you convert containers from one format to another. For example, if you had a sandbox container called development/ and you wanted to convert it to a SIF container called production.sif, you could do so as follows:

$ apptainer build production.sif development/

    # 4. 
    ```

#### NOTE For the Uploaded Version

    ```bash
    # For the version that has been tar'ed and uploaded, 
    # I used the following run command: 
    ./RUNNER.sh --force_build True --force_data_download True \
        > run_entire_docker_on_sample_STUDY4.log

    # The above command forces a re-build and re-download. 
    # This was useful since there were previous versions of the
    # Docker image on my local machine, and I was able to get a sense
    # of the time taken for each step, and keep a record of what the
    # sample output looks like. The sample output is stored at
    # run_entire_docker_on_sample_STUDY4.log

    # In general though, the pipeline can be run using ./RUNNER.sh
    # To save logs, use: ./RUNNER.sh > log_file_path.log
    ```





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
