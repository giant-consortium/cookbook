---
layout: default
---
<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./index.html">⬅️ Return to Homepage</a>
  <a href="dev_guides/topmed_imputation.html">Go to Step 3 [TOPMed Imputation] ➡️</a>
</div>

# Pre-phasing Pipeline 

## Overview

This repository provides a containerized pipeline for data preparation for phasing and imputation on either the TOPmed imputation server or UK Biobank RAP. The pipeline is distributed as a .sif file that can be run using apptainer/singularity.
Presently (November 2026) only checks against TOPmed are implemented.

We are asking studies of predominately European and South Asian genetic ancestry to impute to the latest UK Biobank haplotype reference panel. Studies of other genetic ancestries should impute to TOPMed.

## Usage

1. **Clone the pre-phasing/imputation repo from GitHub**

   ```bash
   git clone git@github.com:giant-consortium/pre_phasing.git
   cd pre_phasing/
   chmod +x PREPHASING_PIPELINE.sh
   ```

2. **Edit `parameters.txt` to set paths and options for your data**. There are three parameters that need to be set in the `parameters.txt` file. 
If you have used the sample/variant QC pipeline, you should provide the prefix of the plink filename found within the output directory created: `<path_of_sample_qc_resulst>/<study>_Outputs/PostSampleVariantQC/`
 
   ```bash
   # Imputation reference panel - TOPMED or UKB
   ref_panel="TOPMED"

   # Directory containing plink data and prefix
   plink_prefix="/home/ubuntu/giant_step1_qc/mystudy_Outputs/PostSampleVariantQC/mystudy_postQC"

   # Force container and reference data download (true/false). By default, the pipeline will check if these files exist. 
   # Only set to true if you require the container or data to be redownloaded (e.g. due to previous interrupted download)
   force_downloads="false"

   # Output directory for VFCs for phasing/imputatioon
   out_dir="/home/ubuntu/giant_step2_prephasing_checks/"
   ```

3. **Run the pipeline**. This will download the container if it does not already exist in the working directory. You should specify whether you would like to use Apptainer or Singularity to run the container.

   ```bash
   # Run container using Apptainer
   bash PREPHASING_PIPELINE.sh --apptainer
   
   # Run container using Singularity 
   bash PREPHASING_PIPELINE.sh --singularity
   ```

4. **Outputs** will be saved in the directory specified by `out_dir` in `parameters.txt` with the final VCFs for phasing and imputation saved in the subdirectory `vcfs_for_phasing_imputation/`.


## Details

There are several checks made to QC'd array data by this workflow as detailed below. Reference datasets are built into the .sif container file to enable comparisons between study genotype data and reference panel.

1. **Chromosome and base-pair order**
A check made is to ensure all variants are ordered in the `.bim` file by chromosome / base-pair position. Updates to the data will be made if unexpected ordering of variants has been identified. 
The updated PLINK files will be placed in the directory assigned to the `out_dir` variable.

2. **Overlap with imputation reference panel**
A check is made to determine how many variants overlap with the imputation reference panel based on chromosome and base-pair position. Variants that do not overlap based on genomic coordinates will be removed.

3. **Allele frequency checks**
A check is made to ensure the allele frequencies of variants are consistent with those in the imputation panel. For TOPmed, this is the overall allele frequency. Variants with a MAF discrepancy > 0.2 will be removed. 

4. **Strand consistencies**
A check is made to ensure variants that overlap based on chromosome and base-pair position have the same alleles. Variants where allele are different, are flipped is consistent with strand flips. 

5. **Allele consistencies**
Variants where alleles are consistent after account for potential strand flips are removed from the array-based genotype dataset of the study. Palindromic SNPs with MAF > 0.4 removed also.

6. **Duplicates**
Variants with a chromosome and position shared with other variants will be removed from the array data

In addition, the output VCF will force genotypes to be coded to REF and ALT as defined by the haplotype reference panels.

#### Example terminal output from workflow (with genomic position reordering of variants required) 

