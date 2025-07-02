---
---
<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./../index.html">⬅️ Return to Homepage</a>
  <a href="./../ind_geno_qc.html">Go to Step 1 [Individual and Genotype QC] ➡️</a>
</div>

# Container Platforms Supported

This workflow supports three types of containers: **Docker**, **Singularity**, and **Apptainer** (the commercial version of Singularity).

Before proceeding, check which tools are available on the system where your genotype and phenotype data are stored.  
**Tip:** If using a high-performance compute platform or remote resource, run the tool checks on that system.

## Check Available Tools

```bash
# Test Docker installation
docker --version

# Test Singularity installation
singularity --version

# Test Apptainer installation
apptainer --version
```

If you have **at least one** of these tools, you can download the corresponding container to run the association testing pipeline:

- [Docker Images](https://console.cloud.google.com/storage/browser/giant_deeper_imputation/docker_containers)
- [Singularity Containers](https://console.cloud.google.com/storage/browser/giant_deeper_imputation/singularity_containers)
- [Apptainer Containers](https://console.cloud.google.com/storage/browser/giant_deeper_imputation/singularity_containers)

> **Note:** If you have `gsutil` or Google Cloud Console installed, you can use `gsutil -m cp` for fast, parallelized file transfers.

---

## If You Do Not Have Any Container Tools

Use the table below to identify the recommended tool for your system, then use the links to download and install the required software.

| OPERATING SYSTEM | ROOT ACCESS |   RECOMMENDED TOOL   |
|------------------|-------------|----------------------|
|      MAC OS      |     YES     |        DOCKER        |
|      MAC OS      |      NO     |  N/A. SWITCH SYSTEM  |
|     LINUX OS     |  YES / NO   |      SINGULARITY     |

- [Docker Installation Guide](https://docs.docker.com/get-started/get-docker/)
- [Singularity Installation Guide](./singularity_install.md)

---

You are now ready to run the pipeline! Continue with the next steps in the documentation.
