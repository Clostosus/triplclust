#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
R_PACKAGE_ROOT="${PROJECT_ROOT}/triplclustLibR"

INPUT="${1:-${PROJECT_ROOT}/test.dat}"
RUNS="${RUNS:-5}"

CPP_BINARY="${PROJECT_ROOT}/build/triplclust"
R_SCRIPT="${R_PACKAGE_ROOT}/tests/use_triplclust.R"

TMP_DIR="$(mktemp -d)"

CPP_OUT="${TMP_DIR}/cpp.csv"
R_OUT="${TMP_DIR}/r.csv"

echo "Temporary files:"
echo "  C++: ${CPP_OUT}"
echo "  R:   ${R_OUT}"

###############################################################################
# Checks
###############################################################################

if [[ ! -x "${CPP_BINARY}" ]]; then
    echo "ERROR: C++ binary not found or not executable:"
    echo "  ${CPP_BINARY}"
    exit 1
fi

if [[ ! -x "${R_SCRIPT}" ]]; then
    echo "ERROR: R script not found or not executable:"
    echo "  ${R_SCRIPT}"
    exit 1
fi

if [[ ! -f "${INPUT}" ]]; then
    echo "ERROR: Input file not found:"
    echo "  ${INPUT}"
    exit 1
fi

if ! [[ "${RUNS}" =~ ^[1-9][0-9]*$ ]]; then
    echo "ERROR: RUNS must be a positive integer"
    exit 1
fi

###############################################################################
# Timing
###############################################################################

measure_cpp() {
    local output="$1"
    local start
    local end

    start=$(date +%s%N)

    "${CPP_BINARY}" "${INPUT}" > "${output}"

    end=$(date +%s%N)

    echo $(( (end - start) / 1000000 ))
}

measure_r() {
    local output="$1"
    local start
    local end

    start=$(date +%s%N)

    "${R_SCRIPT}" "${INPUT}" > "${output}"

    end=$(date +%s%N)

    echo $(( (end - start) / 1000000 ))
}

###############################################################################
# First run — also used for correctness
###############################################################################

echo
echo "=== Running C++ binary ==="

CPP_TIME_MS="$(measure_cpp "${CPP_OUT}")"

echo "C++ runtime: ${CPP_TIME_MS} ms"

echo
echo "=== Running R implementation ==="

R_TIME_MS="$(measure_r "${R_OUT}")"

echo "R runtime:   ${R_TIME_MS} ms"

###############################################################################
# Parse and compare rows
###############################################################################

echo
echo "=== Comparing output ==="

divergence_line=0
data_differences=0
label_differences=0
multilabel_differences=0

cpp_rows=0
r_rows=0

###############################################################################
# Read both files into arrays.
#
# Comments are ignored.
###############################################################################

declare -a CPP_LINES
declare -a R_LINES

while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ "${line}" == \#* ]] && continue
    [[ -z "${line}" ]] && continue

    CPP_LINES+=("${line}")
done < "${CPP_OUT}"

while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ "${line}" == \#* ]] && continue
    [[ -z "${line}" ]] && continue

    R_LINES+=("${line}")
done < "${R_OUT}"

cpp_rows="${#CPP_LINES[@]}"
r_rows="${#R_LINES[@]}"

max_rows=$(( cpp_rows > r_rows ? cpp_rows : r_rows ))

###############################################################################
# Compare rows
###############################################################################

for ((i = 0; i < max_rows; i++)); do

    line_no=$((i + 1))

    cpp_line="${CPP_LINES[$i]:-}"
    r_line="${R_LINES[$i]:-}"

    if [[ -z "${cpp_line}" ]]; then
        if (( divergence_line == 0 )); then
            divergence_line="${line_no}"
        fi

        echo
        echo "Line ${line_no}: C++ has no row, R has:"
        echo "  R: ${r_line}"

        data_differences=$((data_differences + 1))
        continue
    fi

    if [[ -z "${r_line}" ]]; then
        if (( divergence_line == 0 )); then
            divergence_line="${line_no}"
        fi

        echo
        echo "Line ${line_no}: R has no row, C++ has:"
        echo "  C++: ${cpp_line}"

        data_differences=$((data_differences + 1))
        continue
    fi

    IFS=',' read -r cpp_x cpp_y cpp_z cpp_labels <<< "${cpp_line}"
    IFS=',' read -r r_x r_y r_z r_labels <<< "${r_line}"

    cpp_data="${cpp_x},${cpp_y},${cpp_z}"
    r_data="${r_x},${r_y},${r_z}"

    # Compare the first three columns.
    if [[ "${cpp_data}" != "${r_data}" ]]; then

        if (( divergence_line == 0 )); then
            divergence_line="${line_no}"
        fi

        data_differences=$((data_differences + 1))

        echo
        echo "Line ${line_no}: DATA DIFFERENCE"
        echo "  C++: ${cpp_line}"
        echo "  R:   ${r_line}"

        continue
    fi

    # Same coordinates/data, compare labels.
    if [[ "${cpp_labels}" != "${r_labels}" ]]; then

        if (( divergence_line == 0 )); then
            divergence_line="${line_no}"
        fi

        label_differences=$((label_differences + 1))

        # Detect multi-label output.
        if [[ "${cpp_labels}" == *";"* ||
              "${r_labels}" == *";"* ]]; then
            multilabel_differences=$((multilabel_differences + 1))
        fi

        echo
        echo "Line ${line_no}: LABEL DIFFERENCE"
        echo "  Data: ${cpp_data}"
        echo "  C++ labels: ${cpp_labels}"
        echo "  R labels:   ${r_labels}"
    fi
