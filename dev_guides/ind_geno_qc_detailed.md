---
---

<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./index.html">⬅️ Return to Homepage</a>
  <a href="./pre_phasing_checks.html">Go to Step 2 [Pre-Phasing Checks] ➡️</a>
</div>

# Sample Variant QC Pipeline [WITH IMPLEMENTATION DETAILS]

<style>
.hero-title {
   font-size: 2.4rem;
   line-height: 1.05;
   color: #1f3b5a;
   font-weight: 800;
   margin-top: 0.75rem;
   margin-bottom: 0.5rem;
   padding-bottom: 0.35rem;
   border-bottom: 3px solid #e6eef6;
}
@media (min-width: 768px) {
   .hero-title { font-size: 3rem; }
}
</style>

<h1 class="hero-title">Sample Variant QC Pipeline [WITH IMPLEMENTATION DETAILS]</h1>

# Overview

This repository contains scripts and utilities for running a comprehensive sample variant quality control (QC) pipeline, including ancestry prediction and per-chromosome QC reporting. The containerized implementation ensures reproducible execution across different computing environments.

# Features

- **Automated Build Detection** (hg37/hg38) with liftover using progressive MAF filtering strategies
- **Comprehensive QC** filtering and statistics with customizable thresholds
- **Ancestry Prediction** using 1000G + HGDP reference data with MANCS or Random Forest algorithms
- **Principal Component Analysis** for population structure with projection capabilities
- **Kinship Analysis** using KING to identify related samples
- **Interactive Reports** with consistent styling and comprehensive plots
- **Containerized** execution with Docker/Singularity/Apptainer support
- **Multi-format Input Support** (.bed/.bim/.fam, BGEN, .ped/.map, compressed archives)

# Requirements

- Docker, Singularity or Apptainer
- 8GB+ RAM, 50GB+ storage recommended
- Linux/macOS (Windows via WSL)
- Bash shell
- (Optional) R and Python if running outside the container

# Input/Output

**Accepts:** PLINK files (.bed/.bim/.fam), BGEN, .ped/.map, compressed archives (.tar.gz)  
**Produces:** QC'd genotypes, ancestry labels, PCs, kinship results, HTML/PDF reports

# Directory Structure

```bash
sample_variant_qc/
├── scripts/                 # Main pipeline and stepwise shell scripts
├── utils/                   # R scripts, plotting, and support utilities  
├── data/                    # Input data (e.g., population files)
├── output/                  # Output directory for results and reports
├── config/
│   ├── parameters.txt       # Configuration file for pipeline variables
│   └── mounts.txt          # Mount path definitions
├── Dockerfile              # Docker image definition
└── SAMPLE_VARIANT_QC_RUNNER.sh  # Main execution script
```

# Output Structure

```bash
output/
└── STUDY_NAME_Outputs/
    ├── Ancestry/                    # Ancestry predictions and population labels
    ├── AncestrySpecificPCA/         # Population-specific principal components
    ├── Kinship/                     # Relatedness analysis results
    ├── Logs/                        # Pipeline execution logs and error messages
    ├── PCA/                         # Principal component analysis outputs
    ├── PostBasicQC/                 # Genotype files after basic QC filtering
    ├── PostQC_PerChromosome/        # QC'd data split by chromosome
    ├── PostQCStats_PerChromosome/   # QC statistics per chromosome
    ├── PostSampleVariantQC/         # Final QC'd genotype files
    ├── PreQCStats/                  # Pre-QC baseline statistics
    ├── PreQCStats_PerChromosome/    # Pre-QC statistics per chromosome
    └── Reports/                     # HTML and PDF summary reports
```

# Default QC Thresholds

- **Build check:** Requires ≥80% variant overlap between study and reference data (tested with no MAF threshold, MAF>1% and MAF>5%)
- **Sample call rate:** 90% (0.9)
- **Variant call rate:** 90% (0.9)  
- **Minor allele frequency:** 1% (0.01)
- **Hardy-Weinberg equilibrium:** p > 1e-50
- **Sample heterozygosity:** within 3 IQR of median
- **Kinship threshold:** 0.354 (MZ twins/duplicates only)
- **Ancestry prediction algorithm:** MANCS (Multi-Ancestry Nearest Control Selection)
- **Ancestry confidence:** 80% (0.8), fallback to 75% if no samples meet 80%

*All thresholds are customizable via `parameters.txt`*

# Reference Data

Uses harmonized 1000 Genomes + HGDP data:

