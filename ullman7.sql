drop table plan_table;

create table PLAN_TABLE (
        statement_id       varchar2(30),
        plan_id            number,
        timestamp          date,
        remarks            varchar2(4000),
        operation          varchar2(30),
        options            varchar2(255),
        object_node        varchar2(128),
        object_owner       varchar2(30),
        object_name        varchar2(30),
        object_alias       varchar2(65),
        object_instance    numeric,
        object_type        varchar2(30),
        optimizer          varchar2(255),
        search_columns     number,
        id                 numeric,
        parent_id          numeric,
        depth              numeric,
        position           numeric,
        cost               numeric,
        cardinality        numeric,
        bytes              numeric,	
        other_tag          varchar2(255),
        partition_start    varchar2(255),
        partition_stop     varchar2(255),
        partition_id       numeric,
        other              long,
        distribution       varchar2(30),
        cpu_cost           numeric,
        io_cost            numeric,
        temp_space         numeric,
        access_predicates  varchar2(4000),
        filter_predicates  varchar2(4000),
        projection         varchar2(4000),
        time               numeric,
        qblock_name        varchar2(30),
        other_xml          clob
);

EXPLAIN PLAN SET STATEMENT_ID = 'st1'
FOR
SELECT dname, job, AVG(sal)
FROM nikovits.emp
NATURAL JOIN nikovits.dept
WHERE hiredate > TO_DATE('1981.01.01','yyyy.mm.dd')
GROUP BY dname, job
HAVING SUM(sal) > 5000
ORDER BY AVG(sal) DESC;

select * from plan_table;


Select LPAD(' ',2*(level-1))||operation||' + '||options||' + '
    ||object_owner||nvl2 (object_owner,'.','')|| object_name  xplan  
    from plan_table
    start with id = 0 and statement_id ='st1'
    connect by prior id = parent_id and statement_id ='st1'
    order siblings by position;
   
    

-- if object owner is not null then return object owner then . if null then space      
--SIBLINGS = all rows with the same parent
--position = a column in PLAN_TABLE that stores the order of operations determined by the optimizer    
--When Oracle displays a hierarchical query (using CONNECT BY), rows at the same level (siblings) are 
--not guaranteed to appear in any particular order.


--===============another variant which shows the COSTS and CARDINALITIES in nodes

SELECT LPAD(' ', 2*(level-1))||operation||' + '||options||' + '
  ||object_owner||nvl2(object_owner,'.','')||object_name xplan,
  cost, cardinality, bytes, io_cost, cpu_cost
FROM plan_table
START WITH ID = 0 AND STATEMENT_ID = 'st1'                 -- 'st1' -> unique name of the statement
CONNECT BY PRIOR id = parent_id AND statement_id = 'st1'   -- 'st1'
ORDER SIBLINGS BY position;


--cost → optimizer’s estimated cost for the step
--cardinality → estimated number of rows returned
--bytes → estimated size of data (in bytes)
--io_cost → estimated I/O cost
--cpu_cost → estimated CPU cost


--It is a built-in PL/SQL procedure in Oracle used to display query execution plans in a formatted and readable way.    
    
SELECT plan_table_output
FROM TABLE(
    dbms_xplan.display('plan_table', 'st1', 'all')
);
    
    
--Exercise 2.
-------------
--Create your own copy from the following tables and answer the following query.
--QUERY
--Give the name of the departments which have an employee with salary category 1. (dname)
--NIKOVITS.EMP (empno, ename, job, mgr, hiredate, sal, comm, deptno)
--NIKOVITS.DEPT(deptno, dname, loc)
--NIKOVITS.SAL_CAT(category, lowest_sal, highest_sal)
--See the execution plan of the previous query, then create an index for any of the tables
--that can be used by the query.
--Check the new execution plan to see if it actually uses the index! 
--You should send the SQL query (with hints if needed), the OUTPUT of the query and the EXECUTION PLAN in text format!!! 

--Select Distinct d.dname from nikotvits.emp e


select * from nikovits.emp;
select * from nikovits.dept;
select * from nikovits.sal_cat;


--Give the name of the departments which have an employee with salary category 1. (dname)

