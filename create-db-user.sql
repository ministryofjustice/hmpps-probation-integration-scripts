
drop procedure createIntegrationServiceUser;
create PROCEDURE createIntegrationServiceUser(
    p_operatoradname VARCHAR2,
    p_distinguished_name VARCHAR2,
    p_surname VARCHAR2,
    p_forename VARCHAR2
)
    IS
    l_cnt                     NUMBER := 0;
l_user_id                 NUMBER;
    l_operator_id             NUMBER;
    l_organisation_id         NUMBER;
    l_sql                     VARCHAR2(1024);
    l_business_interaction_id NUMBER;
    l_audit_string            VARCHAR2(4000);
BEGIN

    /* Check to see if the operator is authorised to access National Delius */
    l_sql := 'SELECT COUNT(*) FROM USER_ WHERE UPPER(DISTINGUISHED_NAME) = UPPER(''' || p_operatoradname || ''')';
EXECUTE IMMEDIATE l_sql INTO l_cnt;

IF l_cnt = 1 THEN

        /* Obtain the user_id and organisation_id for the operator for auditing purposes */
        l_sql := 'SELECT USER_ID, ORGANISATION_ID FROM USER_ WHERE UPPER(DISTINGUISHED_NAME) = UPPER(''' ||
                 p_operatoradname || ''')';
EXECUTE IMMEDIATE l_sql INTO l_operator_id, l_organisation_id;

/* Check if the new user already exists */
l_sql := 'SELECT COUNT(*) FROM USER_ WHERE UPPER(DISTINGUISHED_NAME) = UPPER(''' || p_distinguished_name ||
                 ''')';
EXECUTE IMMEDIATE l_sql INTO l_cnt;

IF l_cnt = 0 THEN

            /* INSERT into USER_ */
            l_sql := 'INSERT INTO USER_(USER_ID, SURNAME, FORENAME, DISTINGUISHED_NAME, ROW_VERSION, PRIVATE, ORGANISATION_ID, LAST_UPDATED_USER_ID, CREATED_BY_USER_ID, CREATED_DATETIME, LAST_UPDATED_DATETIME) ' ||
                     'VALUES (USER_ID_SEQ.NEXTVAL,''' || p_surname || ''',''' || p_forename || ''',''' || p_distinguished_name || ''',0,0,''' ||
                     l_organisation_id || ''', ' || l_operator_id || ',' || l_operator_id || ',sysdate,sysdate)';
EXECUTE IMMEDIATE (l_sql);

l_sql := 'SELECT USER_ID FROM USER_ WHERE DISTINGUISHED_NAME = ''' || p_distinguished_name || '''';
EXECUTE IMMEDIATE l_sql INTO l_user_id;

/* INSERT into PROBATION_AREA_USER */
l_sql := 'INSERT INTO PROBATION_AREA_USER(USER_ID, PROBATION_AREA_ID, ROW_VERSION, LAST_UPDATED_USER_ID, CREATED_BY_USER_ID, CREATED_DATETIME, LAST_UPDATED_DATETIME)
                     SELECT ' || l_user_id || ',probation_area_id,0,' || l_operator_id || ',' || l_operator_id ||
                     ',sysdate,sysdate from probation_area where end_date is null';
EXECUTE IMMEDIATE (l_sql);

/* Obtain business_interaction_id for auditing purposes */
SELECT BUSINESS_INTERACTION_ID
INTO l_business_interaction_id
FROM BUSINESS_INTERACTION
WHERE BUSINESS_INTERACTION_CODE = 'HPBI008';

/* INSERT into AUDITED_INTERACTION */
l_audit_string := 'CREATE distinguished_name=' || p_distinguished_name;
            l_sql := 'INSERT INTO AUDITED_INTERACTION (DATE_TIME, USER_ID, OUTCOME, INTERACTION_PARAMETERS, BUSINESS_INTERACTION_ID) ' ||
                     'VALUES (sysdate,' || l_operator_id || ',''P'',''' || l_audit_string || ''',' ||
                     l_business_interaction_id || ')';
EXECUTE IMMEDIATE (l_sql);
COMMIT;
END IF;
END IF;


END createIntegrationServiceUser;


-- Usage:
-- select * from user_ where distinguished_name = 'HMPPSAllocationsService';
-- delete from probation_area_user where user_id=2500357091;
-- delete from user_ where user_id=2500357091;
-- call delius_app_schema.createIntegrationServiceUser('Data Maintenance', 'HMPPSAllocationsService', 'Service', 'HMPPS Allocations');