---
---
<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./../index.html">⬅️ Return to Homepage</a>
  <a href="./../ind_geno_qc.html">Go to Step 1 [Individual and Genotype QC] ➡️</a>
</div>

# Container Platforms Supported

This workflow supports three types of containers: **Docker**, **Singularity**, and **Apptainer** (the commercial version of Singularity).

Before proceeding, check which tools are available on the system where your genotype and phenotype data are stored.  
**Important:** For high-performance computing clusters or remote systems, execute these checks on the target compute environment. Some systems require requesting an interactive session before running commands.

## Check Available Tools

```bash
# Test Docker installation
docker --version

# Test Singularity installation
singularity --version

# Test Apptainer installation
apptainer --version
```

If you have **at least one** of these tools, you can use the GIANT Deeper Imputation analysis pipeline!

If you don't have one yet, let's get you set up! → [Jump to Installation Guide](#if-you-do-not-have-any-container-tools)

---

## SSH Key Setup for GitHub Access

The pipeline pipeline clones repositories and downloads resources from GitHub. On HPCs and remote systems, SSH keys are the preferred authentication method:

```bash
# Generate SSH key (if you don't have one)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add to SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Display public key (copy this to GitHub Settings → SSH and GPG keys)
cat ~/.ssh/id_ed25519.pub
```

**Next steps:**

1. Copy the public key output from the command above
2. Go to [GitHub Settings → SSH and GPG keys](https://github.com/settings/keys)
3. Click "New SSH key" and paste your public key

[Detailed GitHub SSH Setup Guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)

---

## Container Download Options

The GIANT pipeline offers flexible container management:

### Option 1: Download-as-you-go (Recommended)

The pipeline downloads containers automatically when needed for each step. **No upfront setup required** - containers are fetched on-demand as you progress through the workflow.

> **Note:** Most users can use the download-as-you-go approach for a smoother experience.

### Option 2: Pre-download All Containers

If you prefer to download everything upfront:

- [Docker Images](https://console.cloud.google.com/storage/browser/giant_deeper_imputation/docker_containers)
- [Singularity/Apptainer Containers](https://console.cloud.google.com/storage/browser/giant_deeper_imputation/singularity_containers)

> **Note:** If you have `gsutil` or Google Cloud Console installed, you can use `gsutil -m cp` for fast, parallelized file transfers.

---

## If You Do Not Have Any Container Tools

Use the table below to identify the recommended tool for your system, then use the links to download and install the required software.

| OPERATING SYSTEM | ROOT ACCESS |   RECOMMENDED TOOL   |
|------------------|-------------|----------------------|
|      macOS       |     YES     |        DOCKER        |
|      macOS       |      NO     |  N/A. SWITCH SYSTEM  |
|     LINUX OS     |  YES / NO   |      SINGULARITY     |

- [Docker Installation Guide](https://docs.docker.com/get-started/get-docker/)
- [Singularity Installation Guide](./singularity_install.md)

> Note: Apptainer is the enterprise-software equivalent of Singularity, and is usually installed at an organization-level. This is typically available within HPCs.

---

🎉 **Setup Complete!**

You're now ready to run the pipeline. **Next step:** [Individual and Genotype QC Pipeline](../ind_geno_qc.html)
