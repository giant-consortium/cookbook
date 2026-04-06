---
---

<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./index.html">⬅️ Return to Homepage</a>
  <a href="./pre_phasing_checks.html">Go to Step 2 [Pre-Phasing Checks] ➡️</a>
</div>

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

This repository contains scripts and utilities for running a comprehensive sample variant quality control (QC) pipeline for human genomics datasets, including ancestry prediction and per-chromosome QC reporting. It is primarily designed for use with biobank scale array-sequencing datasets, but provides support for WGS datasets as well.

The containerized implementation ensures reproducible execution across different computing environments. This was designed as part of the Deeper Imputation effort by the GIANT Consortium.

# Features

- **Automated Build Detection** (hg37/hg38) with liftover using progressive MAF filtering strategies
- **Comprehensive QC** filtering and statistics with customizable thresholds
- **Ancestry Prediction** using 1000G + HGDP reference data with Multiple-Ancestry Nearest Control Selection (MANCS) or Random Forest algorithms
- **Principal Component Analysis** for population structure with projection capabilities
- **Kinship Analysis** using KING to identify related samples
- **Interactive Reports** with consistent styling and comprehensive plots
- **Containerized** execution with Docker/Singularity/Apptainer support
- **Multi-format Input Support** (.bed/.bim/.fam, BGEN, .ped/.map, compressed archives)

# Characteristics of Container-Based Solution

## Platform Requirements

- Docker, Singularity or Apptainer
- 8GB+ RAM, 50GB+ storage recommended
- Linux/macOS (Windows via WSL)

## Accepted Input File Formats for Genotype Data

- .bed/.bim/.fam
- .ped/.map
- BGEN
- PGEN

## Generated Output Files

-

# Internal Directory Structure

```bash
sample_variant_qc/
├── scripts/                       # Main pipeline and stepwise shell scripts
│   ├── RunQCPipeline.sh           # Top-level orchestrator (called inside container)
│   ├── Step0_Setup.sh
│   ├── Step1_CheckBuild.sh
│   ├── Step2_PreQC.sh
│   ├── Step3_BasicQC.sh
│   ├── Step4_SNPIntersectAndPrune.sh
│   ├── Step5_KinshipTest.sh
│   ├── Step6_PCA.sh
│   ├── Step7_AncestryModel.sh
│   ├── Step8_AncestrySpecificPCA.sh
│   └── Step9_CleanUp.sh
├── utils/                         # R scripts, Python helpers, plotting, and support utilities
│   ├── align_variants.sh          # Allele harmonization between study and reference
│   ├── check_build.R              # Build detection (hg37/hg38) via variant overlap
│   ├── compute_palindromes_summary.sh  # Palindromic SNP diagnostics
│   ├── convert_to_hg37.sh         # Liftover hg38 → hg37
│   ├── convert_to_hg38.sh         # Liftover hg37 → hg38
│   ├── filter_het_rate.py         # Het rate (IQR-based) outlier detection
│   ├── filter_fscore.py           # F-score (SD-based) outlier detection
│   ├── filter_relateds.py         # Greedy related-sample removal (Python fallback)
│   ├── plot_pca.R                 # Standardized PCA plotting functions
│   ├── qc_report_style.css        # Shared CSS for all HTML reports
│   ├── report_ancestry_predictions.Rmd
│   ├── report_ancestry_specific_pca.Rmd
│   ├── report_kinship.Rmd
│   ├── report_pca.Rmd
│   ├── report_per_chrom_qc_stats.Rmd
│   ├── report_qc_stats.Rmd
│   ├── report_snp_intersect_for_pca.Rmd
│   ├── stack_ancestry_pca.py      # Combine per-ancestry PCA outputs
│   ├── train_pca_model.py         # Ancestry prediction (MANCS / RF)
│   ├── write_manifest.sh          # File provenance tracking helper
│   └── fast_filter_relateds/      # Cython-optimized related-sample filtering
│       ├── cli.py
│       ├── setup.py
│       └── src/fast_filter_relateds/
├── data/                          # Reference/population files (downloaded at first run)
├── output/                        # Output directory for results and reports (created in first run)
├── parameters.txt                 # Configuration file for pipeline variables
├── checksums.sha256               # SHA-256 checksums for downloaded artifacts
├── Dockerfile                     # Docker image definition
└── SAMPLE_VARIANT_QC_RUNNER.sh    # Main host-side execution script
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
- **Minor allele frequency:** 0.1% (0.001)
- **Hardy-Weinberg equilibrium:** p > 1e-6 (single-ancestry) or p > 1e-12 (multi-ancestry)
- **Sample heterozygosity:** F-score within mean ± 4 SD (default), or het rate within median ± 3 IQR
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

   # With Apptainer (default if no runtime specified)
   ./SAMPLE_VARIANT_QC_RUNNER.sh --apptainer

   # To force data download:
   ./SAMPLE_VARIANT_QC_RUNNER.sh --docker --force_data_download

   # To get the most recent containers:
   ./SAMPLE_VARIANT_QC_RUNNER.sh --docker --get_update
   ```

4. **Outputs** will be saved in a sub-folder named `study_name` at the path specified by `path_to_output` in `parameters.txt`.

