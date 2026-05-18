#!/bin/bash
# Step 9: Within-Ancestry Principal Component Analysis
# Computes per-ancestry PCs for fine-scale population structure analysis.
#
# Input: PC scores, ancestry labels, LD-pruned PLINK files
# Output: Per-ancestry PC matrices and consolidated file

set -euo pipefail
trap 'echo "[$(date "+%Y-%m-%d %H:%M:%S")] ERROR: Script failed at line $LINENO: $BASH_COMMAND"; exit 1' ERR

# Function to print messages with timestamps for better logging
print_with_timestamp() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Create log file
log_file="${logs_out_path}/step9_generate_ancestry_specific_pca_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a $log_file) 2>&1

print_with_timestamp "Generating ancestry-specific PCA..."

# Source shared write_manifest helper (fallback)
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
helper_script_utils="$(cd "${script_dir}/.." && cd utils && pwd)/write_manifest.sh"
if [ -f "${helper_script_utils}" ]; then
    # shellcheck source=/dev/null
    . "${helper_script_utils}"
    print_with_timestamp "Loaded manifest helper from utils: ${helper_script_utils}"
else
    print_with_timestamp "WARN: write_manifest helper not found at ${helper_script_utils}; using fallback manifest writer"
    write_manifest() { local manifest_dir="$1"; local entry="$2"; mkdir -p "${manifest_dir}"; printf '%s\n' "${entry}" >> "${manifest_dir}/generated_files.txt"; }
fi

# Drop the first row (header) without modifying the original file
ancestry_predictions_noheader="${ancestry_out_path}/${study_name}_AncestryPredictions.noheader.tmp"

# For each predicted ancestry, filter the dataset and run PCA
for ancestry in $(cut -f2 "$ancestry_predictions_noheader" | sort | uniq); do
    # Filter the dataset to keep only individuals with the predicted ancestry
    awk -v ancestry="$ancestry" '$2 == ancestry {print $1}' "$ancestry_predictions_noheader" > "${ancestry_out_path}/${study_name}_${ancestry}_iids_only.txt"

    # If there are <2 samples, skip the ancestry
    num_samples=$(wc -l < "${ancestry_out_path}/${study_name}_${ancestry}_iids_only.txt")
    [ "$num_samples" -ge 2 ] || { print_with_timestamp "Skipping $ancestry: only $num_samples samples."; continue; }
    
    # Calculate PCA for the ancestry-specific subset
    print_with_timestamp "FlashPCA calculation for $ancestry [$num_samples samples]..."
    flashpca_log="$logs_out_path/${study_name}_${ancestry}_flashpca.log"
    flashpca --bfile "${ancestry_pca_out_path}/${study_name}_${ancestry}_filtered" \
        --ndim $num_pcs \
        --outvec "${ancestry_pca_out_path}/${study_name}_${ancestry}_PCA.txt" \
        --outload "${ancestry_pca_out_path}/loadings_${ancestry}_fpca_outputs.txt" \
        --outmeansd "${ancestry_pca_out_path}/meansd_${ancestry}_fpca_outputs.txt" \
        --outval "${ancestry_pca_out_path}/eigenvalues_${ancestry}_fpca_outputs.txt" \
        --outpve "${ancestry_pca_out_path}/pve_${ancestry}_fpca_outputs.txt" \
        > "$flashpca_log" 2>&1 || true
    
    # Handle dimension limits (re-run with allowed_dim if needed)
    allowed_dim=$(sed -n 's/.*but[[:space:]]*only[[:space:]]*\([0-9][0-9]*\)[[:space:]]*allowed.*/\1/p' "$flashpca_log" || true)
    if [ -n "${allowed_dim:-}" ] && [ "$allowed_dim" -ge 2 ]; then
        print_with_timestamp "FlashPCA limited to $allowed_dim PCs for $ancestry; re-running..."
        flashpca --bfile "${ancestry_pca_out_path}/${study_name}_${ancestry}_filtered" \
            --ndim $allowed_dim \
            --outvec "${ancestry_pca_out_path}/${study_name}_${ancestry}_PCA.txt" \
            --outload "${ancestry_pca_out_path}/loadings_${ancestry}_fpca_outputs.txt" \
            --outmeansd "${ancestry_pca_out_path}/meansd_${ancestry}_fpca_outputs.txt" \
            --outval "${ancestry_pca_out_path}/eigenvalues_${ancestry}_fpca_outputs.txt" \
            --outpve "${ancestry_pca_out_path}/pve_${ancestry}_fpca_outputs.txt" \
            > "$flashpca_log" 2>&1
    fi
    


done

# Consolidate ancestry-specific PCs
print_with_timestamp "Consolidating per-ancestry PCs..."
python3 /utils/stack_ancestry_pca.py --indir "${ancestry_pca_out_path}" --out "${ancestry_pca_out_path}/${study_name}_combined_ancestry_pca.tsv" || true

# Generate report
cp /utils/qc_report_style.css ${ancestry_pca_out_path}/
cp /utils/report_ancestry_specific_pca.Rmd "${ancestry_pca_out_path}/"
print_with_timestamp "Generating ancestry-specific PCA report..."
Rscript -e "rmarkdown::render(input='${ancestry_pca_out_path}/report_ancestry_specific_pca.Rmd', output_file='${study_name}_report_ancestry_specific_pca.html', output_dir='${ancestry_pca_out_path}', params = list(ancestry_pca_out_path='${ancestry_pca_out_path}', study_name='${study_name}', reference_name='${reference_name}', refgen_pcs = '${pca_out_path}/pcs_${reference_name}_fpca_outputs.txt', refgen_pop = '${ancestry_out_path}/combined_population_labels.txt', num_pcs_to_plot=${num_pcs_to_plot}, working_dir = '${ancestry_pca_out_path}'))" 2>&1 | tee -a ${log_file}
rm "${ancestry_pca_out_path}/report_ancestry_specific_pca.Rmd"

# Remove temp file
rm -f "${ancestry_predictions_noheader}"

# Final ancestry-specific PCA outputs: copy to post-QC output
if [ -d "${ancestry_pca_out_path}" ]; then
    cp "${ancestry_pca_out_path}/${study_name}"_*_PCA.txt "${post_sample_variant_qc_out_path}/" 2>/dev/null || print_with_timestamp "No ancestry-specific PCA projection files found to copy to post-QC output"
else
    print_with_timestamp "No ancestry-specific PCA output directory found to copy from"
fi  

print_with_timestamp "Within-ancestry PCA complete!"


