---
---
<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./../index.html">⬅️ Return to Homepage</a>
  <a href="./../ind_geno_qc.html">Go to Step 1 [Individual and Genotype QC] ➡️</a>
</div>

# Singularity/Apptainer User Environment Setup

## Summary Workflow

-------------------------------------------------------------------------------

1. Download all scripts:

    ```bash
    wget https://storage.googleapis.com/giant_deeper_imputation/source_code/singularity_install/sing1_install_miniconda.sh
    wget https://storage.googleapis.com/giant_deeper_imputation/source_code/singularity_install/sing2_install_singularity.sh
    wget https://storage.googleapis.com/giant_deeper_imputation/source_code/singularity_install/convert_docker_to_singularity.sh
    ```

2. Change file permissions on your system:

    ```bash
    chmod +x *.sh
    ```

3. Install Miniconda:

    ```bash
    bash sing1_install_miniconda.sh --install-dir /your/conda/install/path [--bashrc /your/custom/bashrc]
    ```

4. Source bashrc:

    ```bash
    source ~/.bashrc   # or your custom bashrc
    ```

5. Install Singularity/Apptainer:

    ```bash
    bash sing2_install_singularity.sh --install-dir /your/conda/install/path [--env-name myenv] [--no-root]
    ```

6. Activate environment:

    ```bash
    conda activate <env_name>
    ```

-------------------------------------------------------------------------------

This guide explains how to set up a user-level Singularity/Apptainer environment using Miniconda, and how to convert Docker images (from a tar file or Docker Hub) to a Singularity Image Format (.sif) file.

-------------------------------------------------------------------------------

> **Note:** You must have either `wget` or `curl` installed to download the scripts.
>
> - On Ubuntu/Debian: `sudo apt-get install wget` or `sudo apt-get install curl`
> - On CentOS/RHEL: `sudo yum install wget` or `sudo yum install curl`

### Step 1: Install Miniconda

Run the Miniconda installer script:

```bash
bash sing1_install_miniconda.sh --install-dir /your/conda/install/path [--bashrc /your/custom/bashrc]
```

**Options:**

- `--install-dir`   Directory where Miniconda will be installed (default: `$HOME`)
- `--bashrc`        Path to a custom bashrc file to update with Miniconda's PATH
- `--no-root`       Use user-writable directories for all conda/temp/cache files

**Example:**

```bash
bash sing1_install_miniconda.sh --install-dir $HOME/miniconda_custom --bashrc $HOME/.bashrc_custom --no-root
```

-------------------------------------------------------------------------------

### Step 2: Source Your Bashrc

After installation, update your shell environment:

```bash
source ~/.bashrc
```

or, if you used a custom bashrc:

```bash
source /your/custom/bashrc
```

-------------------------------------------------------------------------------

### Step 3: Install Singularity/Apptainer in a Conda Environment

Run the second script to create a conda environment and install Singularity/Apptainer:

```bash
bash sing2_install_singularity.sh --install-dir /your/conda/install/path [--env-name myenv] [--no-root]
```

**Options:**

- `--install-dir`   Should match the directory used in Step 1
- `--env-name`      Name for the conda environment (default: `singularity_env`)
- `--no-root`       Use user-writable directories for all conda/temp/cache files

**Example:**

```bash
bash sing2_install_singularity.sh --install-dir $HOME/miniconda_custom --env-name sing_env --no-root
```

-------------------------------------------------------------------------------

### Step 4: Activate the Conda Environment

```bash
conda activate /your/environment/name
```

**Example:**

```bash
conda activate sing_env
```

-------------------------------------------------------------------------------

### Developer Add-on: Docker Image to SIF Conversion

_The following is optional and intended for developers or advanced users who need to convert Docker images to Singularity SIF format._

### Step 5: Convert Docker Images to SIF

Use the provided script to convert a Docker image (from a local tar or Docker Hub) to a `.sif` file:

```bash
bash convert_docker_to_sif.sh --docker-tar /path/to/image.tar --output my_image.sif
```

or

```bash
bash convert_docker_to_sif.sh --docker-hub repo/image:tag --output my_image.sif
```

**Options:**

- `--docker-tar`    Path to a Docker image tar file (created with `docker save`)
- `--docker-hub`    Docker Hub image reference (e.g., `ubuntu:22.04`)
- `--output`        Output SIF file name (default: `container.sif`)

**Examples:**

```bash
bash convert_docker_to_sif.sh --docker-tar ./my_image.tar --output my_image.sif
bash convert_docker_to_sif.sh --docker-hub ubuntu:22.04 --output ubuntu22.sif
```

-------------------------------------------------------------------------------
