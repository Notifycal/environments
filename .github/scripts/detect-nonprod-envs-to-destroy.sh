#!/usr/bin/env bash

set -euo pipefail

log_tab() {
  printf "%-25s %s\n" "$1" "$2"
}

print_json_array() {
  local json="$1"
  echo "$json" | jq -r '. | join(", ")'
}

FIND_TOOL="find"
if [[ $OSTYPE == 'darwin'* ]]; then
  FIND_TOOL="gfind"
fi

if [[ -z "${FILTERS_FILE:-}" ]]; then
  echo "FILTERS_FILE is required but not set"
  exit 1
fi

ALL_NON_PROD_ENVS=$(yq -o=json -I0 'keys | map(select(. != "prod*"))' "${FILTERS_FILE}")
PROTECTED_ENVS=$("${FIND_TOOL}" "${KEEP_ENVS_DIR}" -maxdepth 1 -type f ! -name .gitkeep -printf "%f\n" 2>/dev/null | jq -R . | jq -crs .)

echo "Starting environment detection..."
echo
log_tab "Filters file:" "${FILTERS_FILE}"

if [[ -v TARGET_ENV && -n "$TARGET_ENV" ]]; then
  log_tab "Target environments:" "$TARGET_ENV"
else
  log_tab "Target environments:" "[all] -> $(print_json_array "${ALL_NON_PROD_ENVS}")"
fi

log_tab "Non-prod environments:" "$(print_json_array "${ALL_NON_PROD_ENVS}")"
log_tab "Protected environments:" "$(print_json_array "${PROTECTED_ENVS}")"
echo

echo "Check if we have a target environment set for destroy"
if [[ -n "${TARGET_ENV:-}" ]]; then
  # Skip non dev* environments for safety
  if [[ "${TARGET_ENV}" == "prod" ]]; then
    echo "Invalid environment '${TARGET_ENV}'. Only non-prod environments can be destroyed." | tee -a "${GITHUB_STEP_SUMMARY}"
    exit 1
  fi

  # Skip environment if a file with its name exists in $KEEP_ENVS_DIR
  if [[ -f "$KEEP_ENVS_DIR/$TARGET_ENV" ]]; then
    echo "Environment '${TARGET_ENV}' is protected and will be skipped." | tee -a "${GITHUB_STEP_SUMMARY}"
    echo "envs=[]" | tee -a "${GITHUB_OUTPUT}"
    exit 0
  fi

  # Mark TARGET_ENV for destroy
  echo "envs=[\"${TARGET_ENV}\"]" | tee -a "${GITHUB_OUTPUT}"
  exit 0
fi

FINAL_ENVS=$(jq -rcn --argjson all "${ALL_NON_PROD_ENVS}" --argjson protected "${PROTECTED_ENVS}" '$all - $protected')
echo "Destroying all unprotected non-prod environments"
echo "envs=${FINAL_ENVS}" | tee -a "${GITHUB_OUTPUT}"

exit 0
