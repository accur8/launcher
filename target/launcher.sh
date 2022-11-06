#!/bin/sh

mkdir -p ~/.a8
rm -f ~/.a8/repo.properties
echo "repo_url=${REPO_URL}" >> ~/.a8/repo.properties
echo "repo_realm=${REPO_REALM}" >> ~/.a8/repo.properties
echo "repo_user=${REPO_USER}" >> ~/.a8/repo.properties
echo "repo_password=${REPO_PASSWORD}" >> ~/.a8/repo.properties

rm -f a8-launcher.json
echo "{" >> a8-launcher.json
echo "  \"kind\": \"${KIND}\"," >> a8-launcher.json
echo "  \"organization\": \"${ORGANIZATION}\"," >> a8-launcher.json
echo "  \"artifact\": \"${ARTIFACT}\"," >> a8-launcher.json
echo "  \"branch\": \"${BRANCH}\"," >> a8-launcher.json
echo "  \"mainClass\": \"${MAIN_CLASS}\"" >> a8-launcher.json
echo "}" >> a8-launcher.json

python3 a8-launcher