done

###############################################################################
# Hash comparison
#
# Hash complete rows, but preserve multiplicity.
###############################################################################

echo
echo "=== Hashing rows ==="

declare -A CPP_HASHES
declare -A R_HASHES

while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ "${line}" == \#* ]] && continue
    [[ -z "${line}" ]] && continue

    hash="$(printf '%s' "${line}" | sha256sum | cut -d' ' -f1)"
    CPP_HASHES["${hash}"]=$(( ${CPP_HASHES["${hash}"]:-0} + 1 ))
done < "${CPP_OUT}"

while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ "${line}" == \#* ]] && continue
    [[ -z "${line}" ]] && continue

    hash="$(printf '%s' "${line}" | sha256sum | cut -d' ' -f1)"
    R_HASHES["${hash}"]=$(( ${R_HASHES["${hash}"]:-0} + 1 ))
done < "${R_OUT}"

cpp_only=0
r_only=0

for hash in "${!CPP_HASHES[@]}"; do
    cpp_count="${CPP_HASHES["${hash}"]}"
    r_count="${R_HASHES["${hash}"]:-0}"

    if (( cpp_count > r_count )); then
        cpp_only=$((cpp_only + cpp_count - r_count))
    fi
done

for hash in "${!R_HASHES[@]}"; do
    r_count="${R_HASHES["${hash}"]}"
    cpp_count="${CPP_HASHES["${hash}"]:-0}"

    if (( r_count > cpp_count )); then
        r_only=$((r_only + r_count - cpp_count))
    fi
done

difference_count=$((cpp_only + r_only))

###############################################################################
# Timing
###############################################################################

echo
echo "=== Timing (${RUNS} runs) ==="

cpp_total=0
r_total=0

for ((i = 1; i <= RUNS; i++)); do
    time="$(measure_cpp "${TMP_DIR}/cpp_${i}.csv")"
    cpp_total=$((cpp_total + time))
done

for ((i = 1; i <= RUNS; i++)); do
    time="$(measure_r "${TMP_DIR}/r_${i}.csv")"
    r_total=$((r_total + time))
done

cpp_avg=$((cpp_total / RUNS))
r_avg=$((r_total / RUNS))

###############################################################################
# Result
###############################################################################

echo
echo "========================================"
echo "Verification result"
echo "========================================"

echo "C++ rows          : ${cpp_rows}"
echo "R rows            : ${r_rows}"

if (( divergence_line == 0 )); then
    echo "First divergence  : none"
else
    echo "First divergence  : line ${divergence_line}"
fi

echo
echo "Data differences  : ${data_differences}"
echo "Label differences : ${label_differences}"
echo "Multi-label diffs : ${multilabel_differences}"

echo
echo "Exact row differences"
echo "C++-only rows     : ${cpp_only}"
echo "R-only rows       : ${r_only}"
echo "Total differences : ${difference_count}"

echo
echo "Runtime"
echo "----------------------------------------"
echo "C++ first run     : ${CPP_TIME_MS} ms"
echo "R first run       : ${R_TIME_MS} ms"
echo "C++ average       : ${cpp_avg} ms"
echo "R average         : ${r_avg} ms"

if (( cpp_avg > 0 )); then
    printf "R/C++ ratio       : %.2fx\n" \
        "$(awk "BEGIN { print ${r_avg} / ${cpp_avg} }")"
fi

echo
echo "Temporary files"
echo "----------------------------------------"
echo "C++ output        : ${CPP_OUT}"
echo "R output          : ${R_OUT}"
echo "========================================"

###############################################################################
# Exit status
###############################################################################

if (( difference_count > 0 )); then
    exit 1
fi

exit 0
