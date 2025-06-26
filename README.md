
# <img src="giant_logo.png" alt="GIANT Consortium Logo" width="80" style="vertical-align:middle; margin-right:10px;"> GIANT Deeper Imputation

<p align="center">

## Analysis Cookbook

</p>

This site has been set up as a guide on how to use the containers provided to perform

- Individual and Genotype QC, including ancestry inference
- Phenotype adjustment and transformation
- Pre-phasing checks
- GWAS
- Post-GWAS checks

---

## 📦 Getting Started

**1. [Install Container Tools](containerization/container_install.md)**

- Instructions for Docker, Singularity, or Apptainer.
- How to obtain pre-built containers.

**2. [Sample & Genotype QC Pipeline](ind_geno_qc.md)**

- Quick start for running the main QC pipeline.
- See [Detailed QC Steps](detailed_steps/ind_geno_qc_steps.md) for in-depth explanations of the steps performed and other implementation details.

**3. [Phenotype Processing](phenotyping.md)**

- How to adjust and transform phenotypes.

**4. [Pre-phasing Checks](pre_phasing_checks.md)**

- Ensure your data is ready for phasing.

**5. [GWAS Pipeline](gwas.md)**

- Running genome-wide association analysis.

**6. [Post-GWAS Checks](post_gwas_checks.md)**

- Automated QC and reporting for GWAS results.

---

## 🛠️ Developer & Advanced User Section

If you need to build or customize containers, or run the pipeline in new environments:

- **[Container Image Creation & Export](containerization/container_create.md)**  
  Build Docker images, export them, convert to Singularity/Apptainer, and package releases.

- **[Singularity/Apptainer User-Level Install & Conversion](containerization/singularity_install.md)**  
  Scripts for user-level installation and Docker-to-SIF conversion.

---

## 📚 Additional Resources

- All scripts and configuration files are referenced in the respective documentation pages.
- For troubleshooting, see the "Troubleshooting" section in each pipeline step.

---

## 🧭 Navigation

- [Container Installation](containerization/container_install.md)
- [Sample & Genotype QC Pipeline](ind_geno_qc.md)
- [Detailed QC Steps](detailed_steps/ind_geno_qc_steps.md)
- [Phenotyping](phenotyping.md)
- [Pre-phasing Checks](pre_phasing_checks.md)
- [GWAS](gwas.md)
- [Post-GWAS Checks](post_gwas_checks.md)
- [Developer Guide: Container Creation](containerization/container_create.md)
- [Developer Guide: Singularity Install](containerization/singularity_install.md)

---
