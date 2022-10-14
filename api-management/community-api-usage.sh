#!/usr/bin/env bash

# AZURE_APP_GUID="the application GUID for Application Insights"
COMMUNITY_API_URL=

# Requires authentication with Azure Application Insights - API key?
# az login --use-device-code

# Paths used
QUERY="requests
         | where cloud_RoleName in ('community-api')
         | where url has '/secure/staff' or url has '/secure/teams'
         | summarize count() by name, tostring(customDimensions.clientId)"

# Run query for the the last week
az monitor app-insights query --app "${AZURE_APP_GUID}" \
  --analytics-query "${QUERY}" \
  --offset 7d |
  jq -r '.tables[0].rows[] | @csv'
