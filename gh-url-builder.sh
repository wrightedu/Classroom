#!/usr/bin/env bash
#
# generate_github_urls.sh
#
# Reads a roster CSV (Name,Email,Role,Username) and produces an output CSV
# with an added GitHubURL column:
#   https://github.com/<org>/<assignmentname>-<slug>-f26
#
# The slug is derived from the email's local part (before the @), with all
# punctuation stripped except hyphens, which are preserved.
#   e.g. duncan.66@wright.edu       -> duncan66
#        al-ramahi.4@wright.edu     -> al-ramahi4
#
# Usage:
#   ./generate_github_urls.sh input.csv [output.csv]
#
# You will be prompted for the assignment name and the GitHub org.

set -euo pipefail

INPUT_CSV="${1:-}"
OUTPUT_CSV="${2:-output.csv}"

if [[ -z "$INPUT_CSV" ]]; then
    echo "Usage: $0 input.csv [output.csv]" >&2
    exit 1
fi

if [[ ! -f "$INPUT_CSV" ]]; then
    echo "Error: input file '$INPUT_CSV' not found." >&2
    exit 1
fi

read -rp "Assignment name: " ASSIGNMENT_NAME
read -rp "GitHub org: " ORG_NAME

if [[ -z "$ASSIGNMENT_NAME" || -z "$ORG_NAME" ]]; then
    echo "Error: assignment name and org cannot be empty." >&2
    exit 1
fi

# Write header
echo "Name,Email,Role,Username,GitHubURL" > "$OUTPUT_CSV"

# Skip header line of input, strip any Windows CR (\r) line endings up front,
# then process each row
tail -n +2 "$INPUT_CSV" | tr -d '\r' | while IFS=',' read -r name email role username; do
    email="$(echo "$email" | xargs)"

    # Extract local part before @, strip all non-alphanumeric characters
    # except hyphens, which are preserved
    local_part="${email%%@*}"
    slug="$(echo "$local_part" | tr -cd -- '-A-Za-z0-9' | tr 'A-Z' 'a-z')"

    url="https://github.com/${ORG_NAME}/${ASSIGNMENT_NAME}-${slug}-f26"

    echo "${name},${email},${role},${username},${url}" >> "$OUTPUT_CSV"
done

echo "Done. Wrote $(($(wc -l < "$OUTPUT_CSV") - 1)) rows to $OUTPUT_CSV"
