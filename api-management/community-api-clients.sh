#!/usr/bin/env bash

# Read credentials from 1Password
IFS=', ' read -r -a app_insights_credentials <<<"$(
  op item get --vault 'HMPPS-Development-Team' 'Application Insights API - T3' --fields username,credential
)"

# Application Insights access
APP_INSIGHTS_APPLICATION_GUID=${app_insights_credentials[0]}
APP_INSIGHTS_API_KEY=${app_insights_credentials[1]}
APP_INSIGHTS_URL=https://api.applicationinsights.io/v1/apps

# Path usage by client
QUERY="requests
         | where cloud_RoleName in ('community-api')
         | where timestamp between(startofday(ago(7d)) .. endofday(now()))
         | summarize count() by name, tostring(customDimensions.clientId)"

result=$(
  curl -s \
    --data-urlencode "query=${QUERY}" \
    --get "${APP_INSIGHTS_URL}/${APP_INSIGHTS_APPLICATION_GUID}/query" \
    --header "x-api-key: ${APP_INSIGHTS_API_KEY}"
)

jq -r '.tables[0].rows[] | @csv' <<<"$result"
