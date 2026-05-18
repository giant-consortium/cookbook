---
layout: default
---

<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./ind_geno_qc_step7.html">⬅️ Step 7: Ancestry Prediction</a>
  <a href="./ind_geno_qc_step9.html">Step 9: Cleanup and Reporting ➡️</a>
</div>

[Back to Pipeline Overview](./ind_geno_qc_detailed.html)

# Step 8: Ancestry-Specific PCA

**Script:** `Step8_FinalizeOutputsPostQC.sh`

![Step 8: Finalize Outputs Post-QC](./../diagrams/ind_geno_qc/Workflow1_Step9.png)

## Process

1. **Remove related samples:** From the post-QC PLINK files, remove related samples as identified in Step 5 (using a remove-list if present).
2. **Generate final post-QC dataset:** Output the final post-QC PLINK files (with relateds removed) for downstream use.
3. **Copy key outputs:** Copy the final ancestry prediction file and PCA projections to the post-QC output directory.
4. **Copy rsID mapping file:** If present, move the rsID mapping file to the post-QC output directory.
5. **Split by ancestry:** For each predicted ancestry, filter the post-QC dataset to create ancestry-specific PLINK files (only if there are at least 2 samples for that ancestry).

<div style="display: flex; justify-content: space-between;">
  <a href="./ind_geno_qc_step7.html">⬅️ Step 7: Ancestry Prediction</a>
  <a href="./ind_geno_qc_step9.html">Step 9: Ancestry-Specific PCA ➡️</a>
</div>
