---
layout: default
---

<style>
  table { font-size: 0.85em; }
  table th, table td { padding: 4px 8px; }
</style>

<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./index.html">⬅️ Return to Homepage</a>
  <a href="./pre_phasing_checks.html">Go to Step 2 [Pre-Phasing Checks] ➡️</a>
</div>

# Sample Variant QC Pipeline

A containerized sample and variant QC pipeline providing automated build detection, ancestry prediction, PCA, kinship analysis, and HTML/PDF reports. Requires Docker, Singularity, or Apptainer; 8 GB+ RAM; 50 GB+ storage; Linux/macOS (Windows via WSL).

## Contents

- [Quick Start](#quick-start)
- [Input / Output](#input-output)
- [Default QC Thresholds](#default-qc-thresholds)
- [Pipeline Overview](#pipeline-overview)
- [Repository Structure](#repository-structure)
- [Reference Data](#reference-data)
- [Troubleshooting](#troubleshooting)

---

<a id="quick-start"></a>

## Quick Start

1. **Clone the repository:**

   ```bash
   git clone git@github.com:giant-consortium/sample_variant_qc.git
   cd sample_variant_qc
   chmod +x SAMPLE_VARIANT_QC_RUNNER.sh
   ```

2. **Edit `parameters.txt`** — set `path_to_data`, `path_to_output`, and `study_name` (basename of your genotype files, no extension). Format conversion is automatic.

   ```bash
   study_name=STUDY4_SAS
   path_to_data=/path/to/input
   path_to_output=/path/to/output
   ```

3. **Run the pipeline:**

   ```bash
   ./SAMPLE_VARIANT_QC_RUNNER.sh --apptainer
   ```

   | Flag | Description |
   |------|-------------|
   | `--docker` | Run using Docker |
   | `--singularity` | Run using Singularity |
   | `--apptainer` | Run using Apptainer *(default)* |
   | `--interactive` | Open an interactive shell inside the Docker container |
   | `--force_data_download` | Re-download reference / build-check / population data |
   | `--get_update` | Fetch the latest container image before running |

### What You'll Get

After the pipeline completes, all final outputs are in `output/<study_name>_Outputs/PostSampleVariantQC/`:

- **`<study_name>_postQC.bed/bim/fam`** → Clean genotypes for imputation
- **`<study_name>_Combined_Report.pdf`** → QC summary (upload to GIANT)
- **`<study_name>_<ancestry>_PCA.txt`** → Ancestry-specific PCs for GWAS covariates
- **`<study_name>_AncestryPredictions.txt`** → Continental ancestry labels

---

<a id="input-output"></a>

## Input / Output

### Accepted Inputs

The pipeline accepts genotype data in the following formats:

| Format | Files | Notes |
|--------|-------|-------|
| **PLINK binary** | `.bed`, `.bim`, `.fam` | Preferred format; passed through directly |
| **BGEN** | `.bgen`, `.sample` | Converted to PLINK in Step 0 |
| **PGEN** | `.pgen`, `.pvar`, `.psam` | Converted to PLINK in Step 0 |
| **PLINK text** | `.ped`, `.map` | Converted to binary PLINK in Step 0 |
| **Compressed** | `.tar.gz` | Extracted in Step 0; must contain PLINK binary (.bed/.bim/.fam) |

**Required:** Study samples must be on **hg37 or hg38** (auto-detected in Step 1; liftover applied if needed).

All output paths are relative to `output/<study_name>_Outputs/`.

### Final Deliverables (PostSampleVariantQC/)

These are the **final QC'd files** produced by this step:

| File | Description |
|------|-------------|
| `<study_name>_postQC.bed/bim/fam` | **QC'd genotypes** (relateds removed, variants filtered)
| `<study_name>_<ancestry>_filtered.bed/bim/fam` | **Ancestry-specific genotypes** (per AFR/AMR/EAS/EUR/SAS)
| `<study_name>_AncestryPredictions.txt` | Continental ancestry labels with confidence scores
| `<study_name>_projections.txt` | **Global PCs** (samples projected onto reference space)
| `<study_name>_<ancestry>_PCA.txt` | **Ancestry-specific PCs** (fine-scale structure)
| `<study_name>_combined_ancestry_pca.tsv` | Consolidated ancestry-specific PCs (all ancestries)
| `<study_name>_rsid_mapping.txt` | rsID to chr:pos mapping (if rsIDs present)
| `<study_name>_Combined_Report.pdf` | **QC summary report**; **Upload to GIANT** |

### Intermediate Outputs (for QC review)

| Directory | Description |
|-----------|-------------|
| `PostBasicQC/` | Genotypes after variant filtering (call rate, MAF, HWE) but before kinship removal. Intermediate QC checkpoint |
| `Kinship/` | Kinship matrix (.kin0), related-sample removal lists, kinship plots for reviewing relatedness structure |
| `PCA/` | Reference PCA loadings, mean/SD, eigenvalues, and population labels for re-projecting future samples |
| `Ancestry/` | Ancestry prediction model, population labels, prediction plots for reviewing ancestry assignments |
| `AncestrySpecificPCA/` | Per-ancestry PCA loadings, eigenvalues, variance explained, and plots for reviewing within-ancestry structure |
| `QCStats/` | Heterozygosity outlier lists, variant/sample statistics, call rate summaries for identifying QC failures |
| `Logs/` | Per-step execution logs with timestamps and error messages for troubleshooting |
| `Reports/` | Individual HTML and PDF reports from each pipeline step for detailed QC review |
| `PostQC_PerChromosome/` | Per-chromosome QC'd genotype files (WGS only) |
| `PostQCStats_PerChromosome/` | Per-chromosome QC statistics and plots (WGS only) |
| `PreQCStats_PerChromosome/` | Per-chromosome baseline statistics before filtering (WGS only) |

---

<a id="default-qc-thresholds"></a>

## Default QC Thresholds

| Metric | Threshold |
|--------|-----------|
| Build check (variant overlap) | ≥ 80 % (tested at MAF > 0 %, > 1 %, > 5 %) |
| Sample call rate | 0.9 |
| Variant call rate | 0.9 |
| Minor allele frequency | 0.001 (0.1 %) |
| Minor allele count | ≥ 5 |
| HWE p-value | > 1e-12 (homogeneous) / > 1e-6 (mixed ancestry) |
| Sample heterozygosity | Outlier-based (configurable) |
| Kinship (KING) | 0.354 (MZ twins / duplicates only) |
| Ancestry algorithm | MANCS |
| Ancestry confidence | 0.80, fallback to 75th percentile |

*All thresholds are customizable in `parameters.txt`.*

---

<a id="pipeline-overview"></a>

| Step | Script | What it does |
|------|--------|-------------|
| 0 | `Step0_Setup.sh` | Detects input format (.bed/.bim/.fam passed through; BGEN, PGEN, .ped/.map, .tar.gz converted to PLINK) |
| 1 | `Step1_CheckBuild.sh` | Detects genome build (hg37 vs hg38) via reference overlap; lifts over to hg38 if needed |
| 2 | `Step2_PreQC.sh` | Computes baseline statistics (call rates, MAF, HWE, heterozygosity) before filtering |
| 3 | `Step3_BasicQC.sh` | Filters samples by call rate and heterozygosity; filters variants by call rate, MAF, MAC, and HWE |
| 4 | `Step4_SNPIntersectAndPrune.sh` | Intersects study variants with 1KG+HGDP reference, harmonizes alleles, removes palindromic SNPs, LD-prunes |
| 5 | `Step5_KinshipTest.sh` | Estimates pairwise kinship (KING); removes related/duplicate samples via greedy algorithm |
| 6 | `Step6_PCA.sh` | Computes PCs on the reference panel and projects study samples into the same space |
| 7 | `Step7_AncestryModel.sh` | Assigns continental ancestry (AFR, AMR, EAS, EUR, SAS) using MANCS or Random Forest on projected PCs |
| 8 | `Step8_FinalizeOutputsPostQC.sh` | Creates final post-QC datasets (global and per-ancestry) with relateds removed; copies ancestry predictions and global PCA outputs |
| 9 | `Step9_AncestrySpecificPCA.sh` | Within-ancestry PCs for fine-scale population structure (covariates for association analyses) |
| 10 | `Step10_ConsolidateAndClean.sh` | Merges HTML reports into a combined PDF, writes final manifest, removes temporary files |

<a href="./diagrams/overview/Overview_SampleVariantQC_Pipeline.png" target="_blank">
  <img src="./diagrams/overview/Overview_SampleVariantQC_Pipeline.png" alt="Sample Variant QC Pipeline Flowchart" style="width: 100%; max-width: 100%;" />
</a>

*Click the image to view full size.*

---

<a id="reference-data"></a>

## Reference Data

Uses harmonized 1000 Genomes + HGDP data (gnomAD v3.1.2):

- **3,280 samples**, 8.15 M high-quality variants
- Continental ancestry labels: AFR, AMR, EAS, EUR, SAS
- Available in hg37 and hg38 builds
- Downloaded automatically on first run.

---

<a id="troubleshooting"></a>

## Troubleshooting

- Check `output/<study_name>_Outputs/Logs/` for error messages.
- Verify all paths in `parameters.txt` are correct and accessible.
- Ensure your container runtime is installed and running.
- If build detection fails, inspect variant-overlap diagnostics in the logs.
- Re-run with `--force_data_download` if reference data appears corrupted.

---

**For implementation details on each pipeline step**, see the [Detailed Guide](dev_guides/ind_geno_qc_detailed.html).
