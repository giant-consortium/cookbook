#!/bin/bash
# Step 10: Report Consolidation and Final Output
# Merges HTML reports into PDF, moves final files, cleans up intermediates.
#
# Input: All step reports (HTML), final genotype and PC files
# Output: Combined PDF report, cleaned output directory, final manifest

set -euo pipefail
trap 'echo "[$(date "+%Y-%m-%d %H:%M:%S")] ERROR: Script failed at line $LINENO: $BASH_COMMAND"; exit 1' ERR

# Function to print messages with timestamps for better logging
print_with_timestamp() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Create log file
log_file="${logs_out_path}/step10_cleanup_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a $log_file) 2>&1

print_with_timestamp "Cleaning up..."

# Source manifest helper if present (resolve script dir robustly)
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Prefer a shared helper in utils/ so all scripts can source the same implementation
helper_script_utils="$(cd "${script_dir}/.." && cd utils && pwd)/write_manifest.sh"
if [ -f "${helper_script_utils}" ]; then
    # shellcheck source=/dev/null
    . "${helper_script_utils}"
    print_with_timestamp "Loaded manifest helper from utils: ${helper_script_utils}"
else
    print_with_timestamp "Manifest helper not found at ${helper_script_utils}; manifest writes will be skipped"
fi



# Define the folder path
folder_path="${output_path}"

print_with_timestamp "Combining and archiving HTML/PDF reports..."

# Build lists of expected HTML reports (only include ones that exist)
main_html_reports=(
    "${stats_out_path}/${study_name}_report_qc_stats.html"
    "${kinship_out_path}/${study_name}_report_kinship_analysis.html"
    # PCA report filename uses sanitized study_name (dots -> underscores) to match Step6
    "${pca_out_path}/${study_name}_report_pca.html"
    "${ancestry_out_path}/${study_name}_report_ancestry_predictions.html"
    "${ancestry_pca_out_path}/${study_name}_report_ancestry_specific_pca.html"
)

# Make archive HTML list the same as the main list (user requested main and archive to be the same)
archive_html_reports=("${main_html_reports[@]}")

if [ ! -d "${output_path}/Reports" ]; then
    mkdir -p "${output_path}/Reports"
fi

main_pdf_reports=()
archive_pdf_reports=()

# Convert existing main HTMLs to PDFs
for html in "${main_html_reports[@]}"; do
    if [ -f "$html" ]; then
        pdf="${output_path}/Reports/$(basename "${html%.html}").pdf"
        weasyprint "$html" "$pdf" || print_with_timestamp "Warning: weasyprint failed for $html"
        main_pdf_reports+=("$pdf")
    else
        print_with_timestamp "Skipping missing main HTML: $html"
    fi
done

# Use main_pdf_reports instead of undefined pdf_list
export TMPDIR=${temp_output_path}
combined_pdf="${output_path}/Reports/${study_name}_Combined_Report.pdf"
if [ ${#main_pdf_reports[@]} -gt 0 ]; then
    print_with_timestamp "Combining PDFs..."
    gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile="$combined_pdf" "${main_pdf_reports[@]}" 2>&1 | tee -a ${log_file}
    [ -f "$combined_pdf" ] && cp "$combined_pdf" "${output_path}/${study_name}_Combined_Report.pdf"

    # copy combined PDF to post-QC output for manifest
    if [ -f "${output_path}/${study_name}_Combined_Report.pdf" ]; then
        cp "${output_path}/${study_name}_Combined_Report.pdf" "${post_sample_variant_qc_out_path}"
        print_with_timestamp "Copied combined PDF report to post-QC output"
    else
        print_with_timestamp "No combined PDF report found to copy to post-QC output"
    fi

    print_with_timestamp "Combined report: $combined_pdf"
else
    print_with_timestamp "WARNING: No PDFs generated; skipping combined PDF."
fi

# Archive individual reports
individual_tar="${output_path}/Reports/${study_name}_individualReports.tar.gz"
if [ "$(ls -1 ${output_path}/Reports/*.pdf 2>/dev/null | wc -l)" -gt 0 ]; then
    print_with_timestamp "Archiving individual reports..."
    (cd "${output_path}/Reports" && tar -czf "$(basename "$individual_tar")" *.pdf)
    print_with_timestamp "Individual reports archive: $individual_tar"
fi

# Clean up intermediate PDF files (keep combined) - use main_pdf_reports
for pdf in "${main_pdf_reports[@]}"; do
    [ "$pdf" != "$combined_pdf" ] && rm -f "$pdf"
done

# Log the pre-clean up file list
print_with_timestamp "Logging pre-clean up file list..."
ls -lh "${folder_path}" > "${logs_out_path}/pre_cleanup_file_list.txt"

# Log the post-clean up file list
print_with_timestamp "Logging output files list..."
ls -lh "${post_qc_dir}" >> "${logs_out_path}/post_cleanup_file_list.txt"
ls -lh "${pre_qc_stats_dir}" >> "${logs_out_path}/post_cleanup_file_list.txt"
ls -lh "${post_qc_stats_dir}" >> "${logs_out_path}/post_cleanup_file_list.txt"
ls -lh "${pca_out_path}" >> "${logs_out_path}/post_cleanup_file_list.txt"
ls -lh "${kinship_out_path}" >> "${logs_out_path}/post_cleanup_file_list.txt"
ls -lh "${ancestry_out_path}" >> "${logs_out_path}/post_cleanup_file_list.txt"
ls -lh "${ancestry_pca_out_path}" >> "${logs_out_path}/post_cleanup_file_list.txt"
ls -lh "${logs_out_path}" >> "${logs_out_path}/post_cleanup_file_list.txt"
ls -lh "${output_path}/Reports" >> "${logs_out_path}/post_cleanup_file_list.txt"
ls -lh "${post_sample_variant_qc_out_path}" >> "${logs_out_path}/post_cleanup_file_list.txt"

# Remove temporary files
print_with_timestamp "Cleaning temporary directories..."
rm -rf "${pre_qc_dir}" "${temp_output_path}"

# Log final output structure
print_with_timestamp "Output files:" && ls -lh "${post_sample_variant_qc_out_path}/" 2>/dev/null || true

print_with_timestamp "Cleanup complete!"
