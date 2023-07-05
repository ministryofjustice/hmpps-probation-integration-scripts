#!/usr/bin/env bash
##
## Replay messages from prod into preprod
##
## Usage:
##   APP_INSIGHTS_APPLICATION_GUID=... APP_INSIGHTS_API_KEY=... \
##   START_TIME=... END_TIME=... QUEUE_NAME=... ./replay-messages.sh
##
## Examples:
##   * Replay messages from the last 24 hours:
##       START_TIME='ago(1d)' END_TIME='now()' QUEUE_NAME=prison-case-notes-to-probation-queue ./replay-messages.sh
##
##   * Replay messages from a specific time window:
##       START_TIME='datetime("2023-07-05T16:00:00.000Z")' END_TIME='datetime("2023-07-05T17:00:00.000Z")' QUEUE_NAME=risk-assessment-scores-to-delius-queue ./replay-messages.sh
##
## How it works:
##   This script makes use of output from the hmpps-domain-events-logger service, which logs all domain event messages
##   to Azure Application Insights as custom events. Once we have the logged events, we send them to the target queue by
##   creating a pod in the preprod namespace and running the sqs-utils.py send script. This allows us to use the service
##   account to access the SQS queue.

set -eo pipefail
source common.sh
requires kubectl terraform jq

if [ -z "$START_TIME" ] \
|| [ -z "$END_TIME" ] \
|| [ -z "$QUEUE_NAME" ] \
|| [ -z "$APP_INSIGHTS_APPLICATION_GUID" ] \
|| [ -z "$APP_INSIGHTS_API_KEY" ]; then print_usage "$0"; exit 0; fi

namespace=hmpps-probation-integration-services-preprod
pod_name="${USER}-replay"

# Get event types for the target queue
echo "Getting event types for $QUEUE_NAME"
terraform_url="https://raw.githubusercontent.com/ministryofjustice/cloud-platform-environments/main/namespaces/live.cloud-platform.service.justice.gov.uk/$namespace/resources/$QUEUE_NAME.tf"
event_types_json=$(curl -sf "$terraform_url" | tr '\n' ' ' | grep -oP 'filter_policy = \Kjsonencode\(.+?\)' | head -n1 | terraform console | jq -c 'fromjson | .eventType | tojson')

# Get messages logged by hmpps-domain-event-logger
echo "Fetching events matching $event_types_json"
query="
let startTime=$START_TIME;
let endTime=$END_TIME;
let eventTypes=parse_json($event_types_json);
customEvents
  | where timestamp between(startTime .. endTime)
  | where cloud_RoleName in ('hmpps-domain-event-logger')
  | where set_has_element(eventTypes, tostring(customDimensions.eventType))
  | order by timestamp desc
  | project customDimensions.rawMessage
"
curl -sf --show-error -H "x-api-key: $APP_INSIGHTS_API_KEY" --data-urlencode "query=$query" --get "https://api.applicationinsights.io/v1/apps/${APP_INSIGHTS_APPLICATION_GUID}/query" \
  | jq -c '.tables[0].rows | flatten | .[] | fromjson' \
  > messages.jsonl
echo "Found $(wc -l < messages.jsonl) messages to replay"

# Start service pod in background
echo "Starting service pod '$pod_name'"
function delete_pod() { kubectl --namespace="$namespace" delete pod "$pod_name"; }
trap delete_pod SIGTERM SIGINT
kubectl run "$pod_name" \
  --namespace="$namespace" \
  --image=ghcr.io/ministryofjustice/hmpps-devops-tools:latest \
  --restart=Never --stdin=true --tty=true --rm \
  --overrides='{"spec":{"serviceAccount":"hmpps-probation-integration-services"}}' \
  -- sh & sleep 5
kubectl wait \
  --namespace="$namespace" \
  --for=condition=ready pod "$pod_name"

# Copy files to service pod
kubectl cp --namespace="$namespace" ./sqs-utils.py "$pod_name:/tmp/sqs-utils.py"
kubectl cp --namespace="$namespace" ./messages.jsonl "$pod_name:/tmp/messages.jsonl"

# Get queue url
queue_url=$(kubectl exec "$pod_name" --namespace="$namespace" -- aws sqs get-queue-url --queue-name "probation-integration-preprod-$QUEUE_NAME" --query QueueUrl --output text)
echo "Got queue URL: $queue_url"

# Run script to replay messages
kubectl exec "$pod_name" --namespace="$namespace" -- sh -c "python /tmp/sqs-utils.py send '$queue_url' < /tmp/messages.jsonl"

# Clean up
kubectl --namespace="$namespace" delete pod "$pod_name"