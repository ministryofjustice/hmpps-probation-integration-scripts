#!/usr/bin/env bash
##
## Delete and recreate all data in the contact semantic search indexes.
##
## Usage:
##   ENVIRONMENT=<dev|preprod|prod> ./clear-and-reindex.sh
##
set -euo pipefail

echo "Forwarding port to OpenSearch in $ENVIRONMENT..."
kubectl -n "hmpps-probation-search-$ENVIRONMENT" port-forward deploy/opensearch-test-proxy 8080:8080 & sleep 5

echo "Deleting indexes..."
curl -XDELETE localhost:8080/contact-semantic-search-a
curl -XDELETE localhost:8080/contact-semantic-search-b

echo "Starting reindex job..."
kubectl -n "hmpps-probation-integration-services-$ENVIRONMENT" create job "contact-semantic-reindex-$RANDOM" --from=cronjob/contact-semantic-reindex
