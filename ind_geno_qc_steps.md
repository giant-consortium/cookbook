## Pipeline Implementation

This file provides a detailed explanation for the Variant and Sample Level genotyping steps that are performed, and provides paths to the bash scripts used for this. It provides an in-depth understanding of the developed analysis pipeline, and will be particularly useful in making this pipeline modular and re-usable by future projects. 

### RUNNER.sh
This file configures paths, performs data downloads, and builds the Docker image. Once built, it calls the Docker image with the passed parameters and executes Workflow1 for the study dataset.

The steps included in this file are:
1. Set mount paths: To the study dataset, reference data, build check data and output
2. Check for Docker install and that Docker is running
3. If the reference and build check data have not been downloaded OR if the the force_data_download flag (passed as a command line argument) is set to True,  re-download the datasets from the Google Bucket.
4. If the Docker image (Named "sample_variant_qc:latest") does not exist OR if the force_build flag (passed as a command line argument) is set to True, re-build the Docker image.

**NOTE** As a pre-cautionary measure, dangling Docker images and volumes are removed whenever the Docker image is re-built. This significantly reduces the disk space used by Docker. 

It takes about 15 minutes to download the datasets and about 30 minutes to build the Docker image. 

All mount paths are defined as key-value pairs in the mounts.txt file. The environment variables are set using the parameters.txt file. These files can be found in the config folder, and can be changed in-between runs without re-building the image.

The container is started and the pipeline is run. The script _RunQCPipeline.sh_ calls the steps sequentially.

#### Reference Datasets:
This script uses the 1000 Genomes (1KG) and Human Genome Diversity Project (HGDP) datasets, as harmonized by gnomAD. The GRCh38 build is used as the standard. 

gnomAD identified some samples of low-quality that were to be filtered out. After excluding these, we had 3280 samples. Multi-allelic sites were filtered. Then, PLINK2 was used to perform pre-processing using the following criteria: 
    1. Minor Allele Frequency > 1%
    2. Hardy-Weinberg Equilibrium p-value > 1e-30 ## CHECK
    3. Variant level call rate > 98%
    4. Keep SNPs Only (Restrict to A,C,G,T)

These 'high-quality' sites are saved in the hg38 build, and exported to the hg37 build. The .bim files for both builds - which lists the variants - are used for identifying the build of the study dataset.

