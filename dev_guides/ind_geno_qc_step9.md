---
layout: default
---

<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./ind_geno_qc_step8.html">⬅️ Step 8: Finalize Outputs</a>
  <a href="./ind_geno_qc_step10.html">Step 10: Clean and Consolidate ➡️</a>
</div>

[Back to Pipeline Overview](./ind_geno_qc_detailed.html)

# Step 9: Ancestry-Specific PCA

**Script:** `Step9_AncestrySpecificPCA.sh`

---

![Step 9: Ancestry-Specific PCA](./../diagrams/ind_geno_qc/Workflow1_Step9.png)

## Process

1. **Sample count check:** Only proceed with PCA if there are at least 2 samples for the ancestry group.
2. **Run FlashPCA:** Perform PCA for each ancestry-specific subset using FlashPCA. If sample size is smaller than `num_pcs`, FlashPCA is automatically re-run with a reduced dimensionality (`allowed_dim = n_samples - 1`).
3. **Consolidate per-ancestry PCs:** All per-ancestry PC files are concatenated into a single `<study_name>_combined_ancestry_pca.tsv` using `stack_ancestry_pca.py`. Samples from ancestry groups where FlashPCA produced fewer PCs than `num_pcs` (i.e. dimension-limited runs) are **dropped** from the combined file — they would otherwise carry `NaN` in the extra PC columns.
4. **Copy to final output:** The combined file is copied to `PostSampleVariantQC/` alongside the other final deliverables.
5. **Output:** `<study_name>_<ancestry>_PCA.txt` (per-ancestry) and `<study_name>_combined_ancestry_pca.tsv` (all ancestries, dimension-limited samples excluded)

---

<div style="display: flex; justify-content: space-between;">
  <a href="./ind_geno_qc_step8.html">⬅️ Step 8: Finalize Outputs</a>
  <a href="./ind_geno_qc_step10.html">Step 10: Clean and Consolidate ➡️</a>
</div>
