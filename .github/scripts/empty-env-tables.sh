#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <environment>"
  echo "Example: $0 dev"
  exit 1
fi

ENVIRONMENT="$1"

delete_all_items() {
  local table_name="$1"

  echo "Retrieving key schema for $table_name..."
  local key_schema_json
  key_schema_json=$(aws dynamodb describe-table \
    --table-name "$table_name" \
    --query "Table.KeySchema" \
    --output json)

  # Extract key attribute names (partition + sort key if any)
  local pk_name sk_name
  pk_name=$(echo "$key_schema_json" | jq -r '.[] | select(.KeyType=="HASH") | .AttributeName')
  sk_name=$(echo "$key_schema_json" | jq -r '.[] | select(.KeyType=="RANGE") | .AttributeName')

  echo "Partition key: $pk_name${sk_name:+, sort key: $sk_name}"

  # Build projection expression
  local projection_expr="$pk_name"
  if [[ -n "$sk_name" && "$sk_name" != "null" ]]; then
    projection_expr="$pk_name,$sk_name"
  fi

  echo "Scanning items from $table_name..."
  local items_json
  items_json=$(aws dynamodb scan \
    --table-name "$table_name" \
    --projection-expression "$projection_expr" \
    --query "Items" \
    --output json)

  echo "$items_json" | jq -c '.[]' | while read -r row; do
    # Extract PK and SK values with their types dynamically
    local pk_value sk_value pk_type sk_type
    pk_type=$(echo "$row" | jq -r --arg pk "$pk_name" ".\"$pk_name\" | keys[0]")
    pk_value=$(echo "$row" | jq -r --arg pk "$pk_name" ".\"$pk_name\"[\"$pk_type\"]")

    local key_json
    if [[ -n "$sk_name" && "$sk_name" != "null" ]]; then
      sk_type=$(echo "$row" | jq -r --arg sk "$sk_name" ".\"$sk_name\" | keys[0]")
      sk_value=$(echo "$row" | jq -r --arg sk "$sk_name" ".\"$sk_name\"[\"$sk_type\"]")
      key_json=$(jq -n \
        --arg pkname "$pk_name" --arg pkval "$pk_value" --arg pktype "$pk_type" \
        --arg skname "$sk_name" --arg skval "$sk_value" --arg sktype "$sk_type" \
        '{($pkname): {($pktype): $pkval}, ($skname): {($sktype): $skval}}')
    else
      key_json=$(jq -n \
        --arg pkname "$pk_name" --arg pkval "$pk_value" --arg pktype "$pk_type" \
        '{($pkname): {($pktype): $pkval}}')
    fi

    echo "Deleting item with key: $key_json"
    # aws dynamodb delete-item \
    #   --table-name "$table_name" \
    #   --key "$key_json" >/dev/null
  done

  echo "Table $table_name emptied."
}

# Exclude tofu tables
TABLES=$(aws resourcegroupstaggingapi get-resources \
  --resource-type-filters dynamodb:table \
  --tag-filters "Key=Environment,Values=$ENVIRONMENT" \
  --query "ResourceTagMappingList[].ResourceARN" \
  --output json |
  jq -r '.[] | select(test("tofu")|not) | split("/")[-1]')

if [[ -z "$TABLES" ]]; then
  echo "No DynamoDB tables found with Environment=$ENVIRONMENT excluding 'tofu'."
  exit 0
fi

for TABLE in $TABLES; do
  echo -e "\n=== Emptying table $TABLE ==="
  delete_all_items "$TABLE"
done

echo "Done."
