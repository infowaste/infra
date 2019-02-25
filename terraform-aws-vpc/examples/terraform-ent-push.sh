#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <path_to_content_directory> <organization>/<workspace>"
  exit 0
fi

CONTENT_DIRECTORY=$1
ORG_NAME="$(cut -d'/' -f1 <<<"$2")"
WORKSPACE_NAME="$(cut -d'/' -f2 <<<"$2")"
UPLOAD_FILE_NAME="./content-$(date +%s).tar.gz"
tar -zcvf $UPLOAD_FILE_NAME $CONTENT_DIRECTORY
WORKSPACE_ID=($(curl \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  https://app.terraform.io/api/v2/organizations/$ORG_NAME/workspaces/$WORKSPACE_NAME \
  | jq -r '.data.id'))
echo '{"data":{"type":"configuration-version"}}' > ./create_config_version.json

UPLOAD_URL=($(curl \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @create_config_version.json \
  https://app.terraform.io/api/v2/workspaces/$WORKSPACE_ID/configuration-versions \
  | jq -r '.data.attributes."upload-url"'))
curl \
  --request PUT \
  -F "data=@$UPLOAD_FILE_NAME" \
  $UPLOAD_URL
rm $UPLOAD_FILE_NAME
rm ./create_config_version.json
