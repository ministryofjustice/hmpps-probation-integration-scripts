#!/usr/bin/env bash
##
## Export standard AWS credentials from a Kubernetes secret
##
## Usage:
##   NAMESPACE=... SECRET_NAME=... source aws-creds-from-k8s.sh
##
## This script can be used to quickly setup credentials for running aws cli commands, e.g.
##   # Get the number of messages on an SQS queue
##   NAMESPACE=prison-to-probation-update-dev SECRET_NAME=sqs-hmpps-domain-events source aws-creds-from-k8s.sh && \
##   aws sqs get-queue-attributes --attribute-names ApproximateNumberOfMessages --queue-url "${SQS_QUEUE_URL}" --region eu-west-2
##
##   # Purge a DLQ
##   NAMESPACE=prison-to-probation-update-dev SECRET_NAME=sqs-hmpps-domain-events-dlq source aws-creds-from-k8s.sh && \
##   aws sqs purge-queue --queue-url "${SQS_QUEUE_URL}" --region eu-west-2
##

set -eo pipefail
source common.sh
requires kubectl

if [ -z "$NAMESPACE" ] || [ -z "$SECRET_NAME" ]; then print_usage "$0"; return 0; fi

secret=$(kubectl -n "$NAMESPACE" get secret "$SECRET_NAME" -o json)
export SQS_QUEUE_URL=$(echo $secret | jq -r '.data.sqs_queue_url | @base64d')
export AWS_ACCESS_KEY_ID=$(echo $secret | jq -r '.data.access_key_id | @base64d')
export AWS_SECRET_ACCESS_KEY=$(echo $secret | jq -r '.data.secret_access_key | @base64d')