-- Step 1: Create an index on EMP.sal to optimize the BETWEEN join
CREATE INDEX emp_sal_idx ON emp(sal);


--Oracle creates a B-tree structure for the column sal.
--B-tree = Balanced Tree, like a dictionary index.
--Each node contains a value of sal and a pointer (rowid) to the corresponding row in emp.

-- Step 2: Explain the plan for the query
EXPLAIN PLAN SET STATEMENT_ID = 'st2' FOR
SELECT /*+ INDEX(e emp_sal_idx) */ DISTINCT d.dname
FROM emp e
JOIN sal_cat s
  ON e.sal BETWEEN s.lowest_sal AND s.highest_sal
JOIN dept d
  ON e.deptno = d.deptno
WHERE s.category = 1;

-- Step 3: Display the execution plan in full detail
SELECT * 
FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE','st2','ALL'));




--=Compare the two similar queries in runtime_example.txt, compare the execution plans
--and tell what the difference is. Why one of them is much faster? See COST and CARDINALITY
--for the nodes.

select * from nikovits.hivas;
select * from nikovits.kozpont;
select * from nikovits.primer; 

------------------------------------------------------------
-- Set date language to Hungarian

ALTER SESSION SET nls_date_language = hungarian;  
-- 'monday' → 'h tf ' in Hungarian
------------------------------------------------------------
EXPLAIN PLAN SET STATEMENT_ID = 'slow_query' FOR
SELECT SUM(darab)
FROM nikovits.hivas h
JOIN nikovits.kozpont k ON h.kozp_azon_hivo = k.kozp_azon
JOIN nikovits.primer p ON k.primer = p.korzet
WHERE p.varos = 'Szentendre'
  AND h.datum + 1 = next_day(TO_DATE('2012.01.31', 'yyyy.mm.dd'), 'h tf ');

-- Display the plan
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'slow_query', 'ALL'));

------------------------------------------------------------
-- 2️⃣ FAST QUERY (1 sec)
------------------------------------------------------------
EXPLAIN PLAN SET STATEMENT_ID = 'fast_query' FOR
SELECT SUM(darab)
FROM nikovits.hivas h
JOIN nikovits.kozpont k ON h.kozp_azon_hivo = k.kozp_azon
JOIN nikovits.primer p ON k.primer = p.korzet
WHERE p.varos = 'Szentendre'
  AND h.datum = next_day(TO_DATE('2012.01.31', 'yyyy.mm.dd'), 'h tf ') - 1;

-- Display the plan
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'fast_query', 'ALL'));

------------------------------------------------------------


--Exercise 4.

--The owner of the following tables is NIKOVITS.
--PRODUCT(prod_id, name, color, weight)
--SUPPLIER(supl_id, name, status, address)
--PROJECT(proj_id, name, address)
--SUPPLY(supl_id, prod_id, proj_id, amount, date)
--The tables have indexes too.
select * from nikovits.product;
select * from nikovits.supplier;
select * from nikovits.project;
select * from nikovits.supply;

---- QUERY
--Give the sum amount of products where color = 'piros' ('piros' in Hungarian means 'red'). 
--
--Give hints in order to use the following execution plans:
--------------------------------------------------------------
--a) no index at all
EXPLAIN PLAN SET STATEMENT_ID = 'my_query' FOR
SELECT /*+ FULL(p) FULL(s) */ SUM(s.amount)
FROM nikovits.product p, nikovits.supply s
WHERE p.prod_id = s.prod_id
  AND p.color = 'piros';

 
Select * from Table(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'my_query','ALL'));
  


SELECT STATEMENT +  + 
  SORT + AGGREGATE + 
    HASH JOIN +  + 
      TABLE ACCESS + FULL + NIKOVITS.PRODUCT
      TABLE ACCESS + FULL + NIKOVITS.SUPPLY
--------------------------------------------------------------
--b) one index

Explain plan set Statement_id = 'second' For 
SELECT /*+ index(p) full(s) */ SUM(amount) 
FROM nikovits.product p, nikovits.supply s
WHERE p.prod_id=s.prod_id and color='piros';



Select * from Table(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'second','ALL'));

