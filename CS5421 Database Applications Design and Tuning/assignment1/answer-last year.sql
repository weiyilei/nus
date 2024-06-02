-- SELECT per.empid , per.lname
-- FROM employee per , payroll pay
-- WHERE per.empid = pay.empid AND pay.salary = 189170
-- ORDER BY per.empid , per.lname;

-- -- 2a
-- SELECT per.empid , per.lname
-- FROM employee per RIGHT OUTER JOIN payroll pay ON TRUE AND pay.salary = 189170
-- WHERE TRUE
-- ORDER BY per.empid , per.lname;
-- -- 2a answer:
-- SELECT per.empid , per.lname
-- FROM employee per RIGHT OUTER JOIN payroll pay ON per.empid = pay.empid AND pay.salary = 189170
-- WHERE per.empid IS NOT NULL
-- ORDER BY per.empid , per.lname;

-- -- 2b
-- SELECT per.empid , per.lname
-- FROM employee per, (SELECT TRUE) AS temp
-- WHERE TRUE
-- ORDER BY per.empid , per.lname;

-- -- 2b answer
-- SELECT per.empid , per.lname
-- FROM employee per, (SELECT pay.empid FROM payroll pay WHERE pay.salary = 189170) AS temp
-- WHERE per.empid = temp.empid
-- ORDER BY per.empid , per.lname;

-- 2c
-- SELECT per.empid , per.lname FROM employee per
-- WHERE NOT EXISTS ( SELECT TRUE)
-- ORDER BY per.empid , per.lname;

-- -- 2c answer
-- SELECT per.empid , per.lname FROM employee per
-- WHERE NOT EXISTS (SELECT pay.empid FROM payroll pay WHERE pay.salary <> 189170 AND per.empid = pay.empid)
-- ORDER BY per.empid , per.lname;


-- -- 3 answer
-- SELECT per1.empid, per1.lname 
-- FROM employee per1, employee per2, payroll pay1, payroll pay2
-- WHERE per1.empid = pay1.empid AND per1.empid = per2.empid AND pay1.empid = pay2.empid AND pay1.salary = 189170
-- ORDER BY per1.empid , per1.lname;


-- SELECT test('
-- SELECT per1.empid, per1.lname 
-- FROM employee per1, employee per2, payroll pay1, payroll pay2
-- WHERE per1.empid = pay1.empid AND per1.empid = per2.empid AND pay1.empid = pay2.empid AND pay1.salary = 189170
-- ORDER BY per1.empid , per1.lname;
--  		',1000);
