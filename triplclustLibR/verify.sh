#!/usr/bin/env bash
# Compare the C++ binary with the R package.
# Usage: ./triplclustLibR/verify.sh [file ...]
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
R_PACKAGE_ROOT="${PROJECT_ROOT}/triplclustLibR"

DATA_DIR="${DATA_DIR:-${PROJECT_ROOT}/data}"
RUNS="${RUNS:-1}"
MAX_SHOW="${MAX_SHOW:-10}"

CPP_BINARY="${PROJECT_ROOT}/build/triplclust"
R_SCRIPT="${R_PACKAGE_ROOT}/inst/scripts/use_triplclust.R"
PROFILES=(defaults dnn_scale absolute_distance dnn_gap)

TMP_DIR="$(mktemp -d)"

check_prerequisites() {
    if [[ ! -x "${CPP_BINARY}" ]]; then
        echo "ERROR: C++ binary not found or not executable: ${CPP_BINARY}" >&2
        exit 1
    fi
    if [[ ! -x "${R_SCRIPT}" ]]; then
        echo "ERROR: R script not found or not executable: ${R_SCRIPT}" >&2
        exit 1
    fi
    if ! [[ "${RUNS}" =~ ^[1-9][0-9]*$ ]]; then
        echo "ERROR: RUNS must be a positive integer" >&2
        exit 1
    fi
}

