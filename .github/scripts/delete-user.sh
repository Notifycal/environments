#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <environment> <user-email>"
  echo "Example: $0 dev notifycal@gmail.com"
  exit 1
fi

ENVIRONMENT=$1
USER_EMAIL=$2

USERS_TABLE="Users-${ENVIRONMENT}"
EMAIL_ATTR="Email"
PK_ATTR="UserId"

echo "Searching for ${PK_ATTR} in table '$USERS_TABLE' with $EMAIL_ATTR='$USER_EMAIL'..."

SCAN_OUTPUT=$(aws dynamodb scan \
  --table-name "${USERS_TABLE}" \
  --filter-expression "#email = :emailval" \
  --expression-attribute-names "$(jq -n --arg email "$EMAIL_ATTR" '{("#email"): $email}')" \
  --expression-attribute-values "$(jq -n --arg email "$USER_EMAIL" '{":emailval": {"S": $email}}')" \
  --projection-expression "$PK_ATTR" \
  --output json)

USER_COUNT=$(echo "${SCAN_OUTPUT}" | jq '.Items | length')

if [ "${USER_COUNT}" -eq 0 ]; then
  echo "No user found with $EMAIL_ATTR='$USER_EMAIL'. Nothing to do."
  exit 1
elif [ "${USER_COUNT}" -gt 1 ]; then
  echo "Found $USER_COUNT users with $EMAIL_ATTR='$USER_EMAIL'. Aborting (ambiguous)."
  echo "${SCAN_OUTPUT}" | jq '.'
  exit 1
fi

USER_ID=$(echo "${SCAN_OUTPUT}" | jq -r ".Items[].$PK_ATTR.S")

echo -e "${PK_ATTR} found for '${USER_EMAIL}': ${USER_ID}.\nProceeding to delete it..."

aws dynamodb delete-item \
  --table-name "${USERS_TABLE}" \
  --key "$(jq -n -rc --arg pk "${USER_ID}" --arg pk_attr "${PK_ATTR}" '{($pk_attr): {"S": $pk}}')"

echo "${PK_ATTR}='${USER_ID}' successfully deleted."
