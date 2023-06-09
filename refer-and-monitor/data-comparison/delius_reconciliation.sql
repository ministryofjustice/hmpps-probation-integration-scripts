set echo off
set feedback off
set termout off
set verify off
set markup csv on
spool &1
WITH INTERVENTIONS_USER AS (
    SELECT USER_ID FROM DELIUS_APP_SCHEMA.USER_ u WHERE u.DISTINGUISHED_NAME LIKE 'InterventionsReferAndMonitorSystem'
                                                  OR u.DISTINGUISHED_NAME LIKE 'ReferAndMonitorAndDelius'
),
RAM_CONTACT AS (
    SELECT c.NSI_ID,
           CASE WHEN rct.CODE = 'CRSAPT' THEN 'Service Delivery Appointment'
               WHEN rct.CODE = 'CRSSAA' THEN 'Supplier Assessment Appointment'
               ELSE REGEXP_REPLACE(TO_CHAR(dbms_lob.substr(c.NOTES,2000,1)),'^(Comment added by .+? on .+? at .+?'||chr(10)||')+(\w+ \w+ \w+).*', '\2', 1, 0, 'n') END CONTACT_NOTES,
           REGEXP_REPLACE(dbms_lob.substr(c.NOTES,2000,1),'.+? Referral ([A-Z0-9]{8}) .*', '\1', 1, 0, 'n') REFERENCE_NUMBER,
           ol.CODE OFFICE_LOCATION,
           c.CONTACT_DATE,
           TO_CHAR(c.CONTACT_DATE,'YYYY-MM-DD ') || TO_CHAR(c.CONTACT_START_TIME,'HH24:MI:"00"') CONTACT_START_TIME,
           CASE WHEN c.CONTACT_END_TIME IS NULL THEN NULL ELSE TO_CHAR(c.CONTACT_DATE,'YYYY-MM-DD ') || TO_CHAR(c.CONTACT_END_TIME,'HH24:MI:SS') END CONTACT_END_TIME,
           c.EXTERNAL_REFERENCE,
           CASE WHEN rcto.CODE = 'RSSR' THEN NULL ELSE c.ATTENDED END as CONTACT_ATTENDED, -- ignore rescheduled outcomes
           CASE WHEN rcto.CODE = 'RSSR' THEN NULL ELSE c.COMPLIED END as CONTACT_COMPLIED,
           CASE WHEN iu3.USER_ID IS NULL THEN 'Y' ELSE 'N' END CREATED_IN_DELIUS,
           CASE WHEN iu4.USER_ID IS NULL THEN 'Y' ELSE 'N' END MANUALLY_UPDATED_IN_DELIUS
    FROM DELIUS_APP_SCHEMA.CONTACT c
    INNER JOIN DELIUS_APP_SCHEMA.R_CONTACT_TYPE rct ON rct.CONTACT_TYPE_ID = c.CONTACT_TYPE_ID AND rct.CODE LIKE 'CRS%' -- ignore delius generated ones
    LEFT JOIN DELIUS_APP_SCHEMA.OFFICE_LOCATION ol ON ol.OFFICE_LOCATION_ID = c.OFFICE_LOCATION_ID -- no location for notification
    LEFT JOIN DELIUS_APP_SCHEMA.R_CONTACT_OUTCOME_TYPE rcto ON rcto.CONTACT_OUTCOME_TYPE_ID = c.CONTACT_OUTCOME_TYPE_ID
    LEFT JOIN INTERVENTIONS_USER iu3 ON iu3.USER_ID = c.CREATED_BY_USER_ID
    LEFT JOIN INTERVENTIONS_USER iu4 ON iu4.USER_ID = c.LAST_UPDATED_USER_ID
)
SELECT SUBSTR(nsi.EXTERNAL_REFERENCE, -36, 36) REFERRAL_ID,
       o.CRN SERVICE_USERCRN,
       rc.REFERENCE_NUMBER,
       rnt.DESCRIPTION NAME,
       nsi.EVENT_ID RELEVANT_SENTENCE_ID,
       TO_CHAR(nsi.REFERRAL_DATE,'YYYY-MM-DD') REFERRAL_START,
       TO_CHAR(nsi.NSI_STATUS_DATE,'YYYY-MM-DD HH24:MI:SS') STATUS_AT,
       rns.DESCRIPTION STATUS,
       rsrl.CODE_DESCRIPTION OUTCOME,
       CASE WHEN iu2.USER_ID IS NULL THEN 'Y' ELSE 'N' END REFERRAL_MANUALLY_UPDATED_IN_DELIUS,
       rc.CONTACT_NOTES,
       rc.OFFICE_LOCATION,
       rc.CONTACT_START_TIME,
       rc.CONTACT_END_TIME,
       SUBSTR(rc.EXTERNAL_REFERENCE, -36, 36) APPOINTMENT_ID,
       rc.CONTACT_ATTENDED AS ATTENDED,
       rc.CONTACT_COMPLIED AS COMPLIED,
       CASE WHEN rc.CREATED_IN_DELIUS IS NULL THEN 'N' ELSE rc.CREATED_IN_DELIUS END CREATED_IN_DELIUS,
       CASE WHEN rc.MANUALLY_UPDATED_IN_DELIUS IS NULL THEN 'N' ELSE rc.MANUALLY_UPDATED_IN_DELIUS END CONTACT_MANUALLY_UPDATED_IN_DELIUS
FROM DELIUS_APP_SCHEMA.NSI nsi
INNER JOIN DELIUS_APP_SCHEMA.R_NSI_TYPE rnt ON rnt.NSI_TYPE_ID = nsi.NSI_TYPE_ID AND rnt.CODE LIKE 'CRS0%' -- only RM nsi types
INNER JOIN DELIUS_APP_SCHEMA.R_NSI_STATUS rns ON rns.NSI_STATUS_ID = nsi.NSI_STATUS_ID
LEFT JOIN DELIUS_APP_SCHEMA.R_STANDARD_REFERENCE_LIST rsrl ON rsrl.STANDARD_REFERENCE_LIST_ID = nsi.NSI_OUTCOME_ID
INNER JOIN DELIUS_APP_SCHEMA.OFFENDER o ON o.OFFENDER_ID = nsi.OFFENDER_ID
LEFT JOIN INTERVENTIONS_USER iu2 ON iu2.USER_ID = nsi.LAST_UPDATED_USER_ID
LEFT JOIN RAM_CONTACT rc on rc.NSI_ID = nsi.NSI_ID -- only RM contacts
WHERE nsi.EXTERNAL_REFERENCE LIKE 'urn:hmpps:interventions-referral:%' -- only RM referrals
-- AND nsi.EXTERNAL_REFERENCE = 'urn:hmpps:interventions-referral:c420661e-47c2-4ea0-ab12-55f4abc626ed'
AND rc.CONTACT_DATE >= TO_DATE('&2', 'YYYY-MM-DD')
AND rc.CONTACT_DATE < TO_DATE('&3', 'YYYY-MM-DD')
--   AND rc.CONTACT_DATE = TO_DATE('2023-06-01', 'YYYY-MM-DD')
AND nsi.SOFT_DELETED = 0
-- AND o.CRN = 'E379156'
ORDER BY nsi.REFERRAL_DATE,
         o.CRN,
         nsi.NSI_STATUS_DATE,
         rc.CONTACT_START_TIME;
spool off