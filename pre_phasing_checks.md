---
---
<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./index.html">⬅️ Return to Homepage</a>
  <a href="phenotyping.html">Go to Step 3 [Phenotyping]➡️</a>
</div>

# Pre-phasing/imputation Pipeline 

## Overview

This repository provides a containerized pipeline for data preparation for phasing and imputation on either the TOPmed imputation server or UK Biobank RAP. The pipeline is distributed as a .sif file that can be run using apptainer/singularity.
Presently (July 2025) only checks against TOPmed are implemented.

We are asking studies of predominately European and South Asian genetic ancestry to impute to the latest UK Biobank haplotype reference panel. Studies of other genetic ancestries should impute to TOPMed.

## Usage

1. **Clone the pre-phasing/imputation report from GitHub**

   ```
   git clone git@github.com:giant-consortium/pre_phasing.git
   ```

2. **Edit `parameters.txt` to set paths and options for your data**. There are three parameters that need to be set in the `parameters.txt` file.
 
   ```
   # Imputation reference panel - TOPMED or UKB
   REF_PANEL=["TOPMED"|"UKB"]

   # Directory containing plink data and prefix
   PLINK_PREFIX="/path/to/plink_files"

   # Output directory for VFCs for phasing/imputatioon
   OUT_DIR="/path/to/output/directory"
   ```

3. **Run the pipeline:**

   ```
   bash PREPHASING_PIPELINE.sh
   ```

4. **Outputs** will be saved in the directory specified by `OUT_DIR` in `parameters.txt` with the final VCFs for phasing and imputation saved in the subdirectory `vcfs_for_phasing_imputation/`.


## Details

There are several checks made to QC'd array data by this workflow as detailed below. Reference datasets are built into the .sif container file to enable comparisons between study genotype data and reference panel.

1. **Chromosome and base-pair order**
A check made is to ensure all variants are ordered in the `.bim` file by chromosome / base-pair position. Updates to the data will be made if unexpected ordering of variants has been identified.

2. **Overlap with imputation reference panel**
A check is made to determine how many variants overlap with the imputation reference panel based on chromosome and base-pair position. Variants that do not overlap based on genomic coordinates will be removed.

3. **Allele frequency checks**
A check is made to ensure the allele frequencies of variants are consistent with those in the imputation panel. For TOPmed, this is the overall allele frequency. Variants with a MAF discrepancy > 0.2 will be removed. 

4. **Strand consistencies**
A check is made to ensure variants that overlap based on chromosome and base-pair position have the same alleles. Variants where allele are different, are flipped is consistent with strand flips. 

5. **Allele consistencies**
Variants where alleles are consistent after account for potential strand flips are removed from the array-based genotype dataset of the study


## Example output from workflow

```
------------------------------------------------------
-     Pre-phasing and Imputation Checks Pipeline     -
-         Questions to A.R.Wood@exeter.ac.uk         -
-                       GIANT                        -
------------------------------------------------------

Downloading container...
--2025-07-28 13:07:43--  https://storage.googleapis.com/giant_deeper_imputation/singularity_containers/giant_prephasing_pipeline_latest.sif
Resolving storage.googleapis.com (storage.googleapis.com)... 142.250.129.207, 216.58.213.27, 142.251.30.207, ...
Connecting to storage.googleapis.com (storage.googleapis.com)|142.250.129.207|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 4338712576 (4.0G) [application/octet-stream]
Saving to: ‘giant_prephasing_pipeline_latest.sif’

giant_prephasing_pipeline_latest.sif      100%[==========================]   4.04G  47.8MB/s    in 90s

2025-07-28 13:09:12 (46.2 MB/s) - ‘giant_prephasing_pipeline_latest.sif’ saved [4338712576/4338712576]

Checking chromosomes and variant ordering in bim file...
  Unexpected ordering of variants in PLINK files. This will now be resolved.
  Reordering of genetic data complete.

Generating allele frequencies for variants on array...
  Allele frequencies of study data generated.

Checking data against TOPMED reference panel

  Options Set:
    Reference Panel:             TOPMed
    Bim filename:                ./results/MYSTUDY_sorted.bim
    Reference filename:          /usr/local/bin/PASS.Variantsbravo-dbsnp-all.tab.gz
    Allele frequencies filename: ./results/MYSTUDY_sorted_freqs.frq
    Output directory:            ./results
    Allele frequency threshold:  0.2

  Path to plink bim file: /home/ubuntu/giant/pre_phasing/results
  Writing output files to: ./results

  Reading /usr/local/bin/PASS.Variantsbravo-dbsnp-all.tab.gz
  10000000 variants loaded
  20000000 variants loaded
  30000000 variants loaded
  40000000 variants loaded
  50000000 variants loaded
  ...
  410000000 variants loaded
  420000000 variants loaded
  430000000 variants loaded
  440000000 variants loaded
  450000000 variants loaded
  460000000 variants loaded

  Details written to log file: /home/ubuntu/giant/pre_phasing/results/LOG-MYSTUDY_sorted-TOPMed.txt

  Creating variant lists
    /home/ubuntu/giant/pre_phasing/results/Force-Allele1-MYSTUDY_sorted-TOPMed.txt
    /home/ubuntu/giant/pre_phasing/results/Strand-Flip-MYSTUDY_sorted-TOPMed.txt
    /home/ubuntu/giant/pre_phasing/results/ID-MYSTUDY_sorted-TOPMed.txt
    /home/ubuntu/giant/pre_phasing/results/Position-MYSTUDY_sorted-TOPMed.txt
    /home/ubuntu/giant/pre_phasing/results/Chromosome-MYSTUDY_sorted-TOPMed.txt
    /home/ubuntu/giant/pre_phasing/results/Exclude-MYSTUDY_sorted-TOPMed.txt
    /home/ubuntu/giant/pre_phasing/results/FreqPlot-MYSTUDY_sorted-TOPMed.txt

  Matching to TOPMed ---

    Position Matches
    ID matches TOPMed 0
    ID Doesn't match TOPMed 534999
    Total Position Matches 534999
    ID Match
    Position different from TOPMed 0
    No Match to TOPMed 12708
    Skipped (MT) 0
    Total in bim file 547707
    Total processed 547707

    Indels 0

    SNPs not changed 87521
    SNPs to change ref alt 431506
    Strand ok 519027
    Total Strand ok 519027

    Strand to change 0
    Total checked 534999
    Total checked Strand 519027
    Total removed for allele Frequency diff > 0.2 2025
    Palindromic SNPs with Freq > 0.4 384

    Non Matching alleles 15588
    ID and allele mismatching 15588; where TOPMed is . 0
    Duplicates removed 0

  Writing plink commands to: Run-plink.sh

Generating VCFs for phasing and imputation...
  Excluding problematic variants relative to reference panel
  Flipping strands where required
  Forcing A1/A2 to align with REF/ALT
  Splitting into separate chromosomes and converting to *.vcf.gz
    1
    2
    3
    ...
    21
    22
    23
VCFs for TOPmed imputation can be found in ./results/vcfs_for_phasing_imputation/
Pre-phasing and pre-imputation checks complete.
```
