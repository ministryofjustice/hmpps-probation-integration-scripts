#!/bin/bash

set -euo pipefail

namespaces="activities-api-dev
  create-and-vary-a-licence-dev
  dps-toolkit
  hmpps-domain-event-logger-dev
  hmpps-incentives-dev
  hmpps-prisoner-to-nomis-update-dev
  hmpps-registers-dev
  hmpps-restricted-patients-api-dev
  hmpps-tier-dev
  hmpps-workload-dev
  keyworker-api-dev
  prisoner-offender-search-dev
  workforce-management-dev"

while read -r namespace; do
  # Rolling restart of all deployments in client namespace
  deploys=$(kubectl get deployments -n "$namespace" | tail -n +2 | cut -d ' ' -f 1)
  for deploy in $deploys; do
    kubectl rollout restart deployments/"$deploy" -n "$namespace"
  done
done <<<"$namespaces"