The continental labels for the 1KG and HGDP samples are provided in the GitHub repository, or can be downloaded (##TODO## Add links to gnomAD and dataset sources)


### Building the Development Environment
    _Reference: Dockerfile_

We use Docker containers (which can be converted to Singularity containers) to execute our pipeline. 

We first build a virtual machine with the Ubuntu 22.04 Operating System. 

Using Ubuntu's package manager (apt-get), libraries required to support the installation of all the subsequent tools are installed. 

Primary Tools:
1. Python3 with pandas, numpy, matplotlib, scipy, json, sklearn
2. R with data.table, kableExtra, knitr, rmarkdown, pandoc
3. FlashPCA with dependencies eigen3, boost, spectra
4. PLINK2 and PLINK1.9

After tool installation, the scripts are made executable using chmod.


### Pipeline Steps

The variables and paths used in all sub-steps are set in _RunQCPipeline.sh_, which then calls the bash scripts for each step sequentially. 

#### Step0: Set up directories, copy binaries, and convert genotypes to .bed/.bim/.bam files
    _Reference: Step0_Setup.sh_

1. Copy the binary files for PLINK1.9 and PLINK2 to the home (/) directory
2. Convert the study files to PLINK .bed/.bim/.fam format. Accepted input formats: .tar.gz, .ped/.map, .bgen
3. Check if a .bed/.bim/.fam files exist for the study
4. Create directories to store intermediates and output files. 
    a. Study-Specific Output Directory (Within 'output'): The output for a specific study is located in a sub-folder of this directory, and the name of the sub-folder is the study name. E.g., if your study is named STUDY3_EAS, the outputs will be in ./output/STUDY3_EAS_Outputs.
    b. Study-Specific Intermediate Outputs: Within the study-specific output directory, there are sub-folders for the InitialQC results (which has all QC statistics in the QCStats sub-folder, and post-QC .bed/.bim/.fam files in the PostQC folder), the PCA results, Kinship and Ancestry analysis. All logs from the intermediate steps are stored in the Logs directory. 

#### Step1: Check if the build is hg38 or hg37
    _Reference: Step1_CheckBuild.sh_

The build determination is done using an R-script called check_build.R in the utils directory. This bash script provides paths to the study .bim file, as well as the .bim files for the reference dataset in both hg37 and hg38 formats. 

If the build is hg37, perform liftover to hg38 using the script convert_to_hg38.sh in utils. 

    _Reference: ./utils/check_build.R_

    1. Remove the 'chr' prefix from all .bim files
    2. Compare the study .bim file to the reference hg37 .bim file. Get the percentage of overlapping variant sites between the two files.
    3. Add the 'chr' prefix to the study .bim file and the reference hg38 file. Since the reference hg38 file uses the 'chr' prefix, we save the study .bim file with the prefix for consistency.
    4. Compare the study .bim file to the reference hg38 .bim file. Get the percentage of overlapping variant sites between the two files.
    5. If the overlap between the study and hg38 reference .bim file is >90%, it is in hg38. No further steps are performed.
    6. If the overlap between the study and hg37 reference .bim file is >90%, the study data is in hg37. This information is passed back to the calling bash script, and liftover is subsequently performed.
    7. If the overlap is less than 90% with both hg37 and hg38, the script displays that the build check is failed, and exits with status code 1. 


    _Reference: ./utils/convert_to_hg38.sh_

    1. Download the liftover file from UCSC's golden path
    2. Set the reference allele according to the hg37 reference file, and perform the liftover
    3. Add the suffix _hg37 to the original study files. Copy the converted study files to the expected location. Remove temporary files. 

#### Step 2: Get Stats before QC
    _Reference: Step2_GetInitialQCStats.sh_

Statistics are calculated using PLINK2 and PLINK. Then, an R script (./utils/1-1_preqcstat.Rmd) is used to create an HTML reports and plots. 

For samples, we get the sample call rate and heterozygosity rate, and plot the histograms of the distribution. The reported vs genetic sex is compared. 

For variants, we get the allele frequencies, call rate, hardy-weinberg equilibrium p-values and plot the histograms of the distribution. The number of monomorphic sites is counted. 

For variants, allele counts (for founders only) and genotype counts are also generated as intermediates, but not included in the report. 

QCStats and HTML Reports are stored in ./output/<study_name>/InitialQC/QCStats.

##TO-DO##: Move HTML Reports to a separate directory?

#### Step 3: Perform Basic QC
    _Reference: Step3_PerformBasicQC.sh_

Basic QC Steps are performed. 
1. Drop samples with a low call rate [DEFAULT: 0.1]
2. Drop variants with a low call rate [DEFAULT: 0.1]
3. Drop variants with a low minor allele frequency [DEFAULT: 0.01]
4. Drop variants with a low hardy-weinberg equilibrium p-value [DEFAULT: 1e-50]

##TO-DO##: Check values -- do we want to update HWE?

The output QC'ed files are saved in the .bed/.bim/.fam format in the ./output/<study_name>/InitialQC/PostQC. 

#### Step 4: Perform Kinship Analysis using KING
    _Reference: Step4_KinshipTest.sh_

1. Use PLINK2 to run KING. 
2. This generates 2 output files: kin0, which has the required output columns such as pairwise kinship coefficient and IBS0
3. R Script 1-3_relatedness.Rmd in utils is used to calculates number of MZ twins, 1/2/3 degree relatives and plot kinship coefficients for samples

The cut-off for relatedness can be set. The default value for this is 0.1.

The output from the Kinship Analysis is at ./output/<study_name>/Kinship

##TO-DO##: Drop related samples after Kinship test??

#### Step 5: SNP Intersection and LD Pruning
    _Reference: Step5_SNPIntersect.sh_

This step focuses on extracting the common SNPs between the two datasets, aligning alleles, and dropping duplicates. Once these pre-processing steps are done, LD Pruning can be performed on the reference dataset. Both datasets are then restricted to the LD Pruned SNPs. This data is used for downstream analysis. 

1. Get the list of SNPs in the reference dataset
2. Align alleles of the study dataset to the reference dataset
3. Get the list of SNPs in the study dataset
4. Find the intersection of the SNP between the two datasets
5. Restrict both reference & study dataset to SNPs that are in both datasets
6. Perform LD pruning for the reference dataset
7. Restrict both reference & study dataset to the LD-pruned SNPs
8. At this point, the number of variants in the study & reference datasets should be the same, and the alleles should be aligned the same way. This implies that the .bim file for study & reference data should be identical. We ensure that the previous steps were run correctly by testing whether the .bim files are identical. If not, exist the script. 

**NOTE** On 25th April 2025, the direct extraction of SNPs from the datasets after determining the list of intersection SNPs failed. This happened after the Hardy-Weinberg equilibirum filter was eased to increase the number of overlapping SNPs to ~90% between the 2 datasets. As a result, chunking had to be introduced. Whenever the intersecting SNPs have to be extracted from the two datasets, the list of SNPs is subdivided, and smalled .bed/.bim/.fam files are created. These are later combined using PLINK1.9's merge-list argument. 


#### Step 6: Generate PCAs
    _Reference: GeneratePCA.sh_ 

PCAs are passed as covariates to account for population stratification. These are also used to determine broad continental ancestry groups in the subsequent steps of our pipeline. 

1. Generate PCAs for the reference dataset using FlashPCA
2. Project the study dataset onto the reference data PCA space
3. Align the signs of the projected PCs
4. Generate an HTML report which contains plots of the initial PCs

The output from the PCA Analysis is at ./output/<study_name>/PCA

#### Step 7: Continental Ancestry Determination
    _Reference: Step7_TrainModel.sh_

This script identifies continental ancestries for the study samples. 

1. The PCAs of the reference dataset are used as the training dataset. The labels are the continental ancestry labels for the 1KG and HGDP datasets. Note that samples with ancestry label of 'oth' or 'Other' are not used, and that 'NFE' (Non-Finnish Europeans) and 'FIN' (Finnish Europeans) are combined into one group as 'EUR' (European). 

2. The training algorithm can be specified by the user: the implementation supports the Random Forest (RF) and the Multi-Ancestry Nearest Control Selection (MANCS) method. 

For RF, the model can be trained with or without hyperparameter tuning. A default hyperparameter tuning grid is provided, but can be altered by the user as required. 

3. This script calls a Python file (./utils/train_pca_model.py), which trains the specified training algorithm.

4. The trained algorithm is run on the projected PCs from the study dataset. Each sample is assigned a probability for belonging to a specific ancestry group. The sum of the probabilities for a particular sample is 1.

5. If the confidence of a sample belonging to a specific population is >=80% (probability of 0.8), then the sample is assigned to that population group for ancestry-specific analyses. If no samples reach this confidence level, we check for a confidence threshold of >=75%. 

6. Print the distribution of the ancestries, and plot the distribution of PC1 vs PC2, as well as PC3 vs PC4 for the training as well as test dataset. The code for this is at ./utils/plot_ancestry_predictions.py.

The output from the Ancestry Determination is at ./output/<study_name>/Ancestry.


#### Step 8: Ancestry-Specific PCA
    _Reference: Step8_GenerateAncestrySpecificPCA.sh_

For each ancestry group, we calculate the PCs, which will be passed as covariates during ancestry-specific analyses.

1. For each predicted ancestry, filter the study dataset to individuals with the predicted ancestry (with a confidence >= 80%). 
##TO-DO##: Check that low-confidence predictions are excluded
2. Project the filtered study dataset onto the reference PCA space.

The output from the PCA Analysis is at ./output/<study_name>/PCA

#### Step 9: Clean Up
    _Reference: CleanUp.sh_

In this step, log the file lists, remove the .bed/.bim/.fam files for the study, remove binaries, and zip or tar the output files for an easier upload as required. 

##TO-DO##: Discuss what to keep and what to remove at this stage.