# Pipeline Overview

The pipeline performs the following steps:

| Step | Script | Description |
|------|--------|-------------|
| 0 | `Step0_Setup.sh` | Setup & format conversion to PLINK |
| 1 | `Step1_CheckBuild.sh` | Build detection (hg37/hg38) and liftover |
| 2 | `Step2_PreQC.sh` | Pre-QC baseline statistics |
| 3 | `Step3_BasicQC.sh` | Sample & variant QC filtering |
| 4 | `Step4_SNPIntersectAndPrune.sh` | SNP intersection with reference & LD pruning |
| 5 | `Step5_KinshipTest.sh` | Kinship analysis (KING) & related-sample removal |
| 6 | `Step6_PCA.sh` | Principal component analysis & projection |
| 7 | `Step7_AncestryModel.sh` | Continental ancestry prediction |
| 8 | `Step8_AncestrySpecificPCA.sh` | Ancestry-specific PCA |
| 9 | `Step9_CleanUp.sh` | Report consolidation & cleanup |

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

This file configures paths, performs data downloads, and downloads prebuilt container images (docker .tar or singularity .sif) from GCS and loads/tags them; use `--get_update` to request an updated tar (this will re-download and replace existing container files).

The runner reads configuration from `parameters.txt`, and then executes the pre-built image with passed parameters to execute the complete workflow. The `parameters.txt` file contains the settings referenced by every step (study_name, path_to_data, path_to_output, thresholds, container flags).

### Runner usage

Supported flags:

| Flag | Description |
|------|-------------|
| `--docker` | Run pipeline via Docker (downloads/loads docker .tar) |
| `--singularity` | Run pipeline via Singularity |
| `--apptainer` | Run pipeline via Apptainer (default if none specified) |
| `--force_data_download` | Force download of reference data |
| `--get_update` | Re-download container artifacts (refresh .tar / .sif) |
| `--interactive` | Run container interactively (shell) |
| `--no_ld_king` | Use container image variant without LD-based KING |

### Checksums / integrity

The runner requires a checksums file (`./checksums.sha256`) to validate downloaded container artifacts. Ensure `checksums.sha256` is present alongside the runner or in the same directory where downloads occur. This checksums file is available on the GitHub repository.

### Container behavior

Default runtime: Apptainer (if none specified). Behavior:

- **Docker:** downloads `giant_sample_variant_qc_latest.tar` from the configured GCS location and runs `docker load` → `docker tag` → `docker run`.
- **Singularity/Apptainer:** downloads `giant_sample_variant_qc_latest.sif` from GCS and runs the SIF.
- `--get_update` forces re-download and replacement of existing container files.

## RunQCPipeline.sh — Pipeline Orchestrator

### Script: `scripts/RunQCPipeline.sh`

### Purpose

Top-level orchestrator executed **inside** the container. It sources `parameters.txt`, derives all path variables, exports environment variables consumed by downstream steps, and invokes each step script in sequence.

### Behavior

1. **Parameter loading:** Sources `parameters.txt` (passed via `--env-file` for Docker or `--env` for Singularity/Apptainer). Resolves container-internal mount points (`/home/input_data`, `/home/output`, etc.) from the host paths mapped by the runner.
2. **Path derivation:** Computes all output sub-directory paths from `path_to_output` and `study_name`:
   - `stats_out_path` → `PreQCStats/`
   - `qc_out_path` → `PostBasicQC/`
   - `pca_out_path` → `PCA/`
   - `kinship_out_path` → `Kinship/`
   - `ancestry_out_path` → `Ancestry/`
   - `logs_out_path` → `Logs/`
   - `temp_output_path` → temporary working area
   - Per-chromosome directories (`PreQCStats_PerChromosome/`, `PostQC_PerChromosome/`, `PostQCStats_PerChromosome/`) when `data_type=wgs`.
3. **Environment export:** Exports all QC threshold variables (`minor_allele_freq_cutoff`, `variant_missingness_cutoff`, `sample_missingness_cutoff`, `variant_hwe_thresh`, `het_filter_method`, `num_f_sd_shifts`, `num_iqr_shifts`, `minor_allele_count_cutoff`, `kinship_threshold`, `ancestry_algorithm`, `ancestry_confidence`, etc.) so child scripts and R/Python processes inherit them.
4. **HWE threshold resolution:** If `variant_hwe_thresh` is not explicitly set in `parameters.txt`, derives a default based on `study_anc_expectation`:
   - `HOM` (homogeneous / single ancestry) → `1e-6`
   - `HET` (heterogeneous / mixed ancestry) → `1e-12`
   - Explicit user value in `variant_hwe_thresh` always takes priority.
5. **Sequential step execution:** Calls each step script in order (Step 0 → Step 1 → … → Step 9), checking exit status after each. Aborts on non-zero exit with a timestamped error message and the failing step name.
6. **Logging:** Redirects combined stdout/stderr to a timestamped master log file in `logs_out_path` while also printing to the console via `tee`.

### Dependencies

- All step scripts in `scripts/`
- `parameters.txt` sourced into the environment
- Container runtime (provides all binary dependencies)

