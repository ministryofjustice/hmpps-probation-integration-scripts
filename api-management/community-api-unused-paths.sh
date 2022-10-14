#!/usr/bin/env bash

# AZURE_APP_GUID="the application GUID for Application Insights"
COMMUNITY_API_URL='https://community-api.test.probation.service.justice.gov.uk'

# Requires authentication with Azure Application Insights - API key?
# az login --use-device-code

# Paths used
QUERY="requests
         | where cloud_RoleName in ('community-api')
         | summarize count() by name"

# Run query for the the last week
paths_called=$(az monitor app-insights query --app "${AZURE_APP_GUID}" \
  --analytics-query "${QUERY}" \
  --offset 7d |
  jq -r '.tables[0].rows[][0] | sub("[^/]+"; "")' | sort | uniq)

# Find all defined Community API paths
paths_defined_secure=$(curl -s "${COMMUNITY_API_URL}/v2/api-docs?group=Community%20API" |
  jq -r '.paths | keys | .[]' |
  sort | uniq)

paths_defined_api=$(curl -s "${COMMUNITY_API_URL}/v2/api-docs?group=NewTech%20Private%20APIs" |
  jq -r '.paths | keys | .[]' |
  sort | uniq)

paths_defined="${paths_defined_api}${paths_defined_secure}"

# Find paths that are defined in the OpenAPI doc but haven't been called in the time period
grep -xvFf <(echo "$paths_called") <(echo "$paths_defined")
