EXECUTE SA_COMPONENTS.CREATE_LEVEL('human_resources',50,'L3','Level 3');
EXECUTE SA_COMPONENTS.CREATE_LEVEL('human_resources',30,'L2','Level 2');
EXECUTE SA_COMPONENTS.CREATE_LEVEL('human_resources',10,'L1','Level 1');

EXECUTE SA_COMPONENTS.CREATE_COMPARTMENT('human_resources',100,'M','MANAGEMENT');
EXECUTE SA_COMPONENTS.CREATE_COMPARTMENT('human_resources',110,'E','EMPLOYEE');

EXECUTE SA_COMPONENTS.CREATE_GROUP('human_resources',10,'D10','DEPARTMENT 10');
EXECUTE SA_COMPONENTS.CREATE_GROUP('human_resources',20,'D20','DEPARTMENT 20');
EXECUTE SA_COMPONENTS.CREATE_GROUP('human_resources',30,'D30','DEPARTMENT 30');
EXECUTE SA_COMPONENTS.CREATE_GROUP('human_resources',40,'D40','DEPARTMENT 40');

EXECUTE SA_USER_ADMIN.SET_USER_PRIVS('human_resources','sa_demo','FULL');
EXECUTE SA_USER_ADMIN.SET_USER_PRIVS('human_resources','hr_admin','FULL,PROFILE_ACCESS');

BEGIN
  SA_POLICY_ADMIN.APPLY_TABLE_POLICY('human_resources',
                                     'sa_demo','emp','no_control');
END;

UPDATE SA_DEMO.EMP SET hr_label = CHAR_TO_LABEL('human_resources','L1');
COMMIT;

BEGIN
   SA_POLICY_ADMIN.REMOVE_TABLE_POLICY('human_resources','sa_demo','emp');
   SA_POLICY_ADMIN.APPLY_TABLE_POLICY (
     POLICY_NAME => 'human_resources',
     SCHEMA_NAME => 'sa_demo',
     TABLE_NAME  => 'emp',
     TABLE_OPTIONS => 'no_control',
     LABEL_FUNCTION => 'sa_demo.gen_emp_label(:new.job,:new.deptno,:new.sal)',
     PREDICATE => NULL);
END;

select * from SA_DEMO.EMP;

UPDATE SA_DEMO.EMP SET deptno=deptno;
COMMIT;

col hr_label format a15
SELECT empno, sal, deptno, label_to_char(hr_label) AS hr_label FROM SA_DEMO.EMP;

COLUMN policy_name FORMAT A15
COLUMN label FORMAT A15
SELECT * FROM DBA_SA_LABELS WHERE policy_name='HUMAN_RESOURCES' 
    ORDER BY POLICY_NAME, LABEL_TAG;
    


BEGIN
   SA_POLICY_ADMIN.REMOVE_TABLE_POLICY('human_resources','sa_demo','emp');
   SA_POLICY_ADMIN.APPLY_TABLE_POLICY (
     POLICY_NAME => 'human_resources',
     SCHEMA_NAME => 'sa_demo',
     TABLE_NAME  => 'emp',
     TABLE_OPTIONS => 'READ_CONTROL,WRITE_CONTROL,CHECK_CONTROL',
     LABEL_FUNCTION => 'sa_demo.gen_emp_label(:new.job,:new.deptno,:new.sal)',
     PREDICATE => NULL);
END;

EXECUTE SA_USER_ADMIN.SET_PROG_PRIVS('Human_resources','sa_demo','average_sal','READ');

EXECUTE SA_USER_ADMIN.SET_USER_LABELS('human_resources','PRES','L3:M,E');
EXECUTE SA_USER_ADMIN.SET_USER_LABELS('human_resources','MD10','L3:M,E:D10');
EXECUTE SA_USER_ADMIN.SET_USER_LABELS('human_resources','ED10','L3:E:D10');
EXECUTE SA_USER_ADMIN.SET_USER_LABELS('human_resources','ED20','L3:E:D20');

EXECUTE SA_USER_ADMIN.ALTER_COMPARTMENTS('human_resources','PRES','E',sa_utl.read_only);


SELECT * FROM DBA_SA_POLICIES ORDER BY policy_name;
SELECT * FROM DBA_SA_LABELS ORDER BY policy_name, label_tag;
SELECT * FROM DBA_SA_USERS ORDER BY policy_name, user_name;
SELECT * FROM DBA_SA_PROG_PRIVS ORDER BY policy_name, schema_name, program_name;
SELECT * FROM DBA_SA_SCHEMA_POLICIEs ORDER BY policy_name, schema_name;
SELECT * FROM DBA_SA_TABLE_POLICIES ORDER BY policy_name, schema_name, table_name;

SELECT avg(sal) FROM SA_DEMO.EMP;
--EXECUTE SA_SESSION.SET_ACCESS_PROFILE('human_resources','ED10');
--SELECT avg(sal) FROM SA_DEMO.EMP;

