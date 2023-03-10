#!/usr/bin/env bash

projects='APPROVED_PREMISES_AND_DELIUS APPROVED_PREMISES_AND_OASYS CUSTODY_KEY_DATES_AND_DELIUS MAKE_RECALL_DECISIONS_AND_DELIUS MANAGE_POM_CASES_AND_DELIUS OFFENDER_EVENTS_AND_DELIUS PERSON_SEARCH_INDEX_FROM_DELIUS PRE_SENTENCE_REPORTS_TO_DELIUS PRISON_CASE_NOTES_TO_PROBATION PRISON_CUSTODY_STATUS_TO_DELIUS REFER_AND_MONITOR_AND_DELIUS RISK_ASSESSMENT_SCORES_TO_DELIUS TIER_TO_DELIUS UNPAID_WORK_AND_DELIUS WORKFORCE_ALLOCATIONS_TO_DELIUS'
envs='test preprod prod'

cd ~/IdeaProjects/hmpps-probation-integration-services || exit 1
for project in $projects; do
  gh secret list | grep "$project" | awk '{print $1}' | xargs -n1 gh secret delete
  for env in $envs; do
    gh secret list --env "$env" | grep "$project" | awk '{print $1}' | xargs -n1 gh secret delete --env "$env"
  done
done