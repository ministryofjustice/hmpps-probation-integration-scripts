#!/usr/bin/env bash
source ../common.sh
requires csvcut
export LC_ALL=C

csvcut -c customDimensions case-notes.csv                                    | # get customDimensions column
sed 1d                                                                       | # remove header
sed -E 's/""/"/g;s/^"//g;s/"$//g'                                            | # remove extra quotes from CSV output
sed -E 's/"\[\{type=NOMS, value=(.+?)\}\]"/[{"type":"NOMS","value":"\1"}]/g' | # fix json in personReference
jq '.personReference = { "identifiers": ."personReference.identifiers" }'    | # remap personReference
jq '.additionalInformation = {
  "subType": ."additionalInformation.subType",
  "type": ."additionalInformation.type",
  "caseNoteType": ."additionalInformation.caseNoteType",
  "caseNoteId": ."additionalInformation.caseNoteId"
}'                                                                           | # remap additionalInformation
jq 'del(
  ."personReference.identifiers",
  ."additionalInformation.subType",
  ."additionalInformation.type",
  ."additionalInformation.caseNoteType",
  ."additionalInformation.caseNoteId"
)'                                                                           | # remove remapped fields
jq -c '{
  "Type": "Notification",
  "MessageId": "00000000-0000-0000-0000-000000000000",
  "TopicArn": "arn:aws:sns:eu-west-2:754256621582:cloud-platform-Digital-Prison-Services-e29fb030a51b3576dd645aa5e460e573",
  "Message": . | tojson,
  "Timestamp": "2022-05-04T07:00:33.487Z",
  "MessageAttributes": {
    "eventType": {"Type": "String", "Value": .eventType},
    "caseNoteType": {"Type": "String", "Value": .additionalInformation.caseNoteType}
  }
}'