FILES=("$@")
if (( ${#FILES[@]} == 0 )); then
    shopt -s nullglob
    FILES=("${DATA_DIR}"/*.dat)
    shopt -u nullglob
fi
if (( ${#FILES[@]} == 0 )); then
    echo "ERROR: no input files found in ${DATA_DIR}" >&2
    exit 1
fi

ELAPSED_MS=0
time_cmd() {
    local out="$1"
    shift
    local start end rc
    start=$(date +%s%N)
    "$@" > "${out}" 2> "${out}.err"
    rc=$?
    end=$(date +%s%N)
    ELAPSED_MS=$(( (end - start) / 1000000 ))
    return "${rc}"
}

count_columns() {
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "${line//[[:space:]]/}" ]] && continue
        [[ "${line:0:1}" == "#" ]] && continue
        awk '{ print NF }' <<< "$line"
        return
    done < "$1"
    printf '0\n'
}

strip_comments() {
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "${line//[[:space:]]/}" ]] && continue
        [[ "${line:0:1}" == "#" ]] && continue
        printf '%s\n' "$line"
    done < "$1" > "$2"
}

profile_args() {
    local profile="$1"
    case "${profile}" in
        defaults)
            return 0
            ;;
        dnn_scale)
            printf '%s\n' -r 1.5dNN -s 0.25dNN -k 13 -n 3 -a 0.05 -m 4 -link complete
            ;;
        absolute_distance)
            printf '%s\n' -r 1.5 -s 0.25 -dmax 2.5 -k 13 -n 3 -a 0.05 -m 4 -link average
            ;;
        dnn_gap)
            printf '%s\n' -dmax 1.5dNN
            ;;
        *)
            return 1
            ;;
    esac
}

RESULT=""
DETAIL=""
CPP_MS=0
R_MS=0

verify_file() {
    local input="$1"
    local profile="$2"
    local name; name="$(basename "${input}")"
    local test_name="${name}.${profile}"
    local cpp_out="${TMP_DIR}/${test_name}.cpp.csv"
    local r_out="${TMP_DIR}/${test_name}.r.csv"
    local -a cpp_args=()

    RESULT=""; DETAIL=""; CPP_MS=0; R_MS=0

    if ! mapfile -t cpp_args < <(profile_args "${profile}"); then
        RESULT="ERROR"; DETAIL="unknown parameter profile: ${profile}"
        return
    fi

    if [[ ! -f "${input}" ]]; then
        RESULT="ERROR"; DETAIL="file not found"
        return
    fi

    local cols; cols="$(count_columns "${input}")"
    if [[ "${cols}" != "3" ]]; then
        RESULT="SKIP"; DETAIL="${cols:-0} columns (need 3)"
        return
    fi

    if ! time_cmd "${cpp_out}" "${CPP_BINARY}" "${input}" "${cpp_args[@]}"; then
        RESULT="ERROR"; DETAIL="C++ failed: $(head -n 1 "${cpp_out}.err")"
        return
    fi
    CPP_MS="${ELAPSED_MS}"

    if ! time_cmd "${r_out}" Rscript --vanilla --quiet "${R_SCRIPT}" "${input}" "--profile=${profile}"; then
        RESULT="ERROR"; DETAIL="R failed: $(grep -v '^$' "${r_out}.err" | tail -n 1)"
        return
    fi

    R_MS=$(grep -m1 '^# R-call' "${r_out}.err" | awk '{print int($3)}')
    if [[ -z "${R_MS}" ]]; then
        R_MS="${ELAPSED_MS}"
    fi

    if (( RUNS > 1 )); then
        local cpp_total="${CPP_MS}" r_total="${R_MS}" i
        for ((i = 2; i <= RUNS; i++)); do
            time_cmd "${TMP_DIR}/t.cpp" "${CPP_BINARY}" "${input}" "${cpp_args[@]}"; cpp_total=$((cpp_total + ELAPSED_MS))
            time_cmd "${TMP_DIR}/t.r" Rscript --vanilla --quiet "${R_SCRIPT}" "${input}" "--profile=${profile}"; r_total=$((r_total + ELAPSED_MS))
        done
        CPP_MS=$((cpp_total / RUNS))
        R_MS=$((r_total / RUNS))
    fi

    strip_comments "${cpp_out}" "${cpp_out}.cmp"
    strip_comments "${r_out}"   "${r_out}.cmp"

    local report="${TMP_DIR}/${test_name}.report"
    awk -F, -v limit="${MAX_SHOW}" '
        FILENAME == ARGV[1] { a[FNR] = $0; na = FNR; next }
        { b[FNR] = $0; nb = FNR }
        END {
            n = (na > nb) ? na : nb
            for (i = 1; i <= n; i++) {
                if (!(i in a) || !(i in b)) {
                    dd++; if (!first) first = i
                    if (shown++ < limit) printf "    line %d: row missing on one side\n", i
                    continue
                }
                split(a[i], x, ","); split(b[i], y, ",")
                kx = x[1] "," x[2] "," x[3]
                ky = y[1] "," y[2] "," y[3]
                if (kx != ky) {
                    dd++; if (!first) first = i
                    if (shown++ < limit) printf "    line %d: DATA  C++: %s | R: %s\n", i, a[i], b[i]
                    continue
                }
                if (x[4] != y[4]) {
                    ld++; if (!first) first = i
                    if (index(x[4], ";") || index(y[4], ";")) md++
                    if (shown++ < limit) printf "    line %d: LABEL %s  C++: %s | R: %s\n", i, kx, x[4], y[4]
                }
            }
            printf "SUMMARY %d %d %d %d %d %d\n", na, nb, dd + 0, ld + 0, md + 0, first + 0
        }' "${cpp_out}.cmp" "${r_out}.cmp" > "${report}"

    local cpp_rows r_rows data_diffs label_diffs multi_diffs first_div
    read -r _ cpp_rows r_rows data_diffs label_diffs multi_diffs first_div \
        <<< "$(grep '^SUMMARY' "${report}")"

    local cpp_only r_only
    cpp_only="$(LC_ALL=C comm -23 <(LC_ALL=C sort "${cpp_out}.cmp") <(LC_ALL=C sort "${r_out}.cmp") | wc -l)"
    r_only="$(LC_ALL=C comm -13 <(LC_ALL=C sort "${cpp_out}.cmp") <(LC_ALL=C sort "${r_out}.cmp") | wc -l)"

    if (( data_diffs == 0 && label_diffs == 0 && cpp_only == 0 && r_only == 0 )); then
        RESULT="OK"
        DETAIL="${cpp_rows} rows identical"
    else
        RESULT="FAIL"
        DETAIL="rows C++/R: ${cpp_rows}/${r_rows}, first divergence: line ${first_div}, data: ${data_diffs}, labels: ${label_diffs} (multi-label: ${multi_diffs}), C++-only: ${cpp_only}, R-only: ${r_only}"
        grep -v '^SUMMARY' "${report}" > "${TMP_DIR}/${test_name}.diffs"
    fi
}

check_prerequisites

n_ok=0; n_fail=0; n_error=0; n_skip=0

echo "Data files: ${#FILES[@]}   Profiles: ${#PROFILES[@]}   (RUNS=${RUNS})"
echo

for f in "${FILES[@]}"; do
    name="$(basename "${f}")"
    for profile in "${PROFILES[@]}"; do
        verify_file "${f}" "${profile}"

        case "${RESULT}" in
            OK)    n_ok=$((n_ok + 1)) ;;
            FAIL)  n_fail=$((n_fail + 1)) ;;
            ERROR) n_error=$((n_error + 1)) ;;
            SKIP)  n_skip=$((n_skip + 1)) ;;
        esac

        if [[ "${RESULT}" == "OK" || "${RESULT}" == "FAIL" ]]; then
            printf '%-6s %-36s %s  [C++ %d ms, R %d ms]\n' \
                "${RESULT}" "${name} (${profile})" "${DETAIL}" "${CPP_MS}" "${R_MS}"
        else
            printf '%-6s %-36s %s\n' \
                "${RESULT}" "${name} (${profile})" "${DETAIL}"
        fi

        if [[ "${RESULT}" == "FAIL" && -s "${TMP_DIR}/${name}.${profile}.diffs" ]]; then
            cat "${TMP_DIR}/${name}.${profile}.diffs"
        fi
    done
done

echo
echo "========================================"
echo "Verification result"
echo "========================================"
echo "OK      : ${n_ok}"
echo "FAIL    : ${n_fail}"
echo "ERROR   : ${n_error}"
echo "SKIPPED : ${n_skip}"
echo
echo "Temporary files: ${TMP_DIR}"
echo "  <name>.<profile>.cpp.csv / <name>.<profile>.r.csv  (raw outputs)"
echo "  <name>.<profile>.*.err                            (stderr of the runs)"
echo "========================================"

if (( n_fail > 0 || n_error > 0 )); then
    exit 1
fi
exit 0