- **3,280 samples**, 8.15M high-quality variants
- **Continental ancestry labels** (AFR, AMR, EAS, EUR, SAS)
- **Available in hg37 and hg38 builds**
- **Source:** gnomAD v3.1.2 HGDP + 1KG subset with additional QC filtering

# Quick Start

1. **Clone the GitHub repository:**

   ```bash
   git clone git@github.com:giant-consortium/sample_variant_qc.git
   cd sample_variant_qc
   chmod +x SAMPLE_VARIANT_QC_RUNNER.sh
   ```

2. **Edit `parameters.txt`** to set paths and options for your data. The `path_to_data` and `study_name` are altered in every execution. Always set `study_name` to match the base name of your PLINK files (no file extensions).

   ```bash
   # Example: If your files are named STUDY4_SAS.bed, STUDY4_SAS.bim, STUDY4_SAS.fam
   study_name=STUDY4_SAS
   ```

   **Note:** If these are stored in a compressed form (.tar.gz) or in alternate formats (.ped/.map, .bgen) the conversion to PLINK is done automatically. Do not include the file extension in the `study_name` parameter.

3. **Run the pipeline:**

   ```bash
   # With Docker
   ./SAMPLE_VARIANT_QC_RUNNER.sh --docker

   # With Singularity
   ./SAMPLE_VARIANT_QC_RUNNER.sh --singularity

   # With Apptainer
   ./SAMPLE_VARIANT_QC_RUNNER.sh --apptainer

   # To force data download:
   ./SAMPLE_VARIANT_QC_RUNNER.sh --docker --force_data_download

   # To get the most recent containers:
   ./SAMPLE_VARIANT_QC_RUNNER.sh --docker --get_update
   ```

4. **Outputs** will be saved in a sub-folder named `study_name` at the path specified by `path_to_output` in `parameters.txt`.

# Pipeline Overview

The pipeline performs the following steps:

1. **Setup & Format Conversion** - Convert input to PLINK format
2. **Build Detection** - Determine hg37/hg38 and liftover if needed  
3. **Pre-QC Statistics** - Generate baseline quality metrics
4. **Basic QC** - Filter samples/variants (call rate, MAF, HWE, heterozygosity)
5. **Kinship Analysis** - Identify related samples using KING
6. **SNP Intersection** - Align with reference data for PCA
7. **PCA Generation** - Calculate population structure covariates
8. **Ancestry Prediction** - Assign continental ancestry labels
9. **Ancestry-Specific PCA** - Generate population-specific PCs
10. **Reporting** - Create comprehensive HTML/PDF reports

# Workflow Diagram

![Sample Variant QC Pipeline Flowchart](./Overview_SampleVariantQC_Pipeline.png)

# Troubleshooting

- Check the log files in the `./output/study_name/Logs` directory for errors.
- Ensure all required paths in `parameters.txt` are correct and accessible.
- Stepwise outputs are in the `./output/study_name/` directory.
- For container issues, verify your container runtime is installed and running.
- If build detection fails, check variant overlap diagnostics in the logs.

---

# Pipeline Implementation Details

This section provides detailed explanations of each pipeline step, implementation specifics, and technical details for developers and advanced users.

## SAMPLE_VARIANT_QC_RUNNER.sh

This file configures paths, performs data downloads, and downloads prebuilt container images (docker .tar or singularity .sif) from GCS and loads/tags them; use --get_update to request an updated tar (this will re-download and replace existing container files).

The runner reads configuration from  `config/parameters.txt`, and then executes the pre-built image with passed parameters to execute the complete workflow. The parameters.txt file contains the settings referenced by every step (study_name, path_to_data, path_to_output, thresholds, container flags)

### Runner usage

Supported flags:

- --docker           : run pipeline via Docker (downloads/loads docker .tar)
- --singularity      : run pipeline via Singularity
- --apptainer        : run pipeline via Apptainer (default if none specified)
- --force_data_download : force download of reference data
- --get_update       : re-download container artifacts (refresh .tar / .sif)
- --interactive      : run container interactively (shell)

### Checksums / integrity

The runner requires a checksums file (./checksums.sha256) to validate downloaded container artifacts. Ensure checksums.sha256 is present alongside the runner or in the same directory where downloads occur. This checksums file is available on the GitHub repository.

### Container behavior

Default runtime: Apptainer (if none specified). Behavior:

- Docker: downloads giant_sample_variant_qc_latest.tar from the configured GCS location and runs docker load → docker tag → docker run.
- Singularity/Apptainer: downloads giant_sample_variant_qc_latest.sif from GCS and runs the SIF.
- --get_update forces re-download and replacement of existing container files.

