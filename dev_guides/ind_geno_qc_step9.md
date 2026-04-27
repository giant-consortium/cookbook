---
---

<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./ind_geno_qc_step8.html">⬅️ Step 8: Ancestry-Specific PCA</a>
  <a href="./ind_geno_qc_detailed.html">⬅️ Back to Pipeline Overview</a>
</div>

[Back to Pipeline Overview](./ind_geno_qc_detailed.html)

# Step 9: Cleanup and Reporting

**Script:** `CleanUp.sh`

---

![Step 9: Cleanup](./../diagrams/ind_geno_qc/Step9.png)

## Create Final Post-QC Dataset

1. **Combine exclusions:** Take STUDY file after basic QC and remove samples excluded due to relatedness (from Step 5) → produces the final **Post QC STUDY dataset** (`.bed/.bim/.fam`)

## Reporting and Cleanup

1. **File logging:** Log list of files in all output directories
2. **Report conversion:** Convert HTML reports to PDF format
3. **Combined reporting:** Collate PDFs into a single output report → produces the final **Sample Variant QC Report**

> **Styling Note:** All HTML reports use consistent formatting via `./utils/qc_report_style.css`

---

<div style="display: flex; justify-content: space-between;">
  <a href="./ind_geno_qc_step8.html">⬅️ Step 8: Ancestry-Specific PCA</a>
  <a href="./ind_geno_qc_detailed.html">Back to Pipeline Overview ➡️</a>
</div>
