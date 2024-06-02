SELECT per.empid , per.lname
FROM employee per , payroll pay
WHERE per.empid = pay.empid AND pay.salary = 189170
ORDER BY per.empid , per.lname;

select per1.empid, per1.lname
			from employee per1, employee per2, payroll pay1, payroll pay2
			where per1.empid = pay1.empid and per1.empid = per2.empid and pay1.empid = pay2.empid
			and pay1.salary=189170 and LENGTH(per1.lname) > 10
			order by per1.empid, per1.lname;
			
--0.23 4.34
select test('select per1.empid, per1.lname
from employee per1, employee per2, payroll pay1, payroll pay2
where per1.empid = pay1.empid and per1.empid = per2.empid and pay1.empid = pay2.empid
	and pay1.salary=189170 
order by per1.empid, per1.lname;', 1000);
			
SELECT MIN(LENGTH(per.zip))
FROM employee per , payroll pay
WHERE per.empid = pay.empid;

SELECT *
FROM employee per , payroll pay
WHERE per.empid = pay.empid AND pay.salary = 189170
ORDER BY per.empid , per.lname;


select per1.empid, per1.lname
			from employee per1, employee per2, payroll pay1, payroll pay2
			where per1.empid = pay1.empid and per1.empid = per2.empid and pay1.empid = pay2.empid
			and pay1.salary=189170 and LENGTH(per1.lname) > 10 and LENGTH(per1.fname) > 10 and LENGTH(per1.address) > 2 and LENGTH(per1.city) > 2
			and LENGTH(per1.state) > 1 and LENGTH(per1.zip) > 2
			order by per1.empid, per1.lname;