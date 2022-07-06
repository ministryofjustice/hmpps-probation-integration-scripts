#!/usr/bin/env bash

set -eo pipefail

# Get timestamps and sort by date
timestamps=$(sed -E 's/.*Timestamp": "([^"]+?)".*/\1/' "$1" | sort --stable)

# Output analysis of released and received messages
printf "%25s : %4s\n" "Earliest timestamp"    "$(echo "$timestamps" | head -n 1)"
printf "%25s : %4s\n" "Latest timestamp"      "$(echo "$timestamps" | tail -n 1)"
printf "%25s : %4s\n" "Total messages"      "$(grep -c ^ "$1")"
echo
printf "%25s : %4s\n" "Total released" "$(grep -c 'released' "$1")"
printf "%25s : %4s\n" "Release" "$(grep -c 'RELEASED' "$1")"
printf "%25s : %4s\n" "Temporary absence" "$(grep -c 'TEMPORARY_ABSENCE_RELEASE' "$1")"
echo
printf "%25s : %4s\n" "Total received" "$(grep -c 'received' "$1")"
printf "%25s : %4s\n" "Admission" "$(grep -c 'ADMISSION' "$1")"
printf "%25s : %4s\n" "Temporary absence" "$(grep -c 'TEMPORARY_ABSENCE_RETURN' "$1")"