### Safety / Notes

- The orchestrator is **not** intended to be run on the host directly; it assumes container-internal paths. Use `SAMPLE_VARIANT_QC_RUNNER.sh` to launch it.
- Update paths to match the host system if running this script outside the container.
- If a step is skipped (e.g., liftover not needed), the orchestrator still invokes the step script, which performs its own no-op detection and exits cleanly.

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

#### Utility: `utils/check_build.R`, `utils/convert_to_hg38.sh`

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

#### Script: `scripts/Step2_PreQC.sh` | Report: `utils/report_qc_stats.Rmd`

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

#### Safety / Notes

- No sample/variant removals are performed in this step — it is used to incorporate pre-QC information in the reports

### Step 3: Basic Quality Control

#### Script: `scripts/Step3_BasicQC.sh` | Utilities: `utils/filter_het_rate.py`, `utils/filter_fscore.py`

#### Purpose

Perform primary sample- and variant-level filtering to produce a cleaned dataset for downstream analyses (kinship, PCA, ancestry prediction).

#### Default Thresholds

| Filter | Default | Description |
|---|---|---|
| Bi-allelic only | — | Multi-allelic variants are removed before any other filtering |
| Sample missingness | ≥ 10% missing | Samples with call rate < 90% are removed (`--mind 0.1`) |
| Variant missingness | ≥ 10% missing | Variants with call rate < 90% are removed (`--geno 0.1`) |
| Minor allele frequency | < 0.001 | Variants with MAF < 0.1% are removed (`--maf 0.001`) |
| Minor allele count | disabled | Optional; when set > 0, variants below the MAC are removed (`--mac`) |
| Hardy-Weinberg equilibrium | p < 1e-6 (single-ancestry) or p < 1e-12 (multi-ancestry) | Derived from `study_anc_expectation`; an explicit value in `parameters.txt` always overrides |
| Heterozygosity outliers (F-score) | mean ± 4 SD | Default method. Samples with inbreeding coefficient outside this range are removed |
| Heterozygosity outliers (het rate) | median ± 3 IQR | Alternative method. Samples with heterozygosity rate outside this range are removed |

#### Heterozygosity Outlier Detection

Two methods are available for identifying samples with aberrant heterozygosity. **Both** remove-lists are always generated (for reporting), but only one is applied to the data:

- **F-score method** (default, `het_filter_method=f_score`): Uses the PLINK inbreeding coefficient (F). Flags samples where F falls outside mean ± 4 SD. This is a z-score-style filter on the F statistic from the `.ibc` or `.het` output.
- **Het rate method** (`het_filter_method=het_rate`): Computes per-sample heterozygosity rate as `(OBS_CT − O(HOM)) / OBS_CT` from the PLINK `.het` output. Flags samples where het rate falls outside median ± 3 IQR. This is an IQR-based robust outlier filter.

The choice is controlled by the `het_filter_method` parameter. The non-selected method's remove-list and filtered dataset are still produced and appear in the QC report for comparison, but are not carried forward.

#### Inputs

- PLINK files (prefix) from Step 0/1 (pointed to by `dataset_path`)
- Pre-QC statistics from Step 2 (in `stats_out_path`)
- QC thresholds from environment / `parameters.txt`

#### Outputs

- Filtered PLINK datasets: `_biallelic`, `_HetRateFiltered`, `_FscoreFiltered`, `_SampleFiltered`, `_VariantFiltered` (final)
- Remove-lists: `_filtered_samples_het_rate.txt`, `_filtered_samples_fscore.txt`
- Post-QC summary statistics (PLINK missing/hardy/freq/het outputs)
- Per-chromosome post-QC summaries (WGS mode: all chromosomes; array mode: chrX/chrY only when present)
- HTML QC report (`report_qc_stats.Rmd`) and per-chromosome report (`report_per_chrom_qc_stats.Rmd`, WGS only)

#### Dependencies

- `plink2`, Python 3.8+, R ≥ 4.0 with rmarkdown/knitr
- `utils/filter_het_rate.py`, `utils/filter_fscore.py`, `utils/write_manifest.sh`

#### Behavior

