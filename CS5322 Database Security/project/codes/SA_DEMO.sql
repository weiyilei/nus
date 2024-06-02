EXECUTE SA_SYSDBA.CREATE_POLICY('human_resources','hr_label');
GRANT HUMAN_RESOURCES_DBA TO HR_ADMIN;

GRANT EXECUTE ON sa_components TO HR_ADMIN;
GRANT EXECUTE ON sa_user_admin TO HR_ADMIN;
GRANT EXECUTE ON sa_user_admin TO HR_ADMIN;
GRANT EXECUTE ON sa_label_admin TO HR_ADMIN;
GRANT EXECUTE ON sa_policy_admin TO HR_ADMIN;
GRANT EXECUTE ON sa_audit_admin TO HR_ADMIN;

CREATE TABLE SA_DEMO.DEPT (
 DEPTNO              NUMBER(2) NOT NULL,
 DNAME               VARCHAR2(14),
 LOC                 VARCHAR2(13),
 CONSTRAINT DEPT_PRIMARY_KEY PRIMARY KEY (DEPTNO));

GRANT SELECT, INSERT, UPDATE, DELETE ON DEPT to PUBLIC;

INSERT INTO SA_DEMO.DEPT VALUES (10,'ACCOUNTING','NEW YORK');
INSERT INTO SA_DEMO.DEPT VALUES (20,'RESEARCH','DALLAS');
INSERT INTO SA_DEMO.DEPT VALUES (30,'SALES','CHICAGO');
INSERT INTO SA_DEMO.DEPT VALUES (40,'OPERATIONS','BOSTON');

COMMIT;

SELECT * from SA_DEMO.DEPT;

CREATE TABLE SA_DEMO.EMP (
 EMPNO               NUMBER(4) NOT NULL,
 ENAME               VARCHAR2(10),
 JOB                 VARCHAR2(9),
 MGR                 NUMBER(4),
 HIREDATE            DATE,
 SAL                 NUMBER(7,2),
 COMM                NUMBER(7,2),
 DEPTNO              NUMBER(2) NOT NULL,
 CONSTRAINT EMP_PRIMARY_KEY PRIMARY KEY (EMPNO));

GRANT SELECT, INSERT, UPDATE, DELETE ON EMP TO PUBLIC;

INSERT INTO SA_DEMO.EMP (EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO)
	VALUES (7839,'KING','PRESIDENT',NULL,TO_DATE('17-11ÔÂ-1981', 'DD-MON-YYYY'),5000,NULL,10);
INSERT INTO SA_DEMO.EMP (EMPNO,ENAME,JOB,MGR,HIREDATE,SAL,COMM,DEPTNO)
	VALUES (7698,'BLAKE','MANAGER',7839,TO_DATE('01-5ÔÂ-1981', 'DD-MON-YYYY'),2850,NULL,30);

COMMIT;

select * from SA_DEMO.EMP;

CREATE OR REPLACE FUNCTION sa_demo.gen_emp_label
                 (Job varchar2, 
                  Deptno number, 
                  Total_sal number)
  Return LBACSYS.LBAC_LABEL
as
  i_label  varchar2(80);
Begin
  /* Determine Class Level */
  if total_sal > 2000 then 
     i_label := 'L3:';
  elsif total_sal >1000 then 
     i_label := 'L2:';
  else
     i_label := 'L1:';
  end if;

  /* Determine Compartment */
  IF TRIM(' ' from UPPER(Job)) in ('MANAGER','PRESIDENT') then 
     i_label := i_label||'M:';
  else
     i_label := i_label||'E:';
  end if;
  /* Determine Groups */
  i_label := i_label||'D'||to_char(deptno);
  return TO_LBAC_DATA_LABEL('human_resources',i_label);
End;

SHOW ERRORS;

CREATE OR REPLACE FUNCTION sa_demo.average_sal
RETURN NUMBER IS
   a NUMBER;
BEGIN
   SELECT avg(sal) INTO a FROM emp;
   RETURN a;
END;
/
GRANT EXECUTE ON average_sal TO PUBLIC;