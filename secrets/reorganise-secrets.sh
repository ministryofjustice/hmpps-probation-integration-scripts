#!/usr/bin/env bash

# Usage: eval "$(./reorganise-secrets.sh)"

projects='approved-premises-and-delius approved-premises-and-oasys custody-key-dates-and-delius make-recall-decisions-and-delius manage-pom-cases-and-delius offender-events-and-delius person-search-index-from-delius pre-sentence-reports-to-delius prison-case-notes-to-probation prison-custody-status-to-delius refer-and-monitor-and-delius risk-assessment-scores-to-delius tier-to-delius unpaid-work-and-delius workforce-allocations-to-delius'
namespaces='hmpps-probation-integration-services-dev hmpps-probation-integration-services-preprod hmpps-probation-integration-services-prod'

function reorganise_secret() {
  local namespace=$1
  local project=$2
  local secret_file="$namespace/$project.json"
  local new_secret_suffix=$3
  shift 3

  local command="kubectl -n '$namespace' create secret generic '$project-$new_secret_suffix'"
  local create_secret=false
  for key in "$@"; do
    # if the value already exists in the old secret
    if [ "$(jq --arg key "$key" '.data | has($key)' "$secret_file")" == 'true' ]; then
      create_secret=true
      # then create it in the new structure
      val=$(jq -r ".data.$key" "$secret_file" | base64 -d)
      command="$command --from-literal='$key=$val'"
    fi
  done
  if [ "$create_secret" = 'true' ]; then echo "$command"; fi
}

for namespace in $namespaces; do
  mkdir -p "$namespace"
  for project in $projects; do
    kubectl -n "$namespace" get secret "$project" -o json > "$namespace/$project.json"
    reorganise_secret "$namespace" "$project" 'client-credentials' 'CLIENT_ID' 'CLIENT_SECRET' 'ORDS_CLIENT_ID' 'ORDS_CLIENT_SECRET'
    reorganise_secret "$namespace" "$project" 'database' 'DB_USERNAME' 'DB_PASSWORD'
    reorganise_secret "$namespace" "$project" 'sentry' 'SENTRY_DSN'
  done
done