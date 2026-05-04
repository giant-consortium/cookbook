---
layout: default
---

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

---

<a id="input-output"></a>

## Input / Output

### Accepted inputs

PLINK (.bed/.bim/.fam), BGEN, PGEN, .ped/.map, or compressed archives (.tar.gz).

### Key outputs

| Output | Path | Purpose |
|--------|------|---------|
| **QC report (final deliverable)** | `output/<study_name>_Outputs/Reports/<study_name>_Combined_Report.pdf` | Upload this to GIANT |
| **QC'd genotypes (input for Step 2)** | `output/<study_name>_Outputs/PostBasicQC/` | Required input for [Pre-Phasing Checks](./pre_phasing_checks.html) |

### Full output tree

```
output/<study_name>_Outputs/
├── Ancestry/                  # Ancestry predictions and population labels
├── AncestrySpecificPCA/       # Population-specific principal components
├── Kinship/                   # Relatedness analysis results
├── Logs/                      # Pipeline execution logs
├── PCA/                       # Principal component analysis outputs
├── PostBasicQC/               # OUTPUT QC'd genotypes → feed into Step 2
├── PostQC_PerChromosome/      # QC'd data split by chromosome
├── PostQCStats_PerChromosome/ # Per-chromosome QC statistics
├── PostSampleVariantQC/       # Final QC'd genotype files
├── PreQCStats/                # Baseline statistics (pre-QC)
├── PreQCStats_PerChromosome/  # Per-chromosome baseline statistics
└── Reports/                   # OUTPUT Combined PDF report to upload
```

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

## Pipeline Overview

1. **Setup & Format Conversion** — convert input to PLINK format
2. **Build Detection** — determine hg37/hg38; liftover if needed
3. **Pre-QC Statistics** — generate baseline quality metrics
4. **Basic QC** — filter samples/variants (call rate, MAF, MAC, HWE, heterozygosity)
5. **SNP Intersection & LD Pruning** — align with reference data
6. **Relatedness Estimation** — identify related samples (KING)
7. **PCA Generation** — calculate population-structure covariates
8. **Ancestry Prediction** — assign continental ancestry labels (MANCS / RF)
9. **Ancestry-Specific PCA** — per-ancestry projections
10. **Reporting** — produce combined HTML/PDF report

![Sample Variant QC Pipeline Flowchart](./diagrams/overview/Overview_SampleVariantQC_Pipeline.png)

---

<a id="repository-structure"></a>

## Repository Structure

```
sample_variant_qc/
├── scripts/                     # Pipeline step scripts
├── utils/                       # R scripts, plotting, support utilities
├── data/                        # Reference & population label data (auto-downloaded)
├── output/                      # Pipeline outputs
├── parameters.txt               # ⬅ Main configuration file
├── Dockerfile                   # Docker image definition
└── SAMPLE_VARIANT_QC_RUNNER.sh  # Entry-point script
```

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
