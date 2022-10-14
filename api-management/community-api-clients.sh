#!/usr/bin/env bash

# AZURE_APP_GUID="the application GUID for Application Insights"

# Require authentication with Azure Application Insights
# az login --use-device-code

# Path usage by client
QUERY="requests
         | where cloud_RoleName in ('community-api')
         | summarize count() by name, tostring(customDimensions.clientId)"

az monitor app-insights query --app "${AZURE_APP_GUID}" \
  --analytics-query "${QUERY}" \
  --offset 7d |
  jq -r '.tables[0].rows[] | @csv'
