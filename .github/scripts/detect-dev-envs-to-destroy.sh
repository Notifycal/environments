#!/usr/bin/env bash

set -euo pipefail

echo "Starting environment detection"
echo "TARGET_ENV: ${TARGET_ENV}"
echo "FILTERS_FILE: ${FILTERS_FILE}"

echo "Check if we have a target environment set for destroy"
if [[ "${TARGET_ENV}" != "" ]]; then
  if [[ "${TARGET_ENV}" != dev* ]]; then
    echo "Invalid environment. This only supports destroying \`dev*\` environments." >> "${GITHUB_STEP_SUMMARY}"
    exit 1
  fi

  echo "envs=[\"${TARGET_ENV}\"]" >> "${GITHUB_OUTPUT}"
  exit 0
fi

echo "Destroying all dev* environments"
ENV_KEYS=$(yq -o=json -I0 'keys | map(select(. == "dev*"))' "${FILTERS_FILE}")
echo "envs=${ENV_KEYS}" >> "${GITHUB_OUTPUT}"

exit 0