1. **Remove multi-allelic variants** (`--max-alleles 2`) → `_biallelic` dataset.
2. **Detect heterozygosity outliers** using both methods (F-score and het rate). Each produces a remove-list and a corresponding filtered dataset. The method selected by `het_filter_method` determines which filtered dataset feeds into the next step.
3. **Remove low call-rate samples** (`--mind`) → `_SampleFiltered` dataset.
4. **Remove low-quality variants** (`--geno`, `--maf`, `--mac`, `--hwe`) in a single PLINK2 pass → `_VariantFiltered` dataset (the final QC'd output).
5. **Compute post-QC statistics** on the final dataset and optionally split by chromosome.
6. **Render QC reports** (genome-wide, and per-chromosome for WGS).

#### Safety / Notes

- A `check_remove_list` helper validates that remove-lists do not remove **all** samples, aborting with a clear error if they would produce an empty dataset.
- If a remove-list file is empty or missing, the corresponding `--remove` flag is omitted (no-op).
- All intermediate PLINK datasets are recorded via `write_manifest` for provenance tracking.

### Step 4: SNP Intersection and LD Pruning

#### Script: `scripts/Step4_SNPIntersectAndPrune.sh` | Utilities: `utils/align_variants.sh`, `utils/compute_palindromes_summary.sh` | Report: `utils/report_snp_intersect_for_pca.Rmd`

#### Purpose

Identify overlapping high-quality variants between the study and 1KG+HGDP reference datasets, harmonize alleles, handle palindromic SNPs, and perform LD pruning to produce a clean, matched SNP set for PCA.

#### Inputs

- QC'd PLINK files from Step 3 (`_VariantFiltered` prefix in `qc_out_path`)
- Reference PLINK files in `path_to_ref_data` (1KG+HGDP hg38)
- LD pruning parameters from environment (window size, step, r² threshold)

#### Outputs

- Overlapping SNP list: `<study_name>_intersected_snps.txt`
- Palindromic SNP summary (from `utils/compute_palindromes_summary.sh`)
- Allele-harmonized study and reference datasets restricted to overlapping SNPs
- LD-pruned SNP list: `<study_name>_ldpruned_snps.prune.in`
- Final study and reference datasets restricted to LD-pruned SNPs with verified-identical `.bim` files
- HTML SNP intersection report (`report_snp_intersect_for_pca.Rmd`)
- Manifest entries for all produced files

#### Dependencies

- `plink2` (SNP extraction, allele flipping, LD pruning)
- `utils/align_variants.sh` (allele harmonization logic)
- `utils/compute_palindromes_summary.sh` (palindromic SNP diagnostics)
- `awk`, `sort`, `comm` (POSIX set intersection)
- `R` with rmarkdown/knitr (for report rendering)
- `utils/write_manifest.sh`

#### Behavior

1. **Extract variant IDs** from both study and reference `.bim` files (using `chr:pos:ref:alt` format established in Step 0).
2. **Compute SNP intersection** using sorted set operations (`comm -12`) to identify variants present in both datasets.
3. **Handle allele strand issues** via `utils/align_variants.sh`: for each overlapping variant, check whether alleles match directly or require complementing (A↔T, C↔G flips). Remove ambiguous A/T and C/G palindromic SNPs to avoid strand ambiguity. Palindromic SNP counts and diagnostics are reported via `utils/compute_palindromes_summary.sh`.
4. **Remove duplicate/multi-allelic variant IDs** that may arise from different allele configurations at the same position.
5. **Restrict both datasets** to the harmonized overlapping SNP set using `plink2 --extract`.
6. **LD pruning** on the reference dataset using PLINK2 `--indep-pairwise` (default: window 1000 kb, step 50, r² 0.2). This produces the `.prune.in` list of independent SNPs.
7. **Apply LD-pruned SNP list** to both datasets so they contain identical variant sets.
8. **Verification:** Compare the `.bim` files of the final study and reference datasets to confirm they are identical in variant order and allele coding. Abort with an error if mismatches are detected.
9. **Render SNP intersection report** (`utils/report_snp_intersect_for_pca.Rmd`) summarizing overlap statistics, palindromic SNP handling, and the final pruned variant count.

#### Safety / Notes

- The final `.bim` identity check is a hard gate — PCA results would be meaningless if the datasets contain different variants.
- Palindromic SNP removal is conservative; the summary report documents how many were excluded and why.
- All intermediate files are logged to the manifest for troubleshooting.

### Step 5: Kinship Analysis

#### Script: `scripts/Step5_KinshipTest.sh` | Utilities: `utils/filter_relateds.py`, `utils/fast_filter_relateds/` | Report: `utils/report_kinship.Rmd`

#### Purpose

Identify related and duplicate samples using pairwise kinship estimation (KING algorithm) and remove samples above a configurable kinship threshold using an optimized greedy algorithm.

#### Default Threshold

| Parameter | Default | Description |
|---|---|---|
| Kinship threshold | 0.354 | Removes only MZ twins / duplicates. Lower values (e.g., 0.0884) remove up to 2nd-degree relatives |
| `KING_AUTOSOMES_ONLY` | `True` | Restrict kinship computation to autosomal chromosomes |

#### Inputs

- QC'd PLINK files from Step 3 (`_VariantFiltered` prefix in `qc_out_path`)
- Sample missingness file (`.smiss`) for tie-breaking during greedy removal
- Kinship threshold from environment: `kinship_threshold` (default: `0.354`)

#### Outputs

- KING kinship table: `<study_name>.kin0` (pairwise kinship coefficients φ, IBS0, HetHet)
- Related-pairs summary with relationship degree classifications
- Remove-list: `<study_name>_kinship_filtered_samples.txt`
- Post-kinship PLINK dataset: `<study_name>_KinshipFiltered`
- HTML kinship report with distribution plots and relationship tables
- Manifest entries for all produced files

#### Dependencies

- `plink2` with `--make-king-table` support (KING-robust algorithm)
- Python 3.8+ (`utils/filter_relateds.py` — pure-Python fallback)
- `utils/fast_filter_relateds/` — Cython-optimized greedy removal (preferred when compiled; falls back to `filter_relateds.py` automatically)
- `R` with data.table, ggplot2, rmarkdown, knitr, kableExtra (for report rendering)

#### Behavior

1. **Run KING kinship estimation** using PLINK2 `--make-king-table` on the QC'd dataset. When `KING_AUTOSOMES_ONLY` is set, adds `--autosome` to restrict to autosomes.
2. **Classify relationship degrees** from the `.kin0` output:
   - φ ≥ 0.354 → MZ twins / duplicates
   - 0.177 ≤ φ < 0.354 → 1st-degree (parent-offspring, full siblings)
   - 0.0884 ≤ φ < 0.177 → 2nd-degree (half-siblings, avuncular)
   - 0.0442 ≤ φ < 0.0884 → 3rd-degree (first cousins)
3. **Generate a remove-list** using a greedy algorithm that retains the sample with the highest call rate (lowest missingness from `.smiss`) in each related cluster. The pipeline prefers the Cython-optimized implementation (`fast_filter_relateds/`) for large biobank-scale datasets but falls back to `utils/filter_relateds.py` if the compiled extension is unavailable.
4. **Create the post-kinship dataset** by applying `--remove`. If the remove-list is empty, the dataset passes through unchanged.
5. **Render the kinship report** (`utils/report_kinship.Rmd`) with:
   - Histogram of kinship coefficient distribution
   - IBS0 vs kinship scatterplot with degree-boundary lines
   - Table of related pairs grouped by degree
   - Summary counts of removed samples

#### Safety / Notes

- The default threshold (0.354) removes only MZ twins/duplicates. Lower thresholds can be set via `kinship_threshold` in `parameters.txt`.
- The step is robust to datasets with no related pairs — it produces an empty remove-list and passes the dataset through unchanged.

### Step 6: Principal Component Analysis

#### Script: `scripts/Step6_PCA.sh` | Utility: `utils/plot_pca.R` | Report: `utils/report_pca.Rmd`

#### Purpose

Generate principal components capturing population structure by computing PCs on the reference panel and projecting study samples into the same PC space.

#### Inputs

- LD-pruned, SNP-intersected study and reference PLINK files from Step 4
- Post-kinship sample list from Step 5 (to exclude related samples from projection)
- Population labels for reference samples (in `path_to_pop_files`)
- Number of PCs to compute (default: 20, configurable via `num_pcs`)

#### Outputs

- Reference PCs: `<reference_name>_pcs.txt` (eigenvalues and eigenvectors)
- Projected study PCs: `<study_name>_projected_pcs.txt`
- Combined PC file (reference + study): `<study_name>_combined_pcs.txt`
- Eigenvalues: `<reference_name>_eigenvalues.txt`
- PCA scree plot and multi-panel PC pair plots (PDF/PNG)
- HTML PCA report
- Manifest entries for all produced files

#### Dependencies

- `flashpca` (for PCA computation and projection)
- `plink2` (for data subsetting if needed)
- `R` with data.table, ggplot2, rmarkdown, knitr (for plotting and report rendering)
- `utils/plot_pca.R` (standardized PCA plotting functions)

#### Behavior

1. **Compute reference PCA** using FlashPCA on the LD-pruned reference dataset. Extracts the top `num_pcs` principal components (default 20) along with eigenvalues and SNP loadings.
2. **Project study samples** onto the reference PC space using FlashPCA's `--project` mode with the SNP loadings from step 1. Samples removed by kinship filtering in Step 5 are excluded from projection.
3. **Sign alignment:** PC sign is arbitrary (eigenvectors can be negated without changing explained variance). The script checks whether the median PC values for a known reference population (e.g., EUR) have the expected sign and flips PCs where necessary to ensure consistent orientation across runs.
4. **Merge PC files:** Combine reference and projected study PCs into a single file with a `SOURCE` column (`REF` or `STUDY`) for downstream plotting and ancestry prediction.
5. **Generate plots** using `utils/plot_pca.R`:
   - Scree plot of eigenvalues (variance explained per PC)
   - Multi-panel scatterplots of PC pairs (PC1 vs PC2, PC1 vs PC3, PC2 vs PC3, etc.) colored by reference population label, with study samples overlaid
6. **Render PCA report** (`utils/report_pca.Rmd`).

#### Safety / Notes

- FlashPCA requires the study and reference datasets to have **identical** variant sets (enforced by Step 4's `.bim` identity check).
- If FlashPCA is unavailable, the script falls back to PLINK2's `--pca` with `--pca-loadings` for computation and a manual projection step.
- Eigenvalue magnitudes are logged for diagnostic purposes; very small trailing eigenvalues may indicate insufficient variant overlap.

### Step 7: Continental Ancestry Determination

#### Script: `scripts/Step7_AncestryModel.sh` | Utility: `utils/train_pca_model.py` | Report: `utils/report_ancestry_predictions.Rmd`

#### Purpose

Assign continental ancestry labels to study samples using supervised classification trained on the 1KG+HGDP reference panel PCs.

#### Default Parameters

| Parameter | Default | Description |
|---|---|---|
| Algorithm | MANCS | Multi-Ancestry Nearest Control Selection (distance-based) |
| Confidence threshold | 0.80 | Min probability to assign ancestry; falls back to 0.75 if no samples qualify |
| PCs used | 10 | Number of PCs as features for classification |
| Ancestry groups | AFR, AMR, EAS, EUR, SAS | Continental labels (NFE + FIN merged into EUR) |

#### Inputs

- Combined reference + study PCs from Step 6 (`_combined_pcs.txt`)
- Reference population labels (in `path_to_pop_files`): FID/IID to continental ancestry mapping
- Algorithm choice, confidence threshold, and PC count from `parameters.txt`

#### Outputs

- Per-sample ancestry predictions with probabilities: `<study_name>_ancestry_predictions.txt`
- Ancestry assignments (samples meeting confidence threshold): `<study_name>_ancestry_assignments.txt`
- Per-ancestry sample lists: `<study_name>_<ANC>_samples.txt` (one file per predicted ancestry group)
- Model diagnostics: cross-validation accuracy, confusion matrix (logged)
- HTML ancestry report
- Manifest entries for all produced files

#### Dependencies

- Python 3.8+ with pandas, numpy, scikit-learn, matplotlib
- `utils/train_pca_model.py` (model training and prediction logic)
- `R` with data.table, ggplot2, rmarkdown, knitr, kableExtra (for report rendering)

#### Behavior

1. **Prepare training data:** Load reference PCs and population labels. Exclude samples labeled `oth` (other/unassigned). Combine NFE (Non-Finnish European) and FIN (Finnish) labels into a single `EUR` group.
2. **Train the classification model:**
   - **MANCS** (default): Assigns ancestry by computing the Mahalanobis distance from each study sample to each reference population centroid in PC space. Posterior probabilities are derived from the inverse distances.
   - **Random Forest** (`ancestry_algorithm=RF`): Trains a scikit-learn `RandomForestClassifier` on reference PCs. Supports optional hyperparameter tuning via grid search.
3. **Cross-validation:** A k-fold cross-validation (default k=5) on the reference panel to estimate accuracy. Results are logged (overall accuracy and per-ancestry precision/recall).
4. **Predict study samples:** Apply the trained model to study sample PCs. Each sample receives a probability vector across all ancestry groups.
5. **Assign ancestry labels:** Samples with max probability ≥ 0.80 are assigned that ancestry. If no samples meet 80%, the threshold relaxes to 75%. Remaining samples are labeled `UNASSIGNED`.
6. **Write per-ancestry sample lists** (FID/IID files) for use in Step 8.
7. **Render ancestry report** (`utils/report_ancestry_predictions.Rmd`).

#### Safety / Notes

- The MANCS algorithm is preferred for its robustness to imbalanced reference panel sizes across ancestry groups.
- If the reference panel has <10 samples for any ancestry group after exclusions, a warning is logged and that group may have unreliable predictions.
- Using too many PCs (>15) may introduce noise from uninformative components.

### Step 8: Ancestry-Specific PCA

#### Script: `scripts/Step8_AncestrySpecificPCA.sh` | Utilities: `utils/plot_pca.R`, `utils/stack_ancestry_pca.py` | Report: `utils/report_ancestry_specific_pca.Rmd`

#### Purpose

Generate population-specific principal components by projecting ancestry-stratified study subsets onto within-ancestry reference PC spaces. These PCs capture fine-scale population structure within continental groups and are suitable as covariates in downstream association analyses.

#### Inputs

- QC'd PLINK files from Step 3 (`_VariantFiltered` prefix)
- Per-ancestry sample lists from Step 7 (`_<ANC>_samples.txt`)
- Reference PLINK files in `path_to_ref_data`
- Reference per-ancestry sample lists in `path_to_pop_files`
- Number of PCs: `num_pcs` (default: 20)

#### Outputs

- Per-ancestry reference PCs: `<reference_name>_<ANC>_pcs.txt`
- Per-ancestry projected study PCs: `<study_name>_<ANC>_projected_pcs.txt`
- Per-ancestry combined PCs: `<study_name>_<ANC>_combined_pcs.txt`
- Stacked ancestry-specific PCA file (via `utils/stack_ancestry_pca.py`): all per-ancestry PCs combined into a single table
- Per-ancestry PCA plots (PC pair scatterplots)
- HTML ancestry-specific PCA report (`report_ancestry_specific_pca.Rmd`)
- Manifest entries for all produced files

#### Dependencies

- `flashpca` (for within-ancestry PCA and projection)
- `plink2` (for subsetting by sample list and SNP intersection)
- Python 3.8+ (`utils/stack_ancestry_pca.py` for combining per-ancestry outputs)
- `R` with data.table, ggplot2 (for plotting and report rendering)
- `utils/plot_pca.R` (shared PCA plotting functions)

#### Behavior

1. **Iterate over each predicted ancestry group** (AFR, AMR, EAS, EUR, SAS) that contains at least one study sample meeting the confidence threshold.
2. **Subset reference to within-ancestry samples** using the reference population lists. Subset the study to predicted-ancestry samples using the lists from Step 7.
3. **SNP intersection:** Re-compute the overlapping variant set between the ancestry-specific study and reference subsets (variant sets may differ from the global intersection in Step 4 due to MAF changes in smaller subsets).
4. **LD pruning:** Perform within-ancestry LD pruning on the reference subset.
5. **Compute within-ancestry reference PCA** using FlashPCA on the LD-pruned within-ancestry reference subset.
6. **Project ancestry-specific study samples** onto the within-ancestry PC space.
7. **Sign alignment** (same logic as Step 6) to ensure consistent PC orientations.
8. **Stack per-ancestry outputs** using `utils/stack_ancestry_pca.py` into a single combined file for convenient downstream consumption.
9. **Generate per-ancestry PCA plots** and **render report** (`utils/report_ancestry_specific_pca.Rmd`).

#### Safety / Notes

- Ancestry groups with very few study samples (<5) may produce unstable PCs; a warning is logged and plots may be sparse.
- If an ancestry group has no study samples meeting the confidence threshold, that group is skipped entirely.
- The within-ancestry PCs capture **fine-scale** structure (e.g., sub-continental clustering within EUR or AFR) that the global PCA in Step 6 may not resolve.
- These per-ancestry PCs are the recommended covariates for ancestry-stratified genetic association analyses.

### Step 9: Cleanup and Reporting

#### Script: `scripts/Step9_CleanUp.sh`

#### Purpose

Finalize the pipeline run by consolidating outputs, converting reports, removing temporary files, and producing a unified summary document.

#### Inputs

- All output directories populated by Steps 0–8
- HTML reports from Steps 3, 4, 5, 6, 7, 8
- Manifest files (`generated_files.txt`) from each step

#### Outputs

- Combined PDF report: `<study_name>_QC_Report.pdf` (all HTML reports merged)
- Final cleaned output directory with temporary/intermediate files removed
- Consolidated manifest: `<study_name>_all_generated_files.txt`
- Pipeline completion log entry

#### Dependencies

- `wkhtmltopdf` (for HTML → PDF conversion)
- `pandoc` (fallback for HTML → PDF if wkhtmltopdf unavailable)
- POSIX tools: bash, cat, rm, mv, find

#### Behavior

1. **Consolidate manifests:** Concatenate all per-step manifest entries into a single master manifest.
2. **Convert HTML reports to PDF:** Iterate over all `.html` reports and convert each to PDF using `wkhtmltopdf` (preferred) or `pandoc`. Original HTML files are retained.
3. **Merge PDFs** into a single unified document (`<study_name>_QC_Report.pdf`) in step order:
   - Basic QC report
   - SNP intersection report
   - Kinship report
   - PCA report
   - Ancestry predictions report
   - Ancestry-specific PCA report
   - Per-chromosome QC report (if WGS)
4. **Remove temporary files:** Delete intermediate working files in `temp_output_path`, temporary PLINK datasets that are no longer needed, and copied utility files (`.Rmd`, `.css`) from stats directories.
5. **Preserve essential outputs:** Final QC'd dataset, all remove-lists and sample lists, per-ancestry PCs, all reports (HTML and PDF), log files, and master manifest.
6. **Log completion:** Write a final timestamped entry to the master log.

#### Safety / Notes

- PDF conversion failures are non-fatal — the pipeline logs a warning and continues. HTML reports remain available regardless.
- The cleanup step does **not** delete the `PostBasicQC/` intermediate datasets by default. Set `cleanup_intermediates=True` in `parameters.txt` to enable aggressive cleanup.
- The master manifest enables reproducibility audits: every file produced by the pipeline is traceable to the step and command that created it.

---

## Utility Scripts

### `utils/write_manifest.sh`

Shared helper sourced by all step scripts. Provides the `write_manifest()` function that appends file-prefix entries to a per-directory `generated_files.txt` manifest. Accepts an optional `--optional` flag that suppresses errors when the target file does not exist.

### `utils/filter_het_rate.py`

Computes per-sample heterozygosity rate from PLINK `.het` output as `(OBS_CT − O(HOM)) / OBS_CT`. Flags outlier samples outside `median ± num_iqr_shifts × IQR`. Writes a two-column FID/IID remove-list. Robust to header variants (`#FID` vs `FID`).

### `utils/filter_fscore.py`

Reads the inbreeding coefficient (F) from PLINK `.ibc` or `.het` output. Flags outlier samples outside `mean ± num_f_sd_shifts × SD`. Writes a two-column FID/IID remove-list.

### `utils/filter_relateds.py`

Pure-Python greedy related-sample removal. Reads KING `.kin0` and sample missingness (`.smiss`), iteratively removes the sample with the most relatives (breaking ties by call rate) until no pair exceeds the kinship threshold. Used as fallback when the Cython-optimized version is unavailable.

### `utils/fast_filter_relateds/`

Cython-optimized implementation of the greedy related-sample removal algorithm. Provides the same logic as `filter_relateds.py` but with significantly improved performance for large datasets (biobank-scale). Includes `cli.py` (command-line entry point), `_fast_filter.pyx` (Cython core), and `_fallback.py` (pure-Python fallback). Ships with `setup.py` and `pyproject.toml` for building the extension.

### `utils/align_variants.sh`

Allele harmonization between study and reference datasets. Checks for direct allele matches, strand flips (complement), and ref/alt swaps. Produces a harmonized variant list and logs all allele reconciliation decisions.

### `utils/compute_palindromes_summary.sh`

Identifies and summarizes palindromic (ambiguous strand) SNPs (A/T and C/G pairs) in the overlapping variant set. Reports counts by MAF bin and flags variants that cannot be reliably harmonized.

### `utils/train_pca_model.py`

Implements both MANCS and Random Forest ancestry prediction. Accepts combined PCs, reference labels, algorithm choice, and confidence threshold. Outputs per-sample probabilities and assignments with cross-validation diagnostics.

### `utils/plot_pca.R`

Shared R plotting functions for standardized PCA visualizations. Provides consistent color palettes (one color per ancestry), axis labels, point sizes, and legend formatting. Used by Steps 6 and 8.

### `utils/stack_ancestry_pca.py`

Combines per-ancestry PCA output files into a single stacked table. Adds an `ANCESTRY` column to each per-ancestry PC file and concatenates them for convenient downstream use.

### `utils/check_build.R`

Build detection via variant overlap comparison against hg37 and hg38 reference panels. Supports progressive MAF filtering (no filter → MAF>1% → MAF>5%) to improve overlap estimates when rare variants dominate.

### `utils/convert_to_hg38.sh`

Liftover from hg37 to hg38 using the UCSC `liftOver` tool and `hg19ToHg38.over.chain.gz` chain file. Archives original files with `_hg37` suffix.

### `utils/convert_to_hg37.sh`

Liftover from hg38 to hg37 using the UCSC `liftOver` tool and `hg38ToHg19.over.chain.gz` chain file. Used when downstream tools require hg37 coordinates.

### `utils/qc_report_style.css`

Shared CSS stylesheet applied to all HTML reports for consistent visual formatting.

### RMarkdown Report Templates

| Template | Used by | Description |
|----------|---------|-------------|
| `report_qc_stats.Rmd` | Step 3 | Genome-wide QC statistics (pre/post filtering) |
| `report_per_chrom_qc_stats.Rmd` | Step 3 (WGS) | Per-chromosome QC statistics |
| `report_snp_intersect_for_pca.Rmd` | Step 4 | SNP intersection and LD pruning summary |
| `report_kinship.Rmd` | Step 5 | Kinship analysis and related-pair summary |
| `report_pca.Rmd` | Step 6 | PCA scree plots and PC pair scatterplots |
| `report_ancestry_predictions.Rmd` | Step 7 | Ancestry prediction confidence and assignments |
| `report_ancestry_specific_pca.Rmd` | Step 8 | Within-ancestry PCA plots and summaries |

---

## Container Image Variants

| Variant | Image name suffix | Description |
|---|---|---|
| Default | `giant_sample_variant_qc_latest` | Full pipeline with all dependencies |
| No-LD KING | `giant_sample_variant_qc_noldking_latest` | Omits LD-based KING (uses standard KING only) |

Select via `--no_ld_king` flag to `SAMPLE_VARIANT_QC_RUNNER.sh`.

---

## Configuration Reference (`parameters.txt`)

All pipeline behavior is controlled via `parameters.txt`. Key parameters:

| Parameter | Description | Default |
|---|---|---|
| `study_name` | Base name of input PLINK files (no extension) | *required* |
| `path_to_data` | Path to input genotype data | *required* |
| `path_to_output` | Path for all pipeline outputs | *required* |
| `path_to_ref_data` | Path to 1KG+HGDP reference data | *required* |
| `path_to_build_check` | Path to build-check reference data | *required* |
| `path_to_pop_files` | Path to population label files | *required* |
| `data_type` | `array` or `wgs` | `array` |
| `sample_missingness_cutoff` | Max sample missingness rate | `0.1` |
| `variant_missingness_cutoff` | Max variant missingness rate | `0.1` |
| `minor_allele_freq_cutoff` | Min MAF for variant retention | `0.001` |
| `minor_allele_count_cutoff` | Min MAC for variant retention (0 = disabled) | `0` |
| `variant_hwe_thresh` | Min HWE p-value for variant retention | Derived from `study_anc_expectation` |
| `study_anc_expectation` | `HOM` (single ancestry) or `HET` (mixed) | `HOM` |
| `het_filter_method` | `f_score` or `het_rate` | `f_score` |
| `num_f_sd_shifts` | SD multiplier for F-score outlier detection | `4` |
| `num_iqr_shifts` | IQR multiplier for het rate outlier detection | `3` |
| `kinship_threshold` | Max kinship coefficient before removal | `0.354` |
| `KING_AUTOSOMES_ONLY` | Restrict KING to autosomes | `True` |
| `ancestry_algorithm` | `MANCS` or `RF` | `MANCS` |
| `ancestry_confidence` | Min probability for ancestry assignment | `0.8` |
| `ancestry_num_pcs` | Number of PCs used for ancestry prediction | `10` |
| `num_pcs` | Number of PCs computed in PCA | `20` |
| `bgen_ref_flag` | BGEN reference allele handling | (empty) |
| `cleanup_intermediates` | Remove intermediate PLINK files in cleanup | `False` |
