---
layout: default
---

<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./../pre_phasing_checks.html">⬅️ Go to Step 2 [Pre-Phasing Checks]</a>
  <a href="./../gwas.html">Go to Step 4 [GWAS Pipeline] ➡️</a>
</div>

# TOPMed Imputation

[TOPMed (Trans-Omics for Precision Medicine)](https://topmed.nhlbi.nih.gov/) is a large whole-genome sequencing reference panel, particularly useful for studies with diverse ancestries.

## Account setup

You will need an account on one of the imputation servers below. Registration is free with an institutional email address.

- **[TOPMed Imputation Server (BioData Catalyst)](https://imputation.biodatacatalyst.nhlbi.nih.gov)** hosted by NHLBI. See [server documentation](https://topmedimpute.readthedocs.io/en/latest/).
- **[Michigan Imputation Server](https://imputationserver.sph.umich.edu)** hosted by the University of Michigan. See [server documentation](https://imputationserver.readthedocs.io/en/latest/).

## Input

The input to TOPMed is the output of the [Pre-phasing Pipeline](./../pre_phasing_checks.html): per-chromosome post basic sample and variant QC VCFs that have been strand-checked and aligned to the reference panel.

| Source | Format | Location |
|--------|--------|----------|
| [Pre-phasing Pipeline](./../pre_phasing_checks.html) | `.vcf.gz`, one per chromosome (chr1-chr22, chrX) | `<out_dir>/vcfs_for_phasing_imputation/` |

Upload one file per chromosome. Most servers also require a `.tbi` tabix index alongside each VCF.

## Run configuration

Settings used for imputation job:

| Option | Value | Notes |
| -------- | ------- | ------- |
| Reference Panel | TOPMed r3 | Largest available TOPMed panel |
| Array Build | GRCh38/hg38 | Must match pre-phasing output build |
| rsq Filter | 0.3 | Variants below this INFO/R² are excluded from output |
| Phasing Engine | Eagle v2.4 | Selected on the server — phased output |
| Allele Frequency Check | vs. TOPMed Panel | Flags large AF discordance before imputation |
| Mode | Quality Control & Imputation | Runs QC checks then imputes |
| Generate Meta-imputation file | Checked | Required for downstream meta-analysis |

## Outputs

From the server, you receive one result archive per chromosome. After decryption, each archive contains:

| File | Description |
| ------ | ------------- |
| `chr*.dose.vcf.gz` | Imputed dosages (DS field) and genotype probabilities (GP field) |
| `chr*.info.gz` | Per-variant imputation quality statistics (R², AF, MAF) |
| `chr*.empiricalDose.vcf.gz` | Hard-call genotypes at empirically phased sites (where available) |

---

<a id="decrypt"></a>

## Decrypting results

TOPMed encrypts result archives with AES-256. When the job finishes, the decryption password is emailed to your registered address. The server does not keep a copy of the password.

### Option 1: 7z (bash)

First check whether 7z is already available — it is pre-installed on many HPC systems, or loadable as a module:

```bash
which 7z || which 7za
module avail p7zip 2>&1 | grep -i p7zip
```

If not available, download from [7-zip.org/download.html](https://www.7-zip.org/download.html). On Linux x64:

```bash
wget https://github.com/ip7z/7zip/releases/download/26.02/7z2602-linux-x64.tar.xz
tar xf 7z2602-linux-x64.tar.xz -C ~/7z/
export PATH="$HOME/7z:$PATH"   # add to ~/.bashrc to persist
```

This package is also available via **conda-forge:** `conda install -c conda-forge p7zip`

Decrypt all chromosome archives:

```bash
for zip in chr_*.zip; do
  chr="${zip%.zip}"
  7zz e "$zip" -p"YOUR_PASSWORD" -o./${chr}_imputed/
done
```

### Option 2: Python based

**Python ([pyzipper](https://github.com/danifus/pyzipper)):** supports AES-256 natively; Python's built-in `zipfile` does not.

  ```bash
  pip install pyzipper
  ```

  ```python
  import pyzipper, os, glob
  password = b"YOUR_PASSWORD"
  for zippath in sorted(glob.glob("chr_*.zip")):
      out_dir = zippath.replace(".zip", "_imputed")
      os.makedirs(out_dir, exist_ok=True)
      with pyzipper.AESZipFile(zippath) as zf:
          zf.pwd = password
          zf.extractall(out_dir)
  ```

### Option 3: imputationbot

[imputationbot](http://imputationbot.readthedocs.io/) is developed by Lukas Forer and Sebastian Schönherr (University of Innsbruck, Michigan Imputation Server team). It authenticates with the server, downloads the archives, and decrypts them. See the [documentation](http://imputationbot.readthedocs.io/) for setup.
