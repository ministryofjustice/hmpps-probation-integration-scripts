#!/bin/bash

set -euo pipefail

# List of secrets/namespaces that publish to SNS
creds_namespace="hmpps-domain-events-topic hmpps-registers-dev
    hmpps-domain-events-topic offender-events-dev
    hmpps-domain-events-topic hmpps-interventions-dev
    hmpps-domain-events-topic hmpps-workload-dev
    hmpps-domain-events-topic hmpps-manage-offences-api-dev
    hmpps-domain-events-topic make-recall-decision-dev
    hmpps-domain-events-topic prisoner-offender-search-dev
    hmpps-domain-events-topic hmpps-complexity-of-need-staging
    hmpps-domain-events-topic calculate-release-dates-api-dev
    hmpps-domain-events-topic hmpps-incentives-dev
    hmpps-domain-events-topic hmpps-domain-event-logger-dev
    domain-events-topic offender-case-notes-dev
    activities-domain-events-sqs-topic-instance-output activities-api-dev
    wmt-hmpps-domain-events-topic hmpps-workload-dev
    hmpps-domain-events-topic offender-management-staging
    hmpps-domain-events-topic offender-management-test
    hmpps-domain-events-topic offender-management-test2
    hmpps-domain-events-topic court-probation-dev
    hmpps-domain-events-topic visit-someone-in-prison-backend-svc-dev
    hmpps-domain-events-topic hmpps-restricted-patients-api-dev
    hmpps-domain-events-topic hmpps-tier-dev"

# Loop through each namespace
while IFS= read -r line; do
  read -r secret_name namespace <<<"$line"

  # Read new topic user credentials from domain events namespace
  read -r new_key new_secret <<<$(
    kubectl -n hmpps-domain-events-dev get secret hmpps-domain-events-new-key -o json |
      jq -r '.data | to_entries | map("\(.value)") | join(" ")'
  )

  # Put new topic user credentials into existing topic secret in client namespace
  kubectl -n "$namespace" get secret "$secret_name" -o json |
    jq --arg new_key "$(echo -n $new_key)" \
      --arg new_secret "$(echo -n $new_secret)" \
      '.data["access_key_id"]=$new_key | .data["secret_access_key"]=$new_secret' | kubectl apply -f -

  # Rolling restart of all deployments in client namespace
  deploys=$(kubectl get deployments -n "$namespace" | tail -n +2 | cut -d ' ' -f 1)
  for deploy in $deploys; do
    kubectl rollout restart deployments/"$deploy" -n "$namespace"
  done
done <<<"$creds_namespace"