## Reference Datasets

### Data Source

1000 Genomes (1KG) and Human Genome Diversity Project (HGDP) datasets, harmonized by gnomAD

### Raw Data Location

 `gs://gcp-public-data--gnomad/release/3.1.2/mt/genomes/gnomad.genomes.v3.1.2.hgdp_1kg_subset_dense.mt`

### Processing Pipeline

1. **Sample filtering:** Excluded low-quality and related samples identified by gnomAD → **3,280 samples**
2. **Variant QC using PLINK2:**
   - Minor Allele Frequency ≥ 1%
   - Hardy-Weinberg Equilibrium p-value > 1e-6
   - Variant call rate ≥ 98%
   - SNPs only (A,C,G,T restriction)
3. **Final dataset:** **8.15M high-quality variants**
4. **Build availability:** hg38 (primary) and hg37 (liftover)

## Development Environment

### Containerized (recommended)

The containers contain a reproducible environment (Ubuntu 22.04) with all pipeline dependencies installed:

- Python3 (pandas, numpy, scikit-learn, matplotlib)
- R (data.table, ggplot2, rmarkdown, knitr, kableExtra)
- PLINK2 / PLINK1.9
- FlashPCA (and deps: eigen3, boost)
- pandoc / wkhtmltopdf (report conversion)
- build tools: gcc, make, curl, unzip

### Host (non-container) prerequisites

If you run steps on the host (not using container images), install these minimum tools:

- System
  - Ubuntu/macOS: standard build tools (gcc, make), curl, tar, gzip
- Genotype tools
  - plink2 (recommended) and plink1.9
  - FlashPCA (or equivalent PCA tool)
  - UCSC liftOver (if liftover required)
- R >= 4.0 with packages:
  - data.table, ggplot2, rmarkdown, knitr, kableExtra
- Python 3.8+ with packages:
  - pandas, numpy, scipy, scikit-learn, matplotlib
- Reporting / conversion
  - pandoc; optional wkhtmltopdf for HTML to PDF
- Optional utilities
  - jq (JSON parsing), bcftools (if working with VCF), bgzip/tabix (if using compressed VCFs)

## Detailed Pipeline Steps

### Step 0: Setup and Format Conversion

#### Script: `scripts/Step0_Setup.sh`

#### Purpose: Ensure study genotype files are available in PLINK `.bed/.bim/.fam` format and create required output directories

#### Inputs

- `dataset_path` (prefix to study files), `path_to_data`, `study_name`, `reference_name`, `path_to_ref_data`
- Optional flags: `bgen_ref_flag` (ref-first|ref-last), `force_bed`

#### Outputs

- PLINK files: `<dataset_path>.bed/.bim/.fam` (converted if necessary)
- Created dirs: `stats_out_path`, `qc_out_path`, `pre_qc_dir`, `post_qc_dir`, `pca_out_path`, `kinship_out_path`, `ancestry_out_path`, `logs_out_path`, `temp_output_path`
- Manifest entries (via `utils/write_manifest.sh` or fallback `generated_files.txt`)

#### Dependencies

- `plink2`, `tar`, `awk`
- Note: ensure these are on `PATH` when running outside the containerized environment (host/VM/cluster node).

#### Behavior

1. If `${dataset_path}.tar.gz` exists, extract into `${path_to_data}`.
2. Search for genotype inputs in order:
   - `${dataset_path}.bed/.bim/.fam`
   - `${path_to_data}/${study_name}.bed/.bim/.fam`
   - `${path_to_data}/${study_name}/${study_name}.bed/.bim/.fam`
   - Exit with error if none found.
3. Convert formats as needed:
   - `.pgen/.pvar/.psam`: Convert to hard-calls using a threshold of 0.1 using PLINK2
   - `.bgen`: Convert using PLINK2 (pass `--ref-first`/`--ref-last` if `bgen_ref_flag` set; else `--ref-unknown`)
   - `.ped/.map`: Convert using PLINK2
4. Update reference `.bim` VIDs to `chr:pos:ref:alt` using `awk` (the script overwrites the canonical `.bim`).

### Step 1: Build Detection & Liftover

#### Script: `scripts/Step1_CheckBuild.sh`

#### Utility: `utils/check_build.R`,  `utils/convert_to_hg38.sh`

#### Purpose: Determine study build (hg37 vs hg38) using reference overlap and automatically liftover hg37 inputs to hg38 when required

#### Inputs

