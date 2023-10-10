#!/usr/bin/env bash
##
## Get all pages of Sentry events for an issue
##
## Usage:
##   SENTRY_API_KEY=... ISSUE_ID=... ./get-sentry-events.sh
##
set -eo pipefail
source ../common.sh

if [ -z "$SENTRY_API_KEY" ]; then print_usage; fail "SENTRY_API_KEY not set"; fi
if [ -z "$ISSUE_ID" ]; then print_usage; fail "ISSUE_ID not set"; fi

sentry_events='[]'
cursor=0
while [ "$page" != '[]' ]; do
  page=$(curl --retry 5 --fail -H "Authorization: Bearer $SENTRY_API_KEY" "https://sentry.io/api/0/issues/$ISSUE_ID/events/?full=true&cursor=0:$cursor:0")
  sentry_events=$(printf '%s\n%s' "$sentry_events" "$page")
  cursor=$((cursor + 100))
done

echo "$sentry_events" | jq -s 'add'