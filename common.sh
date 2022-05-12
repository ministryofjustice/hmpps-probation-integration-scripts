#!/usr/bin/env bash

declare PROJECT_HOME
PROJECT_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/projects"
declare -a PROJECTS=(
  'hmpps-delius-api'
  'community-api'
  'prison-to-probation-update'
  'case-notes-to-probation'
  'probation-offender-events'
  'probation-offender-search'
  'probation-offender-search-indexer'
  'hmpps-probation-integration-lambda-functions'
  'hmpps-probation-integration-e2e-tests'
  'hmpps-probation-integration-scripts'
  'hmpps-pi-watch'
  'hmpps-delius-core-terraform'
)
export PROJECTS

fail() {
  echo "${1:-Error occurred}"
  exit 1
}

requires() {
  for arg in "$@"; do
    command -v "$arg" >/dev/null 2>&1 || fail "'$arg' is not installed. Please install '$arg' and try again."
  done
}

print_usage() {
  grep '^##' "$1" | cut -c 3-
}

checkout() {
  mkdir -p "${PROJECT_HOME}"
  cd "${PROJECT_HOME}" || fail
  rm -rf "$1"
  git clone --quiet "https://github.com/ministryofjustice/${1}.git"
  cd "$1" || fail "Project $1 not found"
  git checkout -B "$2"
}

commit() {
  git add .
  git diff
  git commit --all --message "$1"
}

push() {
  git push --set-upstream origin "$1"
}

create_pr() {
  PULL_REQUEST=$(gh pr create --fill)
  PULL_REQUESTS="$PULL_REQUESTS $PULL_REQUEST"
}

gh_login() {
  gh auth status || gh auth login --hostname github.com
}

gh_pi_prs() {
  # shellcheck disable=SC2046
  gh search prs --state open $(for proj in "${PROJECTS[@]}"; do echo --repo "ministryofjustice/$proj"; done)
}
