#!/bin/bash
# Step 8: 
# From the Step3 outputs, remove related samples (as identified using pruned or
# unpruned data in Step5)

# Then, copy the final ancestry prediction file and PCA projections to the 
# post-QC output directory for downstream use in association analyses and other post-QC steps.

# Also, based on the final ancestry predictions, split the postQC dataset
# into ancestry-specific subsets, which are also returned as part of the "final" outputs.

# Input: Post-QC PLINK files, ancestry predictions, PCA projections
# Output: Post-QC PLINK files with relateds removed, ancestry-specific PLINK files, 
#        final ancestry prediction file and PCA projections copied to post-QC output

set -euo pipefail
trap 'echo "[$(date "+%Y-%m-%d %H:%M:%S")] ERROR: Script failed at line $LINENO: $BASH_COMMAND"; exit 1' ERR

# Function to print messages with timestamps for better logging
print_with_timestamp() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Create log file
log_file="${logs_out_path}/step8_finalize_outputs_post_qc_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a $log_file) 2>&1

print_with_timestamp "Finalizing outputs post-QC..."

# Select post QC file as input
# Drop related samples from it first
# Final Post-QC output: Remove relateds from post-QC files (WITHOUT PRUNING)
remove_list_canon="${kinship_out_path}/${study_name}_king_remove_list.txt"
# Run PLINK2, but only pass --remove when the remove-list exists and is non-empty
plink_cmd=(plink2 --bfile "${qc_out_filepath}")
if [ -s "${remove_list_canon}" ]; then
    print_with_timestamp "Applying remove-list: ${remove_list_canon}"
    plink_cmd+=(--remove "${remove_list_canon}")
else
    print_with_timestamp "No remove-list present or file empty; running PLINK without --remove"
fi
plink_cmd+=(--make-bed --out "${post_sample_variant_qc_out_path}/${study_name}_postQC")
"${plink_cmd[@]}" 2>&1 | tee -a ${log_file}

# Move the final output files to the post sample & variant QC directory

# Final Ancestry Prediction file: copy to post-QC output
if [ -f "${ancestry_out_path}/${study_name}_AncestryPredictions.txt" ]; then
    cp "${ancestry_out_path}/${study_name}_AncestryPredictions.txt" "${post_sample_variant_qc_out_path}"
    print_with_timestamp "Copied ancestry predictions to post-QC output"
else
    print_with_timestamp "No ancestry predictions file found to copy to post-QC output"
fi

# Final PC projections: copy to post-QC output
if [ -f "${pca_out_path}/${study_name}_projections.txt" ]; then
    cp "${pca_out_path}/${study_name}_projections.txt" "${post_sample_variant_qc_out_path}"
    print_with_timestamp "Copied PCA projections to post-QC output"
else
    print_with_timestamp "No PCA projections file found to copy to post-QC output"
fi

# Copy rsID mapping file if it exists
if [ -f "${kinship_out_path}/${study_name}_rsid_mapping.txt" ]; then
    mv "${kinship_out_path}/${study_name}_rsid_mapping.txt" "${post_sample_variant_qc_out_path}"
    print_with_timestamp "Moved rsID mapping file"
else
    print_with_timestamp "No rsID mapping file found (no rsIDs in dataset)"
fi

if command -v write_manifest >/dev/null 2>&1; then
    if [ -f "${post_sample_variant_qc_out_path}/${study_name}_rsid_mapping.txt" ]; then
    write_manifest "${post_sample_variant_qc_out_path}" "${post_sample_variant_qc_out_path}/${study_name}_rsid_mapping.txt" "--optional"
    fi
fi

# Read in the ancestry prediction file
ancestry_predictions="${ancestry_out_path}/${study_name}_AncestryPredictions.txt"

# Drop the first row (header) without modifying the original file
ancestry_predictions_noheader="${ancestry_out_path}/${study_name}_AncestryPredictions.noheader.tmp"
awk 'NR>1' "$ancestry_predictions" > "$ancestry_predictions_noheader"

# For each predicted ancestry, filter the dataset and run PCA
for ancestry in $(cut -f2 "$ancestry_predictions_noheader" | sort | uniq); do
    # Filter the dataset to keep only individuals with the predicted ancestry
    awk -v ancestry="$ancestry" '$2 == ancestry {print $1}' "$ancestry_predictions_noheader" > "${ancestry_out_path}/${study_name}_${ancestry}_iids_only.txt"

    # Resolve a valid .fam to join against: Prefer canonical post-QC, then hqsites_pruned
    fam_path=""
    if [ -f "${post_qc_filepath}.fam" ]; then
        fam_path="${post_qc_filepath}.fam"
    fi
    print_with_timestamp "Using .fam for join: $fam_path"

    # Join with .fam to get FID and IID columns (match .fam IID to the IID list)
    # The iids_only file has one column (IID), so use an awk membership join to avoid join-field mismatches.
    awk 'NR==FNR{ids[$1]=1; next} ($2 in ids){print $1, $2}' \
        "${ancestry_out_path}/${study_name}_${ancestry}_iids_only.txt" \
        "$fam_path" \
        > "${ancestry_out_path}/${study_name}_${ancestry}_iids.txt"

    # Log counts to help diagnose empty joins
    count_only=$(wc -l < "${ancestry_out_path}/${study_name}_${ancestry}_iids_only.txt" | tr -d '[:space:]')
    count_join=$(wc -l < "${ancestry_out_path}/${study_name}_${ancestry}_iids.txt" | tr -d '[:space:]')
    print_with_timestamp "Ancestry $ancestry: IIDs-only count=$count_only, matched FID+IID count=$count_join"

    # If there are <2 samples, skip the ancestry
    num_samples=$(wc -l < "${ancestry_out_path}/${study_name}_${ancestry}_iids.txt")
    [ "$num_samples" -ge 2 ] || { print_with_timestamp "Skipping $ancestry: only $num_samples samples."; continue; }
    
    # Filter to ancestry samples
    plink2 --bfile "${post_sample_variant_qc_out_path}/${study_name}_postQC" --keep "${ancestry_out_path}/${study_name}_${ancestry}_iids.txt" --make-bed --out "${ancestry_pca_out_path}/${study_name}_${ancestry}_filtered"
    
    # Copy filtered dataset to post-QC output
    for ext in bed bim fam; do
        [ -f "${ancestry_pca_out_path}/${study_name}_${ancestry}_filtered.${ext}" ] && cp "${ancestry_pca_out_path}/${study_name}_${ancestry}_filtered.${ext}" "${post_sample_variant_qc_out_path}/"
    done

done

# Create manifest for all post-QC files (including ancestry-specific subsets)
if command -v write_manifest >/dev/null 2>&1; then
    for file in "${post_sample_variant_qc_out_path}/${study_name}_postQC".*; do
        write_manifest "${post_sample_variant_qc_out_path}" "$file" "--optional"
    done
    for ancestry_file in "${post_sample_variant_qc_out_path}/${study_name}"_*; do
        write_manifest "${post_sample_variant_qc_out_path}" "$ancestry_file" "--optional"
    done
else
    print_with_timestamp "write_manifest command not found; skipping manifest generation for post-QC outputs"
fi

print_with_timestamp "Post-QC output finalization complete!"