- Study `.bim`/PLINK files produced by Step 0
- Reference `.bim` files for hg37 and hg38 in `path_to_ref_data`

#### Outputs

- Build assignment (`hg37` or `hg38`) written to pipeline state
- Liftover outputs if performed (original files archived with `_hg37` suffix)

#### Dependencies

- `R` (runs `utils/check_build.R`), `liftOver` tool from UCSC, along with the chain file from UCSC for hg19 to hg38

#### Behavior

1. Compare study variant IDs/positions against reference hg37/hg38 `.bim` (accounting for `chr` prefix differences).
2. If overlap ≥ 80% with either build, assign that build.
3. If overlap < 80%, re-evaluate using progressive MAF filters (MAF>1% then MAF>5%).
4. If hg37 is detected and liftover is required, call `utils/convert_to_hg38.sh` which downloads the UCSC liftover chain, performs coordinate conversion, and archives originals with `_hg37` suffix.

#### Safety / Notes

- Preserve rsIDs when present; back up original files before liftover. Log diagnostics when strategies fail so users can inspect variant overlap statistics.

### Step 2: Pre-QC Statistics

#### Script: `Step2_PreQC.sh` | Report: `utils/report_qc_stats.Rmd`

#### Purpose

Generate baseline sample- and variant-level QC metrics and visual summaries prior to filtering to inform downstream QC decisions.

#### Inputs

- PLINK files (prefix) produced by Step 0: bed/bim/fam

#### Outputs

- Per-sample metrics: call rate, heterozygosity
- Per-variant metrics: MAF, call rate, HWE p-values, monomorphic counts
- Sex lists and discordant summary (if chrX data is detected)
- Per-chromosome split statistics (for downstream per-chromosome steps) if data_type=WGS. Not applicable in the default 'array' mode.
- RMarkdown HTML report and supporting plots (placed in `output/<study_name>/PreQCStats/`)
- Manifest entries for all produced files

#### Dependencies

- `plink2` and `plink1.9` for metric extraction
- `R` with packages data.table, ggplot2, rmarkdown, knitr
- `awk`, `sed`, `cut`, GNU `sort`, `coreutils`

#### Behavior

1. Compute sample call rates and heterozygosity using PLINK summary commands.
2. Run sex-check and flag discordant samples (write table but do not remove).
3. Compute variant-level statistics (MAF, call rate, HWE p-values) and flag monomorphic sites.
4. Split variant and metric summaries by chromosome if the input data is from whole genome sequencing. This is not produced for array data (defined by variable data_type in parameters.txt)
5. Render RMarkdown report with summary tables and diagnostic plots (histograms, scatterplots, per-chromosome summaries).

#### Safety / Notes (Step 2)

- No sample/variant removals are performed in this step — it is used to incorporate pre-QC information in the reports

### Step 3: Basic Quality Control

#### Script: `scripts/Step3_BasicQC.sh` | Utility: `./utils/filter_heterozygosity.py`, optional f‑score helpers

#### Purpose

Perform primary sample- and variant-level filtering to produce a cleaned cohort for downstream analyses and generate summary reports and manifest entries.

#### Behavior

1. Retain bi‑allelic variants only.
2. Produce IQR OR F‑score‑based remove‑lists (default to F-score based removal) and create reporting copies of filtered datasets (for inspection). By default, samples with F-score outside [mean ± 4SD] OR heterozygosty outside [median ± 3×IQR] are removed.
3. Apply sample‑level filters (missingness) to create a sample‑filtered dataset.
4. Apply variant‑level filters (call rate, MAF/MAC, HWE) to create the variant‑filtered dataset.
5. Compute post‑QC summary statistics and render QC reports
6. Optionally generate per‑chromosome post‑QC stats when input is WGS.

#### Default filter values (from config/parameters.txt)

1. Data type: array
2. Sample call rate: Drop if call rate < 90%
3. Variant call rate: Drop if call rate < 90%
4. Minor allele frequency (MAF): Retain if MAF > 0.1%
5. Minor allele count (MAC): Retain if MAC >=
6. Hardy–Weinberg equilibrium (HWE): behavior depends on study_anc_expectation in parameters.txt:
   a. study_anc_expectation = "HOM" (predominantly single ancestry) → default HWE p > 1e-6
   b. study_anc_expectation = "HET" (mixed ancestries) → default HWE p > 1e-12
   c. User can explicitly override via variant_hwe_thresh in parameters.txt (explicit value wins)
