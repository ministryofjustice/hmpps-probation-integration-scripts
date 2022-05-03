#!/usr/bin/env bash
##
## Make common changes to all the probation integration GitHub repositories. Useful for updating dependencies etc.
##
## Usage:
## Update the BRANCH and MESSAGE values below, then add a script into the make_changes function.
##

set -eo pipefail
source common.sh
requires git gh

# Set branch and commit message
BRANCH=branch-name
MESSAGE='Commit message

Additional information in commit body'

# Function to run in each project
make_changes() {
  echo Add code here to make changes
  # Examples:
  #  sed -Ei 's/ministryofjustice\/hmpps\@.*/ministryofjustice\/hmpps\@3.14/' .circleci/config.yml # replace a circleci orb version
  #  sed -Ei 's/(.*gradle-spring-boot.*)".*"/\1"4.+"/' build.gradle* || true # replace a gradle plugin version
  #  sed -Ei '/^dependencies.*/i ext["jackson.version.databind"] = "2.13.2.2" \/\/ Overriding Jackson databind version to fix CVE-2020-36518\n' build.gradle* || true # add a dependency override
}

gh_login
for project in "${PROJECTS[@]}"; do
  checkout "$project" "$BRANCH"
  make_changes
  commit "$MESSAGE"
  push "$BRANCH"
  create_pr
done

echo
echo "$PULL_REQUESTS"