---
---

<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./index.html">⬅️ Return to Homepage</a>
  <a href="./pre_phasing_checks.html">Go to Step 2 [Pre-Phasing Checks] ➡️</a>
</div>

# Sample Variant QC Pipeline [WITH IMPLEMENTATION DETAILS]

## Overview

This repository contains scripts and utilities for running a comprehensive sample variant quality control (QC) pipeline, including ancestry prediction and per-chromosome QC reporting. The containerized implementation ensures reproducible execution across different computing environments.

## Features

- **Automated Build Detection** (hg37/hg38) with liftover using progressive MAF filtering strategies
- **Comprehensive QC** filtering and statistics with customizable thresholds
- **Ancestry Prediction** using 1000G + HGDP reference data with MANCS or Random Forest algorithms
- **Principal Component Analysis** for population structure with projection capabilities
- **Kinship Analysis** using KING to identify related samples
- **Interactive Reports** with consistent styling and comprehensive plots
- **Containerized** execution with Docker/Singularity/Apptainer support
- **Multi-format Input Support** (.bed/.bim/.fam, BGEN, .ped/.map, compressed archives)

## Requirements

- Docker, Singularity or Apptainer
- 8GB+ RAM, 50GB+ storage recommended
- Linux/macOS (Windows via WSL)
- Bash shell
- (Optional) R and Python if running outside the container

## Input/Output

**Accepts:** PLINK files (.bed/.bim/.fam), BGEN, .ped/.map, compressed archives (.tar.gz)  
**Produces:** QC'd genotypes, ancestry labels, PCs, kinship results, HTML/PDF reports

## Directory Structure

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

## Output Structure

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

## Default QC Thresholds

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

## Reference Data

Uses harmonized 1000 Genomes + HGDP data:

- **3,280 samples**, 8.15M high-quality variants
- **Continental ancestry labels** (AFR, AMR, EAS, EUR, SAS)
- **Available in hg37 and hg38 builds**
- **Source:** gnomAD v3.1.2 HGDP + 1KG subset with additional QC filtering

## Quick Start

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

## Pipeline Overview

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

## Troubleshooting

- Check the log files in the `./output/study_name/Logs` directory for errors.
- Ensure all required paths in `parameters.txt` are correct and accessible.
- Stepwise outputs are in the `./output/study_name/` directory.
- For container issues, verify your container runtime is installed and running.
- If build detection fails, check variant overlap diagnostics in the logs.

---

## Pipeline Implementation Details

This section provides detailed explanations of each pipeline step, implementation specifics, and technical details for developers and advanced users.

### SAMPLE_VARIANT_QC_RUNNER.sh

This file configures paths, performs data downloads, and builds the Docker image. Once built, it calls the Docker image with the passed parameters and executes the complete workflow.

**Key Steps:**

1. **Set mount paths** to study dataset, reference data, build check data and output
2. **Check Docker installation** and verify Docker is running
3. **Download reference data** if not present or if `--force_data_download` flag is set
4. **Build Docker image** if not present or if `--force_build` flag is set
5. **Execute containerized pipeline** with mounted data and parameters

**Performance Notes:**

- Reference data download: ~15 minutes
- Docker image build: ~30 minutes
- Dangling images and volumes are removed during rebuild to save disk space

**Configuration:**

- Mount paths defined in `config/mounts.txt`
- Environment variables set via `config/parameters.txt`
- Both files can be modified between runs without rebuilding the image

### Reference Datasets

**Data Source:** 1000 Genomes (1KG) and Human Genome Diversity Project (HGDP) datasets, harmonized by gnomAD

**Location:** `gs://gcp-public-data--gnomad/release/3.1.2/mt/genomes/gnomad.genomes.v3.1.2.hgdp_1kg_subset_dense.mt`

**Processing Pipeline:**

1. **Sample filtering:** Excluded low-quality and related samples identified by gnomAD → **3,280 samples**
2. **Variant QC using PLINK2:**
   - Minor Allele Frequency ≥ 1%
   - Hardy-Weinberg Equilibrium p-value > 1e-6
   - Variant call rate ≥ 98%
   - SNPs only (A,C,G,T restriction)
3. **Final dataset:** **8.15M high-quality variants**
4. **Build availability:** hg38 (primary) and hg37 (liftover)

### Development Environment (Dockerfile)

**Base System:** Ubuntu 22.04

**Core Tools:**

- **Python3** with pandas, numpy, matplotlib, scipy, json, sklearn
- **R** with data.table, kableExtra, knitr, rmarkdown, pandoc
- **FlashPCA** with dependencies (eigen3, boost, spectra)
- **PLINK2** and **PLINK1.9**

**Installation:** All dependencies installed via apt-get, scripts made executable with chmod

### Detailed Pipeline Steps

#### Step 0: Setup and Format Conversion

**Script:** `Step0_Setup.sh`

1. **Binary setup:** Copy PLINK1.9 and PLINK2 binaries to `/` directory
2. **Format conversion:** Convert study files to PLINK format
   - **Supported inputs:** .tar.gz, .ped/.map, .bgen
   - **Output:** .bed/.bim/.fam format
