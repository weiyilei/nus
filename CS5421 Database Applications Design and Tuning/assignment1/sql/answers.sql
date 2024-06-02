/******************************************************************************/
/* Fabian Pascal                                                              */
/* Indicate your student number here: A0276571W                               */
/******************************************************************************/
 SELECT per.empid, per.lname 
 FROM employee per, payroll pay
 WHERE per.empid = pay.empid 
 AND pay.salary = 189170;
 
/******************************************************************************/
/* Answer Question 2.a below                                                  */
/******************************************************************************/
select per.empid, per.lname
from employee per RIGHT OUTER JOIN payroll pay
	on per.empid=pay.empid and pay.salary=189170
where per.empid IS NOT NULL
order by per.empid, per.lname;
	
/******************************************************************************/
/* Answer Question 2.b below                                                  */
/******************************************************************************/
select per.empid, per.lname
from employee per
where not exists(
	select 1 from payroll pay where per.empid = pay.empid and pay.salary!=189170)
order by per.empid, per.lname;

/******************************************************************************/
/* Answer Question 3 below                                                  */
/******************************************************************************/
select per1.empid, per1.lname
from employee per1, employee per2, payroll pay1, payroll pay2
where per1.empid = pay1.empid and per1.empid = per2.empid and pay1.empid = pay2.empid
	and pay1.salary=189170 
order by per1.empid, per1.lname;

-- Indicate the average measured time for 1000 executions for the query.
-- (replace <time> below with the average time reported by test function,
-- Average Planning 0.23 ms
-- Average Execution 4.34 ms
