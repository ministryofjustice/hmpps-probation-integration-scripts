#!/usr/bin/env bash

# Application Insights Credentials
AZURE_APP_GUID=
API_KEY=
APPINSIGHTS_URL=https://api.applicationinsights.io/v1/apps

# HMPPS API Location
COMMUNITY_API_URL=https://community-api.test.probation.service.justice.gov.uk

# Find paths used in the last $DAYS
DAYS=30
QUERY="requests
        | where cloud_RoleName in ('community-api')
        | where timestamp between(startofday(ago(${DAYS}d)) .. endofday(now()))
        | summarize count() by name"

result=$(
  curl -s \
    --data-urlencode "query=${QUERY}" \
    --get ${APPINSIGHTS_URL}/${AZURE_APP_GUID}/query \
    --header "x-api-key: ${API_KEY}"
)

paths_called=$(jq -r '.tables[0].rows[][0] | sub("[^/]+"; "")' <<<"$result" | sort | uniq)

# Find all defined Community API paths
paths_defined_secure=$(
  curl -s \
    --data-urlencode "group=Community API" \
    --get ${COMMUNITY_API_URL}/v2/api-docs |
    jq -r '.paths | keys | .[]' | sort | uniq
)

paths_defined_api=$(
  curl -s \
    --data-urlencode "group=NewTech Private APIs" \
    --get ${COMMUNITY_API_URL}/v2/api-docs |
    jq -r '.paths | keys | .[]' | sort | uniq
)

paths_defined="${paths_defined_api}${paths_defined_secure}"

# Find paths that are defined in the OpenAPI doc but haven't been called in the time period
grep -xvFf <(echo "$paths_called") <(echo "$paths_defined")
