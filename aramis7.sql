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

