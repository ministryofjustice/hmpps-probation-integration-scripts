#!/usr/bin/env bash
##
## Output SNS messages for correcting Contact outcomes in Delius based on Sentry events
##
## Usage:
##   SENTRY_API_KEY=... ISSUE_ID=... \
##   ./get-sentry-events.sh | ./reconstruct-messages.sh | python3 ../sqs-utils.py send "$SQS_QUEUE_URL" | tee send-output.log
##
set -eo pipefail
source ../common.sh

cat "${1:-/dev/stdin}" \
| jq '.[].context."async-event"' \
| sed -E 's/"ActionPlanAppointmentEvent\(type=(.+?), deliverySessionId=(.+?), detailUrl='"'"'(.+?\/referral\/([^\/]+?)\/sessions\/([^\/]+?).+?)'"'"', source=(.+?)\)"/\4 \5 \3/' \
| while read -r referralId sessionNumber detailUrl; do
  auth="$(echo -n $(kubectl -n hmpps-probation-integration-services-prod get secret refer-and-monitor-and-delius-client-credentials -o yaml | yq '.data.CLIENT_ID' | base64 -d):$(kubectl -n hmpps-probation-integration-services-prod get secret refer-and-monitor-and-delius-client-credentials -o yaml | yq '.data.CLIENT_SECRET' | base64 -d) | base64 -w0)"
  HMPPS_AUTH_TOKEN=$(kubectl -n hmpps-probation-integration-services-prod exec deployment/refer-and-monitor-and-delius -- sh -c "wget --header 'Authorization: Basic $auth' --post-data '' -O - 'https://sign-in.hmpps.service.justice.gov.uk/auth/oauth/token?grant_type=client_credentials' 2>/dev/null" | jq -r '.access_token' | tr -d '\n')
  export HMPPS_AUTH_TOKEN
  session=$(kubectl -n hmpps-probation-integration-services-prod exec deployment/person-search-index-from-delius -- curl --silent --fail --retry 3 --output - -H "Authorization: Bearer $HMPPS_AUTH_TOKEN" "https://hmpps-interventions-service.apps.live-1.cloud-platform.service.justice.gov.uk/referral/$referralId/sessions/$sessionNumber" \
            | jq '. | {
              deliusAppointmentId: .deliusAppointmentId,
              referralProbationUserURL: ("https://refer-monitor-intervention.service.justice.gov.uk/probation-practitioner/referrals/'"$referralId"'/session/'"$sessionNumber"'/appointment/" + ((.deliusAppointmentId // "0")|tostring) + "/post-session-feedback")
            }')
  referral=$(kubectl -n hmpps-probation-integration-services-prod exec deployment/person-search-index-from-delius -- curl --silent --fail --retry 3 --output - -H "Authorization: Bearer $HMPPS_AUTH_TOKEN" "https://hmpps-interventions-service.apps.live-1.cloud-platform.service.justice.gov.uk/sent-referral/$referralId" \
             | jq '. | {
               referralId: .id,
               referralReference: .referenceNumber,
               contractTypeName: .referral.contractTypeName,
               primeProviderName: .referral.serviceProvider.name,
               crn: .referral.serviceUser.crn
             }')
  echo -e "$session\n$referral" | jq -s '.[0] * .[1]' | jq '{
    "eventType": "intervention.session-appointment.session-feedback-submitted",
    "version": 1,
    "description": "Session feedback submitted for a session appointment",
    "detailUrl": "'"$detailUrl"'",
    "occurredAt": "'"$(TZ=UTC date '+%Y-%m-%dT%H:%M:%S.%3NZ')"'",
    "personReference": {
      "identifiers": [{"type": "CRN", "value": .crn}]
    },
    "additionalInformation": .
  }' | \
  jq -c '{
    "Type": "Notification",
    "MessageId": "00000000-0000-0000-0000-000000000000",
    "TopicArn": "arn:aws:sns:eu-west-2:754256621582:cloud-platform-Digital-Prison-Services-e29fb030a51b3576dd645aa5e460e573",
    "Message": . | tojson,
    "Timestamp": .occurredAt,
    "MessageAttributes": {
      "eventType": {"Type": "String", "Value": .eventType}
    }
  }'
done
