#!/usr/bin/env bash

# APP_INSIGHTS_APPLICATION_GUID=
# APP_INSIGHTS_API_KEY=
APP_INSIGHTS_URL=https://api.applicationinsights.io/v1/apps

# Requires authentication with Azure Application Insights - API key?
# az login --use-device-code

# Paths used
QUERY="requests
         | where cloud_RoleName in ('community-api')
         | where timestamp between(startofday(ago(7d)) .. endofday(now()))
         | summarize count() by name, tostring(customDimensions.clientId)"

result=$(
  curl -s \
    --data-urlencode "query=${QUERY}" \
    --get ${APP_INSIGHTS_URL}/${APP_INSIGHTS_APPLICATION_GUID}/query \
    --header "x-api-key: ${APP_INSIGHTS_API_KEY}"
)

jq -r '.tables[0].rows[] | @csv' <<<"$result"
