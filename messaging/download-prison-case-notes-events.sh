#!/usr/bin/env bash

# Application Insights Credentials
# APP_INSIGHTS_APPLICATION_GUID=
# APP_INSIGHTS_API_KEY=
APP_INSIGHTS_URL=https://api.applicationinsights.io/v1/apps

# Find prison case notes domain events in the last ${DAYS}
DAYS=1
QUERY="customEvents
       | where timestamp between(startofday(ago(${DAYS}d)) .. endofday(now()))
       | where cloud_RoleName == 'hmpps-domain-event-logger'
       | where name has 'prison.case-note.published'
       | where customDimensions['additionalInformation.caseNoteType'] in ('PRISON-RELEASE','TRANSFER-FROMTOL','GEN-OSE', 'ALERT-ACTIVE', 'ALERT-INACTIVE')
       or customDimensions['additionalInformation.caseNoteType'] has 'OMIC'
       or customDimensions['additionalInformation.caseNoteType'] has 'KA'
       | project timestamp, customDimensions"

result=$(
  curl -s \
    --data-urlencode "query=${QUERY}" \
    --get "${APP_INSIGHTS_URL}/${APP_INSIGHTS_APPLICATION_GUID}"/query \
    --header "x-api-key: ${APP_INSIGHTS_API_KEY}"
)

jq -r '.tables[0].rows[][0]' <<<"$result"
