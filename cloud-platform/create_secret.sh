#!/bin/bash

set -euo pipefail

secret=$'{
  "apiVersion": "v1",
  "data": {
    "access_key_id": "TEST",
    "secret_access_key": "TEST",
    "topic_arn": "TEST"
  },
  "kind": "Secret",
  "metadata": {
    "name": "hmpps-domain-events-topic",
    "namespace": "hmpps-probation-integration"
  },
  "type": "Opaque"
}'

echo "$secret" | kubectl apply -f -