3. **Directory creation:**
   - Study-specific output: `./output/<STUDY_NAME>_Outputs/`
   - Subdirectories: InitialQC, PCA, Kinship, Ancestry, Logs

#### Step 1: Build Detection and Liftover

**Script:** `Step1_CheckBuild.sh` | **Utility:** `./utils/check_build.R`

**Enhanced Build Detection Process:**

1. **Initial comparison:** Remove 'chr' prefix, compare study vs reference hg37 .bim files
2. **hg38 comparison:** Add 'chr' prefix, compare study vs reference hg38 .bim files
3. **Primary decision:** If ≥80% overlap with either build, assign build
4. **Progressive MAF filtering** (if <80% overlap):
   - **Strategy 1:** Filter to MAF > 1%, re-test build detection
   - **Strategy 2:** Filter to MAF > 5%, re-test build detection
   - **Failure handling:** Provide detailed diagnostics if all strategies fail
5. **rsID preservation:** Maintain existing rsIDs when available

**Liftover Process (if hg37 detected):**
**Script:** `./utils/convert_to_hg38.sh`

1. Download UCSC liftover chain file
2. Set reference alleles according to hg37 reference
3. Perform coordinate conversion
4. Archive original files with `_hg37` suffix

#### Step 2: Pre-QC Statistics

**Script:** `Step2_PreQC.sh` | **Report:** `./utils/report_qc_stats.Rmd`

**Sample-level metrics:**

- Sample call rate and heterozygosity distributions
- Sex check comparison (with graceful handling of missing data)
- Histogram visualizations

**Variant-level metrics:**

- Allele frequencies, call rates, HWE p-values
- Monomorphic site counts
- Distribution plots

**Per-chromosome analysis:** Automated splitting and individual chromosome QC

#### Step 3: Basic Quality Control

**Script:** `Step3_BasicQC.sh` | **Utility:** `./utils/filter_heterozygosity.py`

**Filtering steps:**

1. **Heterozygosity outliers:** Remove samples outside [median ± 3×IQR] (configurable)
2. **Sample call rate:** Remove samples <90% (default)
3. **Variant call rate:** Remove variants <90% (default)
4. **Minor allele frequency:** Remove variants <1% (default)
5. **Hardy-Weinberg equilibrium:** Remove variants with p < 1e-50 (default)

**Output:** QC'd files in `./output/<study_name>/InitialQC/PostQC/`
**Reports:** Summary statistics and per-chromosome breakdowns

#### Step 4: Kinship Analysis

**Script:** `Step4_KinshipTest.sh` | **Report:** `./utils/report_kinship.Rmd`

**Implementation:**

1. **KING algorithm** via PLINK2 for pairwise kinship coefficients
2. **Output:** `.kin0` file with kinship coefficients and IBS0 values
3. **Sample removal:** Automatic filtering above kinship threshold (default: 0.354 for MZ twins/duplicates only)
4. **Relationship classification:** MZ twins, 1st/2nd/3rd degree relatives
5. **Visualization:** Kinship coefficient distributions and plots

#### Step 5: SNP Intersection and LD Pruning

**Script:** `Step5_SNPIntersectForPCA.sh`

**Process:**

1. **SNP extraction:** Identify overlapping variants between study and reference
2. **Allele alignment:** Harmonize alleles between datasets
3. **Duplicate removal:** Handle multi-allelic and duplicate variants
4. **LD pruning:** Perform linkage disequilibrium pruning on reference data
5. **Dataset restriction:** Limit both datasets to LD-pruned SNPs
6. **Quality check:** Verify identical .bim files between datasets

**Technical note:** Chunking implementation for large variant sets to manage memory usage

#### Step 6: Principal Component Analysis

**Script:** `Step6_PCA.sh` | **Utility:** `./utils/plot_pca.R` | **Report:** `./utils/report_pca.Rmd`

**Implementation:**

1. **Reference PCA:** Generate principal components using FlashPCA
2. **Projection:** Project study samples onto reference PC space
3. **Sign alignment:** Ensure consistent PC orientations
4. **Visualization:** Multi-panel PC plots with population labels

**Standardized plotting:** Consistent formatting across all PCA visualizations using `./utils/plot_pca.R`

#### Step 7: Continental Ancestry Determination

**Script:** `Step7_AncestryModel.sh` | **Utility:** `./utils/train_pca_model.py` | **Report:** `./utils/report_ancestry_predictions.Rmd`

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

#### Step 8: Ancestry-Specific PCA

**Script:** `Step8_AncestrySpecificPCA.sh`

**Process:**

1. **Ancestry filtering:** Extract samples by predicted ancestry (≥80% confidence)
2. **Projection:** Project ancestry-specific subsets onto reference PC space
3. **Validation plots:** Visual verification of ancestry-specific PC clustering

**Output:** Ancestry-specific PC files for downstream association analyses

#### Step 9: Cleanup and Reporting

**Script:** `CleanUp.sh`

**Final steps:**

1. **File logging:** Document all intermediate and final outputs
2. **Binary cleanup:** Remove temporary executables
3. **Report conversion:** Convert HTML reports to PDF format
4. **Combined reporting:** Generate unified PDF from all analysis steps

> **Styling Note:** All HTML reports use consistent formatting via `./utils/qc_report_style.css`
