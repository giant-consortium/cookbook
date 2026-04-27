---
layout: default
---

<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./ind_geno_qc_step6.html">⬅️ Step 6: Principal Component Analysis</a>
  <a href="./ind_geno_qc_step8.html">Step 8: Ancestry-Specific PCA ➡️</a>
</div>

[Back to Pipeline Overview](./ind_geno_qc_detailed.html)

# Step 7: Ancestry Prediction

**Script:** `Step7_AncestryModel.sh` | **Utility:** `./utils/train_pca_model.py` | **Report:** `./utils/report_ancestry_predictions.Rmd`

---

![Step 7: Ancestry Prediction](./../diagrams/ind_geno_qc/Step7.png)

## Model Training

1. **Inputs:** Population labels for REFERENCE dataset, REFERENCE PCs, training algorithm, training parameters
2. **Label processing:** Exclude 'oth' samples; combine NFE and FIN into EUR
3. **Algorithm options:**
   - **MANCS** (Multi-Ancestry Nearest Control Selection) — default
   - **Random Forest** with optional hyperparameter tuning
4. **Output:** Trained model

## Prediction and Assignment

1. **Predict:** Apply trained model to STUDY PCs → produces a per-sample ancestry prediction with confidence score
2. **Confidence thresholding:**
   - Drop samples with confidence < 0.8
   - If **all** samples are dropped at the 80% threshold, fall back to dropping samples with confidence below the 75th percentile instead
3. **Output:** Per-sample ancestry prediction
4. **Visualization:** PC plots with ancestry predictions and confidence distributions

---

<div style="display: flex; justify-content: space-between;">
  <a href="./ind_geno_qc_step6.html">⬅️ Step 6: Principal Component Analysis</a>
  <a href="./ind_geno_qc_step8.html">Step 8: Ancestry-Specific PCA ➡️</a>
</div>
