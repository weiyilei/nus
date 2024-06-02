alter table BANK_RECORDS drop constraint fk_ID_CARD;

alter table BANK_RECORDS add constraint FK_BANK_ID_CARD foreign key(ID_CARD) references GOVERNMENT_CITIZEN(IDENTITY_CARD_ID);

alter table BANK_STAFFS add constraint FK_BANK_STAFF_ID_CARD foreign key(ID_CARD) references GOVERNMENT_CITIZEN(IDENTITY_CARD_ID);

select USER from DUAL;

select * from all_users;

CREATE OR REPLACE FUNCTION check_bank_records_select(v_schema IN VARCHAR2, v_obj IN VARCHAR2)
RETURN VARCHAR2 AS 
    POLICE_COUNT NUMBER := 0;
    BANK_COUNT NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO POLICE_COUNT FROM system.PUBLIC_SECURITY_EMPLOYEE WHERE NAME = SYS_CONTEXT('USERENV', 'SESSION_USER');
    SELECT COUNT(*) INTO BANK_COUNT FROM system.BANK_STAFFS WHERE NAME = SYS_CONTEXT('USERENV', 'SESSION_USER');
    
    IF SYS_CONTEXT('USERENV', 'SESSION_USER') = 'SYSTEM' THEN
        RETURN '';
    END IF;
    
	IF POLICE_COUNT > 0 THEN
		RETURN 'LOAN > 100000';
	ELSIF BANK_COUNT > 0 THEN
		RETURN 'BANK = (select BANK_BELONGING from system.BANK_STAFFS where NAME = SYS_CONTEXT(''USERENV'', ''SESSION_USER''))';
    ELSE
        RETURN 'NAME = SYS_CONTEXT(''USERENV'', ''SESSION_USER'')' ;
    END IF;
END check_bank_records_select;

BEGIN
	DBMS_RLS.ADD_POLICY (
		object_schema	=>	'system',
		object_name	=>	'BANK_RECORDS',
		policy_name	=>	'check_bank_records_select_policy',
		policy_function	=>	'check_bank_records_select',
        statement_types => 'SELECT',
		update_check 	=> 	FALSE );
END;

BEGIN
    DBMS_RLS.DROP_POLICY(
		object_schema	=>	'system',
		object_name	=>	'BANK_RECORDS',
		policy_name	=>	'check_bank_records_select_policy' );
END;

CREATE USER NAME11 IDENTIFIED BY NAME11;
GRANT SELECT, INSERT, UPDATE, DELETE ON BANK_RECORDS TO NAME11;
GRANT CONNECT TO NAME11;

select * FROM system.BANK_RECORDS;

CREATE USER NAME18 IDENTIFIED BY NAME18;
GRANT SELECT, INSERT, UPDATE, DELETE ON BANK_RECORDS TO NAME18;
GRANT CONNECT TO NAME18;
CREATE USER NAME29 IDENTIFIED BY NAME29;
GRANT SELECT, INSERT, UPDATE, DELETE ON BANK_RECORDS TO NAME29;
GRANT CONNECT TO NAME29;
CREATE USER NAME15 IDENTIFIED BY NAME15;
GRANT SELECT, INSERT, UPDATE, DELETE ON BANK_RECORDS TO NAME15;
GRANT CONNECT TO NAME15;

CREATE OR REPLACE FUNCTION check_bank_records_update(v_schema IN VARCHAR2, v_obj IN VARCHAR2)
RETURN VARCHAR2 AS 
BEGIN
	RETURN 'BANK = (select BANK_BELONGING from system.BANK_STAFFS where NAME = 
    SYS_CONTEXT(''USERENV'', ''SESSION_USER'')) AND NAME <> SYS_CONTEXT(''USERENV'', ''SESSION_USER'')';
END check_bank_records_update;

BEGIN
	DBMS_RLS.ADD_POLICY (
		object_schema	=>	'system',
		object_name	=>	'BANK_RECORDS',
		policy_name	=>	'check_bank_records_update_policy',
		policy_function	=>	'check_bank_records_update',
        statement_types => 'UPDATE');
END;

BEGIN
    DBMS_RLS.DROP_POLICY(
		object_schema	=>	'system',
		object_name	=>	'BANK_RECORDS',
		policy_name	=>	'check_bank_records_update_policy' );
END;

CREATE OR REPLACE TRIGGER update_credit_report
BEFORE INSERT ON bank_records
FOR EACH ROW
BEGIN
  -- 检查是否存在对应的政府市民记录
  IF :new.IDENTITY_CARD_ID IS NOT NULL THEN
    -- 计算日期差值（以天为单位）
    DECLARE
      date_difference NUMBER;
    BEGIN
      date_difference := TRUNC(:new.loan_overdue_date) - TRUNC(SYSDATE);
    
      -- 如果日期差值小于 1，减少信用分 10 分
      IF date_difference < 0 THEN
        UPDATE government_citizen
        SET credit_report = credit_report + 10*date_difference
        WHERE IDENTITY_CARD_ID = :new.IDENTITY_CARD_ID;
      END IF;
    END;
  END IF;
END;

drop trigger system.update_credit_report;

select * from system.BANK_RECORDS;
select * from system.GOVERNMENT_CITIZEN;

commit;

update system.BANK_RECORDS set loan_overdue_date = TO_DATE('2023-12-25 00:00:00', 'YYYY-MM-DD HH24:MI:SS');

