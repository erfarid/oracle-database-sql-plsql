drop table emp;
drop table dept;
drop table sal_Cat;


create table emp as select * from nikovits.emp;
create table sal as select * from nikovits.sal_cat;
create table dept as select * from nikovits.dept;

--NIKOVITS.EMP     (empno, ename, job, mgr, hiredate, sal, comm, deptno)
--NIKOVITS.DEPT    (deptno, dname, loc)
--NIKOVITS.SAL_CAT (category, lowest_sal, highest_sal)

--TASKS (same as your exam question)
--1. Create your own copies of these three tables.
--2. Write a SQL query that returns:
--Employee names (ename)
--Who work in DALLAS
--AND whose salary belongs to salary category = 3
--3. View the execution plan of your query using EXPLAIN PLAN.
--4. Create an index on any table/column that might be used by this query.
--5. Generate the execution plan again and check if Oracle used the index.

select * from dept;

Explain plan set statement_id ='multiple' for 
select /*+ index( emp indx_Sal)  */ e.ename from emp e 
join dept d on e.deptno = d.deptno
join sal_cat sal on e.sal between sal.lowest_Sal and sal.highest_sal where sal.category =3 and d.loc ='DALLAS';



select plan_table_output from table(dbms_xplan.display('plan_table','multiple','all'));

create index indx_Sal on emp(sal);

select plan_table_output from table(dbms_xplan.display('plan_table','multiple','all'));


--=========================

--question 2

--Give the departments (dname) where the average salary of employees is greater than 2000 
--and there is at least one employee in salary category 2.
--
--NIKOVITS.EMP     (empno, ename, job, mgr, hiredate, sal, comm, deptno)
--NIKOVITS.DEPT    (deptno, dname, loc)
--NIKOVITS.SAL_CAT (category, lowest_sal, highest_sal)
explain plan set Statement_id ='try2' for 
select /*+ index(dept index_sal) */d.dname from dept d 
join emp e on d.deptno =e.deptno
join sal s on e.sal between s.lowest_Sal and s.highest_sal group by d.dname having avg(e.sal) > 2000
and sum(case when s.category =2  then 1 else 0 end ) > 2;


select plan_table_output from table(dbms_xplan.display('plan_table','multiple','all'));
create index index_sal on dept(loc);

select plan_table_output from table(dbms_xplan.display('plan_table','multiple','all'));



--==============================================
-- The tables have indexes too.
--CREATE INDEX prod_color_idx ON product(color);
--CREATE UNIQUE INDEX prod_id_idx ON product(prod_id);
--CREATE UNIQUE INDEX proj_id_idx ON PROJECT(proj_id);
--CREATE UNIQUE INDEX supplier_id_idx ON supplier(supl_id);
--CREATE INDEX supply_supplier_idx ON supply(supl_id);
--CREATE INDEX supply_proj_idx ON supply(proj_id);
--CREATE INDEX supply_prod_idx ON supply(prod_id);


--PRODUCT(prod_id, name, color, weight)
--SUPPLIER(supl_id, name, status, address)
--PROJECT(proj_id, name, address)
--SUPPLY(supl_id, prod_id, proj_id, amount, sDate)

--QUERY
-------
--Give the sum amount of products where color = 'piros' ('piros' in Hungarian means 'red'). 
explain plan set statement_id='1st' for
select /*+ full(p) full(s)*/ sum(s.amount) from product p  , supply s 
where  p.prod_id =s.prod_id and p.color ='piros';


select plan_table_output from table(dbms_xplan.display('plan_table','1st','all'));
--b) one index

explain plan set statement_id='2nd' for
select /*+ index(p) full(s) */ sum(s.amount) from product p  , supply s 
where  p.prod_id =s.prod_id and p.color ='piros';

select plan_table_output from table(dbms_xplan.display('plan_table','2nd','all'));


--c) index for both tables

Explain plan set statement_id ='3rd' for
select /*+ index(p) index(s) */ sum(s.amount) from product p  , supply s 
where  p.prod_id = s.prod_id and p.color ='piros';

select plan_table_output from table(dbms_xplan.display('plan_table','3rd','all'));

--d) SORT-MERGE join
Explain plan set statement_id ='4th' for
select /*+ USE_MERGE(p,s) */ sum(s.amount) from product p  , supply s 
where  p.prod_id = s.prod_id and p.color ='piros';

select plan_table_output from table(dbms_xplan.display('plan_table','4th','all'));

--e) NESTED-LOOPS join
Explain plan set statement_id ='5th' for
SELECT /*+ use_nl(p s) */ SUM(amount) FROM nikovits.product p, nikovits.supply s
WHERE p.prod_id=s.prod_id and color='piros';




--QUERY
--Give the total amount (SUM(amount)) of red products ('piros') 
--supplied by suppliers whose status is greater than 10,
--to projects located in Budapest.

--PRODUCT(prod_id, name, color, weight)--
--SUPPLIER(supl_id, name, status, address) this 
--PROJECT(proj_id, name, address)
--SUPPLY(supl_id, prod_id, proj_id, amount, sDate) this 

SELECT SUM(s.amount)
FROM supply s JOIN product p 
    ON s.prod_id = p.prod_id
JOIN supplier spr 
    ON spr.supl_id = s.supl_id
JOIN project prj 
    ON prj.proj_id = s.proj_id
WHERE p.color = 'piros'
  AND spr.status > 10
  AND prj.address = 'Budapest';


--SUBTASKS — Use Hints Below


--a) Execute the query with no hint and no index.

--b) Execute the query using one index of your choice.
--c) Execute the query using indexes on all useful tables.
--d) Force a SORT-MERGE join between all tables.
--e) Force a NESTED-LOOPS join.
--f) Force a NESTED-LOOPS join with NO INDEX on any table.
--g) Force a HASH JOIN between all tables.
--h) Use LEADING(...) to force the join order: PRODUCT → SUPPLY → SUPPLIER → PROJECT
--i) Use FIRST_ROWS(1) and compare the execution plan with ALL_ROWS.
--j) Use USE_CONCAT by rewriting the WHERE condition as two OR-conditions logically equivalent to the query.
