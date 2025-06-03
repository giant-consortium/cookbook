# Genome Wide Association Analysis   

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

Modify the `parameters_gwas.txt` file with your input file names and parameters to be used to run the GWAS.   


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

