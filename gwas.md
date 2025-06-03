# Genome Wide Association Analysis   

This pipeline uses [REGENIE](https://rgcgithub.github.io/regenie/) software to perform genome-wide association analysis.   
The following steps are performed when running the pipeline :   
- Conversion of imputed genomic data (.vcf) to plink2 pgen/pvar/psam format (likely one set per chromosome)   
- Step 1 of REGENIE using genomic data before imputation   
- Step 2 of REGENIE using the converted imputed data   
- Concatenation of REGENIE step 2 outputs into one single genome-wide output file

## Run pipeline using docker   

### Clone GitHub repo    

```bash
 git clone https://github.com/giant-consortium/association_analysis.git
```

### Build docker   

Once inside the `association_analysis` repo, run the following command to build the docker from the Dockerfile :    

```bash
docker build --platform linux/amd64 -t step4_assoc .
```

### Update parameters and paths to input files    

Modify the `parameters_gwas.txt` file with your input file names and parameters to be used to run the GWAS, see main inputs needed below.   

- vcf files from imputation step (to be placed in a dedicated `vcfs` folder under your input directory)  
- plink dataset to be used for regenie step 1 (`regenie_step1_trio_name`) : bed/bim/fam trio     
- phenotype file (`pheno_file`) : a tab-delimited file starting with the 2 columns FID IID and other columns containing your phenotype data. See [regenie documentation](https://rgcgithub.github.io/regenie/options/#phenotype-file-format) for file format
- columns from the phenotype file to run gwas on (`pheno_col`): column names without quotes, separated by commas (no spaces)
- covariate file (`covar_file`) : a tab-delimited file starting with the 2 columns FID IID and other columns containing your covariates. See [regenie documentation](https://rgcgithub.github.io/regenie/options/#covariate-file-format) for file format
- columns referring to **continuous** covariates from the covariate file, to be used for the gwas (`cont_covar_col`) : column names without quotes, separated by commas (no spaces)
- columns referring to **categorical** covariates from the covariate file, to be used for the gwas (`cat_covar_col`) : column names without quotes, separated by commas (no spaces)
- sample file (`samples_to_keep`) : a tab-delimited file with 2 columns containing the participants FID and IID that you want to use in your gwas, but no colnames    


### Launch pipeline - example on test data

To launch the pipeline using the test data in `association_analysis/test_input` :     
- Create a vcfs folder located at `association_analysis/test_input/vcfs`
- Download some toy vcfs created by Andy [here](https://zenodo.org/records/13942905) (e.g. the small ones 20 to 22) and save them under `association_analysis/test_input/vcfs`
- Run the command below :    
    
```bash
docker run -it \
  -v <PATH>/GitHub/association_analysis/test_input/:/input \
  -v <PATH>/GitHub/association_analysis/test_output/:/output \
  --platform linux/amd64 \
  --env-file <PATH>/GitHub/association_analysis/parameters_gwas.txt \
  step4_assoc \
  bash /scripts/run_asssoc_pipeline.sh
```

**To run it on your own inputs**, you will need to **change the path passed to the `-v` flag** and provide the path where your input files and `vcfs` folder are located.    

## Run pipeline using singularity   

