select * from ALL_USERS;
ALTER USER LBACSYS ACCOUNT UNLOCK IDENTIFIED BY "LBACSYS";
GRANT ALL_PRIVILEGES TO LBACSYS;

DROP USER POLICY_ADMIN CASCADE;
CREATE USER "POLICY_ADMIN" IDENTIFIED BY "POLICY_ADMIN";
GRANT CONNECT, RESOURCE, SELECT_CATALOG_ROLE TO POLICY_ADMIN;

DROP USER DB_ADMIN CASCADE;
CREATE USER "DB_ADMIN" IDENTIFIED BY "DB_ADMIN";
GRANT CONNECT, RESOURCE, SELECT_CATALOG_ROLE TO DB_ADMIN;

--CONNECT LBACSYS/LBACSYS

GRANT EXECUTE ON sa_components TO DB_ADMIN WITH GRANT OPTION;
GRANT EXECUTE ON sa_user_admin TO DB_ADMIN WITH GRANT OPTION;
GRANT EXECUTE ON sa_user_admin TO DB_ADMIN WITH GRANT OPTION;
GRANT EXECUTE ON sa_label_admin TO DB_ADMIN WITH GRANT OPTION;
GRANT EXECUTE ON sa_policy_admin TO DB_ADMIN WITH GRANT OPTION;
GRANT EXECUTE ON sa_audit_admin  TO DB_ADMIN WITH GRANT OPTION;

GRANT LBAC_DBA TO DB_ADMIN;
GRANT EXECUTE ON sa_sysdba TO DB_ADMIN;
GRANT EXECUTE ON to_lbac_data_label TO DB_ADMIN;

--CONNECT DB_ADMIN/DB_ADMIN;

EXECUTE SA_SYSDBA.DROP_POLICY(policy_name => 'OLS_POLICY', drop_column => TRUE);
EXECUTE SA_SYSDBA.CREATE_POLICY(policy_name => 'OLS_POLICY', column_name => 'OLS_COL', default_options => 'ALL_CONTROL');
EXECUTE SA_SYSDBA.ENABLE_POLICY('OLS_POLICY');
SELECT * FROM ALL_SA_POLICIES;
GRANT OLS_POLICY_DBA TO admin;

BEGIN
    SA_COMPONENTS.CREATE_LEVEL (
        policy_name => 'OLS_POLICY',
        level_num   => 4,
        short_name  => 'HS',
        long_name   => 'HIGHLY_SENSITIVE');
    SA_COMPONENTS.CREATE_LEVEL (
        policy_name => 'OLS_POLICY',
        level_num   => 3,
        short_name  => 'S',
        long_name   => 'SENSITIVE');
    SA_COMPONENTS.CREATE_LEVEL (
        policy_name => 'OLS_POLICY',
        level_num   => 2,
        short_name  => 'C',
        long_name   => 'CONFIDENTIAL');
    SA_COMPONENTS.CREATE_LEVEL (
        policy_name => 'OLS_POLICY',
        level_num   => 1,
        short_name  => 'U',
        long_name   => 'UNCLASSIFIED');
    SA_COMPONENTS.CREATE_COMPARTMENT(
        policy_name => 'OLS_POLICY',
        comp_num    => 1,
        short_name  => 'BK',
        long_name   => 'BANK');
    SA_COMPONENTS.CREATE_COMPARTMENT(
        policy_name => 'OLS_POLICY',
        comp_num    => 2,
        short_name  => 'PO',
        long_name   => 'POLICE');
    SA_COMPONENTS.CREATE_COMPARTMENT(
        policy_name => 'OLS_POLICY',
        comp_num    => 3,
        short_name  => 'HP',
        long_name   => 'HOSPITAL');
--BANK GROUP    
    SA_COMPONENTS.CREATE_GROUP (
        policy_name     => 'OLS_POLICY',
        group_num       => 4,
        short_name      => 'BP',
        long_name       => 'BANK_PRESIDENT');
    SA_COMPONENTS.CREATE_GROUP (
        policy_name     => 'OLS_POLICY',
        group_num       => 3,
        short_name      => 'BM',
        long_name       => 'BANK_MANAGER',
        parent_name     => 'BP');
    SA_COMPONENTS.CREATE_GROUP (
        policy_name     => 'OLS_POLICY',
        group_num       => 2,
        short_name      => 'BS',
        long_name       => 'BANK_SUPERVISOR',
        parent_name     => 'BM');
    SA_COMPONENTS.CREATE_GROUP (
        policy_name     => 'OLS_POLICY',
        group_num       => 1,
        short_name      => 'BT',
        long_name       => 'BANK_TELLER',
        parent_name     => 'BS');
END;

SELECT * FROM ALL_SA_LEVELS;
SELECT * FROM ALL_SA_COMPARTMENTS;
SELECT * FROM ALL_SA_GROUPS;

CREATE TABLE admin.BANK_RECORDS(	
    ID int PRIMARY KEY, 
	IDENTITY_CARD_ID VARCHAR2(20), 
	NAME VARCHAR2(20), 
	DEPOSIT int, 
	LOAN int, 
	LOAN_OVERDUE_DATE DATE, 
	BANK VARCHAR2(20), 
	HANDLING VARCHAR2(20)
);
select* from admin.BANK_RECORDS;
select * from ALL_TABLES where TABLE_NAME = 'BANK_RECORDS';

CREATE OR REPLACE FUNCTION get_bank_label(HANDLING IN VARCHAR2)
RETURN LBACSYS.LBAC_LABEL AS
    label VARCHAR2(50);
    security_level VARCHAR2(10) := 'U';
BEGIN
    CASE HANDLING
        WHEN 'BP' THEN
            security_level := 'HS';
        WHEN 'BM' THEN
            security_level := 'S';
        WHEN 'BS' THEN
            security_level := 'C';
        WHEN 'BT' THEN
            security_level := 'U';
    END CASE;
    RETURN TO_LBAC_DATA_LABEL('OLS_POLICY', security_level || ':BK:' || HANDLING);
END get_bank_label;

BEGIN
  SA_POLICY_ADMIN.APPLY_TABLE_POLICY (
    policy_name => 'OLS_POLICY',
    schema_name => 'admin',
    table_name  => 'BANK_RECORDS',
    table_options => 'ALL_CONTROL',
    label_function => 'admin.get_bank_label(:new.HANDLING)');
END;

GRANT CREATE TRIGGER TO admin;

BEGIN
    SA_POLICY_ADMIN.REMOVE_TABLE_POLICY('OLS_POLICY','admin','BANK_RECORDS');
END;

select * from admin.BANK_RECORDS;
