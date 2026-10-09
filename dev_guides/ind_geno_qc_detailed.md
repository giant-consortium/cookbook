---
layout: default
---

# Sample Variant QC Pipeline — Implementation Guide

See also: [Pipeline overview and QC thresholds](./../ind_geno_qc.html) · [Homepage](./../index.html) · [Workflow diagram](./../diagrams/overview/Overview_SampleVariantQC_Pipeline.png)

---

## Contents

| # | Section | Description |
| --- | --------- | ------------- |
| — | [Runner script](#runner) | Entry point — downloads data, builds image, runs pipeline |
| — | [Reference datasets](#reference) | 1KG/HGDP reference data used for ancestry and QC |
| — | [Development environment](#environment) | Dockerfile and tool versions |
| 0 | [Setup and Format Conversion](./ind_geno_qc_step0.html) | `Step0_Setup.sh` — format conversion, directory setup |
| 1 | [Build Detection and Liftover](./ind_geno_qc_step1.html) | `Step1_CheckBuild.sh` — hg38/hg37 detection, liftover |
| 2 | [Pre-QC Statistics](./ind_geno_qc_step2.html) | `Step2_PreQC.sh` — call rates, HWE, sex check |
| 3 | [Basic Sample and Variant-Level QC](./ind_geno_qc_step3.html) | `Step3_BasicQC.sh` — MAF, MAC, HWE, heterozygosity filters |
| 4 | [SNP Intersection and LD Pruning](./ind_geno_qc_step4.html) | `Step4_SNPIntersectAndPrune.sh` — variant harmonisation, pooled genome-wide pruning |
| 5 | [Relatedness Estimation](./ind_geno_qc_step5.html) | `Step5_KinshipTest.sh` — KING via PLINK2 |
| 6 | [Principal Component Analysis](./ind_geno_qc_step6.html) | `Step6_PCA.sh` — FlashPCA reference PCA + study projection, for ancestry prediction only |
| 7 | [Ancestry Prediction](./ind_geno_qc_step7.html) | `Step7_AncestryModel.sh` — MANCS / Random Forest |
| 8 | [Finalize Outputs Post-QC](./ind_geno_qc_step8.html) | `Step8_FinalizeOutputsPostQC.sh` — remove relateds, split by ancestry |
| 9 | [Ancestry-Specific PCA](./ind_geno_qc_step9.html) | `Step9_AncestrySpecificPCA.sh` — the final, per-ancestry PCs used downstream |
| 10 | [Report Consolidation and Cleanup](./ind_geno_qc_step10.html) | `Step10_ConsolidateAndClean.sh` — combine reports to PDF, cleanup, manifest |

---

<a id="runner"></a>

## SAMPLE_VARIANT_QC_RUNNER.sh

Entry point for the pipeline. It fetches the container image and reference data, then runs the containerized workflow against the paths in `parameters.txt` (repo root). End users need only this script, `parameters.txt`, and `checksums.sha256`.

**Key Steps:**

1. **Parse flags:** `--docker`, `--singularity`, or `--apptainer` (default), plus `--get_update`, `--force_data_download`, and `--path_to_parameters_file`
2. **Load the container:** `docker load` the `.tar` (Docker), or download the `.sif` (Singularity/Apptainer), when missing or with `--get_update`
3. **Read paths** from `parameters.txt` and check that `path_to_data` exists
4. **Download reference data** into `path_to_build_check`, `path_to_ref_data`, and `path_to_pop_files` when missing or with `--force_data_download`. Each archive is staged in `./data/` and SHA256-verified against `checksums.sha256`
5. **Run the container** with five bind mounts (input data, reference, build check, output, population labels). `parameters.txt` is passed in as environment variables, and the container runs `/scripts/RunQCPipeline.sh`

**Performance Notes:**

- Container image: ~3.6 GB, downloaded once and cached
- Reference data: ~2–3 GB compressed, cached after the first run
- Re-runs reuse both unless `--get_update` or `--force_data_download` is passed

**Configuration:**

- All paths and thresholds live in `parameters.txt` at the repo root
- Use `--path_to_parameters_file <path>` to point at a different file
- Edits take effect on the next run; nothing needs rebuilding

---

<a id="reference"></a>

## Reference Datasets

**Data Source:** 1000 Genomes (1KG) and Human Genome Diversity Project (HGDP) datasets, harmonized by gnomAD

**Location:** `gs://gcp-public-data--gnomad/release/3.1.2/mt/genomes/gnomad.genomes.v3.1.2.hgdp_1kg_subset_dense.mt`

**Processing Pipeline:**

1. **Sample filtering:** Excluded low-quality and related samples identified by gnomAD, resulting in **3,280 samples**
2. **Variant QC using PLINK2:**
   - Minor Allele Frequency ≥ 1%
   - Hardy-Weinberg Equilibrium p-value > 1e-6
   - Variant call rate ≥ 98%
   - SNPs only (A,C,G,T restriction)
3. **Final dataset:** **8.15M high-quality variants**
4. **Build availability:** hg38 (primary) and hg37 (liftover)

---

<a id="environment"></a>

## Development Environment (Dockerfile)

**Base System:** Ubuntu 22.04

**Core Tools:**

- **Python3** with pandas, numpy, matplotlib, scipy, json, sklearn
- **R** with data.table, kableExtra, knitr, rmarkdown, pandoc
- **FlashPCA** with dependencies (eigen3, boost, spectra)
- **PLINK2** and **PLINK1.9**

**Installation:** All dependencies installed via apt-get, scripts made executable with chmod