```
bash PREPHASING_PIPELINE.sh --apptainer
------------------------------------------------------------
     Pre-phasing and Imputation Checks Pipeline - 1.0.0
                      GIANT Consortium                      
------------------------------------------------------------
Workflow will run using apptainer

Options set: 

  Reference panel:           TOPMED
  Plink filename:            /home/ubuntu/step1_extend_genotype_qc_output/merged_extend_b38_Outputs/PostSampleVariantQC/merged_extend_b38_postQC
  Reference data directory:  ./ref_data/
  Force downloads:           false
  Output directory:          /home/ubuntu/step2_extend_prephasing_output_v3

Downloading container...
--2026-11-02 14:32:50--  https://storage.googleapis.com/giant_deeper_imputation/singularity_containers/giant_prephasing_pipeline_1.0.0.sif
Resolving storage.googleapis.com (storage.googleapis.com)... 142.250.117.207, 142.250.129.207, 142.250.140.207, ...
Connecting to storage.googleapis.com (storage.googleapis.com)|142.250.117.207|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 342110208 (326M) [application/octet-stream]
Saving to: ‘giant_prephasing_pipeline_1.0.0.sif’

giant_prephasing_pipeline_1.0.0.sif                                   100%[================================>] 326.26M  41.5MB/s    in 8.3s    

2026-11-02 14:32:58 (39.4 MB/s) - ‘giant_prephasing_pipeline_1.0.0.sif’ saved [342110208/342110208]

--2026-11-02 14:32:58--  https://storage.googleapis.com/giant_deeper_imputation/singularity_containers/giant_prephasing_pipeline_1.0.0.sif.md5
Resolving storage.googleapis.com (storage.googleapis.com)... 142.251.30.207, 142.251.29.207, 142.250.117.207, ...
Connecting to storage.googleapis.com (storage.googleapis.com)|142.251.30.207|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 70 [application/octet-stream]
Saving to: ‘giant_prephasing_pipeline_1.0.0.sif.md5’

giant_prephasing_pipeline_1.0.0.sif.md5                               100%[================================>]      70  --.-KB/s    in 0s      

2026-11-02 14:32:59 (33.4 MB/s) - ‘giant_prephasing_pipeline_1.0.0.sif.md5’ saved [70/70]

--2026-11-02 14:33:00--  https://storage.googleapis.com/giant_deeper_imputation/PASS.Variantsbravo-dbsnp-all.tab.gz
Resolving storage.googleapis.com (storage.googleapis.com)... 142.251.30.207, 142.250.151.207, 142.251.29.207, ...
Connecting to storage.googleapis.com (storage.googleapis.com)|142.251.30.207|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 3983735769 (3.7G) [application/octet-stream]
Saving to: ‘./ref_data//PASS.Variantsbravo-dbsnp-all.tab.gz’

./ref_data//PASS.Variantsbravo-dbsnp-all.tab.gz                       100%[================================>]   3.71G  28.6MB/s    in 1m 53s  

2026-11-02 14:34:53 (33.5 MB/s) - ‘./ref_data//PASS.Variantsbravo-dbsnp-all.tab.gz’ saved [3983735769/3983735769]

Checking chromosomes and variant ordering in bim file...
  Reordering checks of genetic data complete.

Generating allele frequencies for variants on array...
  Allele frequencies of study data generated.

Checking data against TOPMED reference panel

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

  Details written to log file: /mnt/output/LOG-merged_extend_b38_postQC_sorted-TOPMed.txt

  Creating variant lists
    /mnt/output/Force-Allele1-merged_extend_b38_postQC_sorted-TOPMed.txt
    /mnt/output/Strand-Flip-merged_extend_b38_postQC_sorted-TOPMed.txt
    /mnt/output/ID-merged_extend_b38_postQC_sorted-TOPMed.txt
    /mnt/output/Position-merged_extend_b38_postQC_sorted-TOPMed.txt
    /mnt/output/Chromosome-merged_extend_b38_postQC_sorted-TOPMed.txt
    /mnt/output/Exclude-merged_extend_b38_postQC_sorted-TOPMed.txt
    /mnt/output/FreqPlot-merged_extend_b38_postQC_sorted-TOPMed.txt

  Matching to TOPMed ---

    Position Matches
    ID matches TOPMed 0
    ID Doesn't match TOPMed 470275
    Total Position Matches 470275
    ID Match
    Position different from TOPMed 0
    No Match to TOPMed 10848
    Skipped (MT) 0
    Total in bim file 481123
    Total processed 481123

    Indels 0

    SNPs not changed 63659
    SNPs to change ref alt 379313
    Strand ok 421371
    Total Strand ok 442972

    Strand to change 34893
    Total checked 470275
    Total checked Strand 456264
    Total removed for allele Frequency diff > 0.2 2468
    Palindromic SNPs with Freq > 0.4 361

    Non Matching alleles 13650
    ID and allele mismatching 13650; where TOPMed is . 0
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
