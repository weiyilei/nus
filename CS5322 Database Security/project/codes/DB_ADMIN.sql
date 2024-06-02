EXECUTE SA_SYSDBA.DROP_POLICY('BANK_READ_POLICY');
EXECUTE SA_SYSDBA.CREATE_POLICY('OLS_POLICY','ols_label');
GRANT OLS_POLICY_DBA TO POLICY_ADMIN;
--EXECUTE SA_SYSDBA.CREATE_POLICY('BANK_WRITE_POLICY','bank_write_label');
--GRANT BANK_WRITE_POLICY_DBA TO POLICY_ADMIN;

GRANT EXECUTE ON sa_components TO POLICY_ADMIN;
GRANT EXECUTE ON sa_user_admin TO POLICY_ADMIN;
GRANT EXECUTE ON sa_user_admin TO POLICY_ADMIN;
GRANT EXECUTE ON sa_label_admin TO POLICY_ADMIN;
GRANT EXECUTE ON sa_policy_admin TO POLICY_ADMIN;
GRANT EXECUTE ON sa_audit_admin TO POLICY_ADMIN;

CREATE TABLE DB_ADMIN.BANK_RECORDS(	
    ID int PRIMARY KEY, 
	IDENTITY_CARD_ID VARCHAR2(20), 
	NAME VARCHAR2(20), 
	DEPOSIT int, 
	LOAN int, 
	LOAN_OVERDUE_DATE DATE, 
	BANK VARCHAR2(20), 
	HANDLING VARCHAR2(20)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON BANK_RECORDS to PUBLIC;

select * from DB_ADMIN.BANK_RECORDS;

CREATE TABLE DB_ADMIN.HOSPITAL(	
    ID int PRIMARY KEY, 
	IDENTITY_CARD_ID VARCHAR2(20), 
	NAME VARCHAR2(50), 
	BLOOD_TYPE VARCHAR2(50), 
	HAS_SERIOUS_ILLNESS NUMBER(1,0) DEFAULT 0, 
	MEDICAL_RECORD VARCHAR2(100), 
	ATTENDING_PHYSICIAN VARCHAR2(20),
    HANDLING VARCHAR2(20)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON HOSPITAL to PUBLIC;

select * from DB_ADMIN.HOSPITAL;


CREATE OR REPLACE FUNCTION DB_ADMIN.get_bank_label
                 (Identity_card_id varchar2, 
                  Handling varchar2)
  Return LBACSYS.LBAC_LABEL
as
  i_label  varchar2(80);
Begin
  /* Determine Class Level */
  CASE Handling
    WHEN 'BP' THEN
        i_label := 'HS:';
    WHEN 'BM' THEN
        i_label := 'S:';
    WHEN 'BS' THEN
        i_label := 'C:';
    WHEN 'BT' THEN
        i_label := 'U:';
  END CASE;

  /* Determine Compartment */
    i_label := i_label||'BK:';
  /* Determine Groups */
  i_label := i_label||Handling;
  return TO_LBAC_DATA_LABEL('OLS_POLICY',i_label);
End;
/

CREATE OR REPLACE FUNCTION DB_ADMIN.get_hospital_label
                 (Identity_card_id varchar2, 
                  Handling varchar2)
  Return LBACSYS.LBAC_LABEL
as
  i_label  varchar2(80);
Begin
  /* Determine Class Level */
  CASE Handling
    WHEN 'HA' THEN
        i_label := 'HS:';
    WHEN 'HM' THEN
        i_label := 'S:';
    WHEN 'DO' THEN
        i_label := 'C:';
    WHEN 'NU' THEN
        i_label := 'U:';
  END CASE;

  /* Determine Compartment */
    i_label := i_label||'HP:';
  /* Determine Groups */
  i_label := i_label||Handling;
  return TO_LBAC_DATA_LABEL('OLS_POLICY',i_label);
End;

SHOW ERRORS

INSERT INTO DB_ADMIN.BANK_RECORDS VALUES (1,'0000000001','NAME1', 3000, 5000, TO_DATE('08-11��-23', 'DD_MON_YY'), 'DBS', 'BT', NULL);
INSERT INTO DB_ADMIN.BANK_RECORDS VALUES (2,'0000000001','NAME1', 3000, 5000000000, TO_DATE('08-11��-23', 'DD_MON_YY'), 'DBS', 'BP', NULL);
INSERT INTO DB_ADMIN.BANK_RECORDS VALUES (3,'0000000030','NAME30', 0, 1000, TO_DATE('06-11��-23', 'DD_MON_YY'), 'BOC', 'BS', NULL);
INSERT INTO DB_ADMIN.BANK_RECORDS VALUES (4,'0000000029','NAME29', 1000000, 500, TO_DATE('05-11��-23', 'DD_MON_YY'), 'BOC', 'BM', NULL);
INSERT INTO DB_ADMIN.BANK_RECORDS VALUES (5,'0000000001','NAME1', 3000, 5000, TO_DATE('08-11��-23', 'DD_MON_YY'), 'DBS', 'BT' , NULL);
INSERT INTO DB_ADMIN.BANK_RECORDS VALUES (6,'0000000029','NAME29', 1000000, 500, TO_DATE('05-11��-23', 'DD_MON_YY'), 'BOC', 'BM' , NULL);
commit;

INSERT INTO DB_ADMIN.HOSPITAL VALUES (1,'0000000001','NAME1', 'AB', 0, '2', '2', 'HA', NULL);
INSERT INTO DB_ADMIN.HOSPITAL VALUES (2,'0000000015','NAME15', 'O', 0, '12', '24', 'DO', NULL);
commit;

select * from DB_ADMIN.HOSPITAL;