7. Heterozygosity filtering:
 a. Methods: f_score (default) or het (set variable het_filter_method)
   b. Defaults:
   - F-score cutoff: num_f_sd_shifts = 4 (mean ± 4 SD)
   - IQR-based cutoff: num_iqr_shifts = 3 (median ± 3 × IQR)

##### Outputs

- Filtered PLINK datasets (prefixes): biallelic, HetFiltered (reporting), FscoreFiltered (reporting), SampleFiltered, VariantFiltered (final).
- Remove‑lists used for filtering (heterozygosity and F‑score).
- Post‑QC summary statistics for the final dataset (PLINK missing/hardy/freq/het outputs).
- Per‑chromosome post‑QC summaries (sex chromosomes only for array data).

##### Dependencies

- plink2 (required)
- Python 3.8+ (to run utils/filter_heterozygosity.py and optional f‑score helpers)
- R >= 4.0 with rmarkdown/knitr and plotting packages (for report rendering)
- POSIX tools: bash, awk, sed, sort, coreutils, curl/wget
- Repository utilities: utils/write_manifest.sh, utils/filter_heterozygosity.py, utils/filter_fscore.py, report Rmd templates

### Step 4: Kinship Analysis

#### Script: `Step4_KinshipTest.sh` | **Report:** `./utils/report_kinship.Rmd`

**Implementation:**

1. **KING algorithm** via PLINK2 for pairwise kinship coefficients
2. **Output:** `.kin0` file with kinship coefficients and IBS0 values
3. **Sample removal:** Automatic filtering above kinship threshold (default: 0.354 for MZ twins/duplicates only)
4. **Relationship classification:** MZ twins, 1st/2nd/3rd degree relatives
5. **Visualization:** Kinship coefficient distributions and plots

### Step 5: SNP Intersection and LD Pruning

#### Script: `Step5_SNPIntersectForPCA.sh`

**Process:**

1. **SNP extraction:** Identify overlapping variants between study and reference
2. **Allele alignment:** Harmonize alleles between datasets
3. **Duplicate removal:** Handle multi-allelic and duplicate variants
4. **LD pruning:** Perform linkage disequilibrium pruning on reference data
5. **Dataset restriction:** Limit both datasets to LD-pruned SNPs
6. **Quality check:** Verify identical .bim files between datasets

**Technical note:** Chunking implementation for large variant sets to manage memory usage

### Step 6: Principal Component Analysis

#### Script: `Step6_PCA.sh` | **Utility:** `./utils/plot_pca.R` | **Report:** `./utils/report_pca.Rmd`

**Implementation:**

1. **Reference PCA:** Generate principal components using FlashPCA
2. **Projection:** Project study samples onto reference PC space
3. **Sign alignment:** Ensure consistent PC orientations
4. **Visualization:** Multi-panel PC plots with population labels

**Standardized plotting:** Consistent formatting across all PCA visualizations using `./utils/plot_pca.R`

### Step 7: Continental Ancestry Determination

#### Script: `Step7_AncestryModel.sh` | **Utility:** `./utils/train_pca_model.py` | **Report:** `./utils/report_ancestry_predictions.Rmd`

**Training process:**

1. **Training data:** Reference dataset PCs with continental labels
2. **Label processing:** Exclude 'oth' samples, combine NFE/FIN → EUR
3. **Algorithm options:**
   - **MANCS** (Multi-Ancestry Nearest Control Selection) - default
   - **Random Forest** with optional hyperparameter tuning

**Prediction and assignment:**

1. **Probability assignment:** Each sample gets probabilities for all ancestry groups
2. **Confidence thresholding:**
   - Primary: ≥80% confidence for assignment
   - Fallback: ≥75% if no samples meet 80% threshold
3. **Visualization:** PC plots with ancestry predictions and confidence distributions

### Step 8: Ancestry-Specific PCA

#### Script: `Step8_AncestrySpecificPCA.sh`

**Process:**

1. **Ancestry filtering:** Extract samples by predicted ancestry (≥80% confidence)
2. **Projection:** Project ancestry-specific subsets onto reference PC space
3. **Validation plots:** Visual verification of ancestry-specific PC clustering

**Output:** Ancestry-specific PC files for downstream association analyses

### Step 9: Cleanup and Reporting

#### Script: `CleanUp.sh`

**Final steps:**

1. **File logging:** Document all intermediate and final outputs
2. **Binary cleanup:** Remove temporary executables
3. **Report conversion:** Convert HTML reports to PDF format
4. **Combined reporting:** Generate unified PDF from all analysis steps

> **Styling Note:** All HTML reports use consistent formatting via `./utils/qc_report_style.css`
