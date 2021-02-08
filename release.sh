#!/bin/bash
set -ex

OWNER=aikw
REPO=test
GITHUB_TOKEN=`cat ./secrets/secrets.json | jq -r .github_token`
VERSION=`node -e '\
const p=require("./package.json");\
const ver=p.version;\
const r=p.ricohLsSdk;\
const pre=r&&r.preRelease?"-"+r.preRelease:"";\
console.log(ver+pre)'`
ASSET_FILE=ricoh-ls-sdk-${VERSION}
MIME=application/zip
HASH=`echo $VERSION | sed 's/\.//g'`
DESCRIPTION="CHANGE LOG: https://github.com/${OWNER}/${REPO}/blob/master/README.md#v${HASH}"

API_ENDPOINT="https://api.github.com/repos/${OWNER}/${REPO}"
UPLOAD_ENDPOINT="https://uploads.github.com/repos/${OWNER}/${REPO}"
ACCEPT_HEADER="Accept: application/vnd.github.v3+json"
TOKEN_HEADER="Authorization: token ${GITHUB_TOKEN}"

echo "now release v${VERSION}"

echo "build ${ASSET_FILE}"
rm -rf ./build/ricoh-ls-sdk-*
mkdir  ./build/ricoh-ls-sdk-${VERSION}
cp     src/ricoh-ls-sdk.js     ./build/ricoh-ls-sdk-${VERSION}/ricoh-ls-sdk.js
cp     src/ricoh-ls-sdk.d.ts   ./build/ricoh-ls-sdk-${VERSION}/ricoh-ls-sdk.d.ts
cd     ./build
zip -r $ASSET_FILE.zip ricoh-ls-sdk-${VERSION}
cd     ..

echo "creatting new release for ${VERSION}"
REPLY=$(curl \
  -H "${ACCEPT_HEADER}" \
  -H "${TOKEN_HEADER}" \
  -d "{\"tag_name\": \"${VERSION}\", \"name\": \"${VERSION}\", \"body\": \"${DESCRIPTION}\"}" \
  "${API_ENDPOINT}/releases" \
  )


echo "upload assets to release"
RELEASE_ID=$(echo "${REPLY}" | jq .id)
RELEASE_URL="https://uploads.github.com/repos/${OWNER}/${REPO}/releases/${RELEASE_ID}/assets"
curl \
  -H "${ACCEPT_HEADER}" \
  -H "${TOKEN_HEADER}" \
  -H "Content-Type: ${MIME}" \
  --data-binary "@./build/${ASSET_FILE}.zip" \
  "${RELEASE_URL}?name=${ASSET_FILE}.zip"