Select * from nikovits.product;
select * from nikovits.supply;
--
--SELECT STATEMENT +  + 
--  SORT + AGGREGATE + 
--    HASH JOIN +  + 
--      TABLE ACCESS + BY INDEX ROWID BATCHED + NIKOVITS.PRODUCT
--        INDEX + RANGE SCAN + NIKOVITS.PROD_COLOR_IDX  
--      TABLE ACCESS + FULL + NIKOVITS.SUPPLY
      
--  A range scan means it finds all rows where color = 'piros'.
--  Uses an index (PROD_COLOR_IDX) to find rows with color = 'piros'.
--For each row returned by the index, Oracle fetches the full row using its ROWID.
--------------------------------------------------------------


--c) index for both tables

Select * from nikovits.product;
select * from nikovits.supply;

Explain plan set statement_id ='third' for 
SELECT /*+ index(p) index(s) */ SUM(amount) FROM nikovits.product p, nikovits.supply s
WHERE p.prod_id=s.prod_id and color='piros';

select * from table(DBMS_XPLAN.DISPLAY('Plan_table', 'third' ,'All'));


--SELECT STATEMENT +  + 
--  SORT + AGGREGATE + 
--    NESTED LOOPS +  + 
--      NESTED LOOPS +  + 
--        TABLE ACCESS + BY INDEX ROWID BATCHED + NIKOVITS.PRODUCT
--          INDEX + RANGE SCAN + NIKOVITS.PROD_COLOR_IDX
--        INDEX + RANGE SCAN + NIKOVITS.SUPPLY_PROD_IDX
--      TABLE ACCESS + BY INDEX ROWID + NIKOVITS.SUPPLY
--------------------------------------------------------------
--d) SORT-MERGE join

--Access both tables (usually full scan if no index).
--Sort both row sets on the join column (prod_id).
--Merge the sorted data by matching values.

SELECT /*+ use_merge(p s) */ SUM(amount) FROM nikovits.product p, nikovits.supply s
WHERE p.prod_id=s.prod_id and color='piros';

SELECT STATEMENT +  + 
  SORT + AGGREGATE + 
    MERGE JOIN +  + 
      SORT + JOIN + 
        TABLE ACCESS + FULL + NIKOVITS.PRODUCT
      SORT + JOIN + 
        TABLE ACCESS + FULL + NIKOVITS.SUPPLY
--------------------------------------------------------------
e) NESTED-LOOPS join
SELECT /*+ use_nl(p s) */ SUM(amount) FROM nikovits.product p, nikovits.supply s
WHERE p.prod_id=s.prod_id and color='piros';

SELECT STATEMENT +  + 
  SORT + AGGREGATE + 
    NESTED LOOPS +  + 
      NESTED LOOPS +  + 
        TABLE ACCESS + FULL + NIKOVITS.PRODUCT
        INDEX + RANGE SCAN + NIKOVITS.SUPPLY_PROD_IDX
      TABLE ACCESS + BY INDEX ROWID + NIKOVITS.SUPPLY
--------------------------------------------------------------
--f) NESTED-LOOPS join and no index


SELECT /*+ ORDERED USE_NL(p s) NO_INDEX(s) */ 
       SUM(s.amount) AS total_amount
FROM nikovits.product p,
     nikovits.supply s
WHERE p.prod_id = s.prod_id
  AND p.color = 'piros';



--SELECT STATEMENT +  + 
--  SORT + AGGREGATE + 
--    NESTED LOOPS +  + 
--      TABLE ACCESS + FULL + NIKOVITS.PRODUCT
--      TABLE ACCESS + FULL + NIKOVITS.SUPPLY
      
      
--where for each row from the outer table, the database searches for matching rows in the inner table.      
--------------------------------------------------------------
g) HASH join
SELECT /*+ use_hash(p s)  */ SUM(amount) FROM nikovits.product p, nikovits.supply s
WHERE p.prod_id=s.prod_id and color='piros';

--SELECT STATEMENT +  + 
--  SORT + AGGREGATE + 
--    HASH JOIN +  + 
--      TABLE ACCESS + FULL + NIKOVITS.PRODUCT
--      TABLE ACCESS + FULL + NIKOVITS.SUPPLY







