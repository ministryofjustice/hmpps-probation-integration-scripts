#!/usr/bin/env bash
##
## Output SQL for correcting Contact outcomes in Delius based on Sentry events
##
## Usage:
##   SENTRY_API_KEY=... ISSUE_ID=... ./get-sentry-events.sh | ./repopulate-outcomes.sh > output.sql
##
set -eo pipefail
source ../common.sh

cat "${1:-/dev/stdin}" \
| jq '.[].entries[] | select(.type == "message") | .data.params[1]' \
| sed -E 's/"req.body=AppointmentOutcomeRequest\(notes=(.+?https:\/\/refer-monitor-intervention.service.justice.gov.uk\/probation-practitioner\/referrals\/(.+?)\/supplier-assessment\/post-assessment.+?), attended=(.+?), notifyPPOfAttendanceBehaviour=(.+?)\)"/\
update contact\
set contact_outcome_type_id = (select contact_outcome_type_id from r_contact_outcome_type where code = '"'"'\3-\4'"'"'),\
    notes = notes || chr(10) || chr(10) || '"'"'\1'"'"',\
    last_updated_datetime = current_date,\
    last_updated_user_id = 4\
where nsi_id = (select nsi_id from nsi where external_reference='"'"'urn:hmpps:interventions-referral:\2'"'"')\
and contact_outcome_type_id is null;/' \
| sed "s/'YES-true'/'ATTC'/; s/'YES-false'/'AFTC'/; s/'NO-.*'/'AFTA'/" \
| sed "s/\\n/' || chr(10) || '/"
