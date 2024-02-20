#!/usr/bin/env bash

# Read credentials from 1Password
IFS=', ' read -r -a app_insights_credentials <<<"$(
  op item get --vault 'HMPPS-Development-Team' 'Application Insights API - T3' --fields username,credential
)"

# Application Insights access
APP_INSIGHTS_APPLICATION_GUID=${app_insights_credentials[0]}
APP_INSIGHTS_API_KEY=${app_insights_credentials[1]}
APP_INSIGHTS_URL=https://api.applicationinsights.io/v1/apps

# HMPPS API Location
COMMUNITY_API_URL=https://community-api.probation.service.justice.gov.uk

# Find paths used in the last $DAYS
DAYS=90
QUERY="requests
        | where cloud_RoleName in ('community-api')
        | where timestamp between(startofday(ago(${DAYS}d)) .. endofday(now()))
        | summarize count() by name"

result=$(
  curl -s \
    --data-urlencode "query=${QUERY}" \
    --get "${APP_INSIGHTS_URL}/${APP_INSIGHTS_APPLICATION_GUID}"/query \
    --header "x-api-key: ${APP_INSIGHTS_API_KEY}"
)

paths_called=$(jq -r '.tables[0].rows[][0] | sub("[^/]+"; "")' <<<"$result" | sort | uniq)

# Find all defined Community API paths
paths_defined_secure=$(
  curl -s \
    --data-urlencode "group=Community API" \
    --get "${COMMUNITY_API_URL}"/v3/api-docs/Community%20API |
    jq -r '.paths | keys | .[]' | sort | uniq
)

paths_defined_api=$(
  curl -s \
    --data-urlencode "group=NewTech Private APIs" \
    --get "${COMMUNITY_API_URL}"/v3/api-docs/Community%20API |
    jq -r '.paths | keys | .[]' | sort | uniq
)

paths_defined="${paths_defined_api}${paths_defined_secure}"

# Find paths that are defined in the OpenAPI doc but haven't been called in the time period
grep -xvFf <(echo "$paths_called") <(echo "$paths_defined")
