-- Step 1: create table
CREATE TABLE PR01 (
    table_name VARCHAR2(128)
);


--here i need to specify the column in which i need to insert
-- Step 2: insert table names
INSERT INTO PR01 (table_name) 
SELECT table_name
FROM dba_tables
WHERE owner = 'NIKOVITS'
  AND table_name LIKE '%B%';

-- Step 3: check
SELECT * FROM PR01;



--1.
--Who is the owner of the view DBA_TABLES? Who is the owner of table DUAL? (owner)

select * from dba_tables ;

SELECT owner FROM all_objects WHERE object_name = 'DBA_TABLES' AND object_type = 'VIEW';

SELECT owner FROM all_objects WHERE object_name = 'Dual' AND object_type = 'TABLE';


--2 who is the owner of synonym DBA_TABLES? (or synonym DUAL) (owner)
SELECT OWNER, SYNONYM_NAME, TABLE_OWNER, TABLE_NAME FROM ALL_SYNONYMS WHERE SYNONYM_NAME = 'DUAL';

--from sys
SELECT OWNER, SYNONYM_NAME, TABLE_OWNER, TABLE_NAME FROM ALL_SYNONYMS WHERE SYNONYM_NAME = 'DBA_TABLES';

Select * from ALL_SYNONYMS;
        
--3 kind of objects the database user ORAUSER has? (dba_objects.object_type column)

SELECT DISTINCT object_type FROM dba_objects WHERE owner = 'ORAUSER';

--4 What are the object types existing in the database? (object_type)


Select * from  DBA_OBJECTS;

Select distinct object_type from dba_objects order by object_type; 


--5 which users have more than 10 different kind of objects in the database? (owner)

Select owner from dba_objects group by owner having count(distinct object_type) >10;

--6 Which users have both triggers and views in the database? (owner)

Select owner from dba_objects where object_type In ('TRIGGER','VIEW') Group by owner Having COUNT(DISTINCT object_type) = 2;


--7Which users have views but don't have triggers? (owner)

Select owner from dba_objects Group by owner Having count(case when object_type ='VIEW' then 1 end) > 0 and 
count(case when object_type='TRIGGER' then 1 end )=0;


--8 Which users have more than 40 tables, but less than 30 indexes? (owner)


--remember object type is a column that stores the differnet object type 

Select owner from dba_objects Group by owner Having count(case when object_type='TABLE' then 1 end ) > 40
 and count(case when object_type = 'INDEX' then 1 end ) < 30;
 
 
 
-- 9.
--Let's see the difference between a table and a view (dba_objects.data_object_id).


--About DATA_OBJECT_ID
--DATA_OBJECT_ID is a column in DBA_OBJECTS.
--Purpose:
--It links an object to its underlying data segment in the database.
--For tables and some other objects (like clusters), DATA_OBJECT_ID is not null because there is actual storage allocated.
--For views, DATA_OBJECT_ID is usually NULL because a view does not store data; it’s just a virtual table based on a query.


SELECT owner, object_name, object_type, data_object_id FROM dba_objects WHERE object_type IN ('TABLE', 'VIEW') ORDER BY object_type, owner;


--10 Which object types have NULL (or 0) in the column data_object_id? (object_type)

Select distinct object_type from dba_objects where data_object_id IS NULL OR data_object_id=0 order by object_type;

--11.
--Which object types have non NULL (and non 0) in the column data_object_id? (object_type)

Select distinct object_type from dba_objects where data_object_id IS not NULL OR data_object_id <> 0 order by object_type;

--
--12.
--What is the intersection of the previous 2 queries? (object_type)

SELECT DISTINCT object_type
FROM dba_objects
WHERE data_object_id IS NULL
   OR data_object_id = 0

INTERSECT

SELECT DISTINCT object_type
FROM dba_objects
WHERE data_object_id IS NOT NULL
  AND data_object_id <> 0;


--Columns of a table
--------------------
--(DBA_TAB_COLUMNS)
--
--13.
--How many columns nikovits.emp table has? (num)

Select * from DBA_TAB_COLUMNS ;
select count(*) as num from dba_tab_columns where owner ='NIKOVITS' and table_name ='EMP';


--14.What is the data type of the 6th column of the table nikovits.emp? (data_type)

SELECT *
FROM dba_tab_columns
WHERE owner = 'NIKOVITS'
  AND table_name = 'EMP';
  
  
  
SELECT data_type
FROM dba_tab_columns
WHERE owner = 'NIKOVITS'
  AND table_name = 'EMP'
  AND column_id = 6;
  
  
  
--  15  Give the owner and name of the tables which have column name beginning with letter 'Z'.
--(owner, table_name)

SELECT DISTINCT owner, table_name ,column_name FROM dba_tab_columns WHERE column_name LIKE 'Z%';


Select * from dba_tab_columns;
--16.
--Give the owner and name of the tables which have at least 8 columns with data type DATE.
--(owner, table_name)

SELECT owner, table_name, COUNT(*) AS date_columns
FROM dba_tab_columns
WHERE data_type = 'DATE'
GROUP BY owner, table_name
HAVING COUNT(*) >= 8
ORDER BY owner, table_name;


--17.
--Give the owner and name of the tables whose 1st and 4th column's datatype is VARCHAR2.
select owner,table_name from dba_tab_columns  where column_id in (1,4) and data_type = 'VARCHAR2' group by owner,table_name having count(*)=2;

--
--CREATE OR REPLACE PROCEDURE procedure_name(parameter_list) IS
--BEGIN
--    -- your code here
--END;
--/


--18.
--Write a PL/SQL procedure, which prints out the owners and names of the tables beginning with the 
--parameter character string. 
--CREATE OR REPLACE PROCEDURE table_print(p_char VARCHAR2) IS
--...
--set serveroutput on
--execute table_print('V');
--|| this is use for string concatenation 

create or replace procedure table_print(p_char varchar) IS
Begin
  for rec in( 
  Select owner,table_name
  from dba_tables
  where table_name LIKE UPPER(p_char)|| '%'
  order by owner,table_name 
  )LOOP
  DBMS_OUTPUT.PUT_LINE('Owner: ' || rec.owner || ', Table: ' || rec.table_name);    
  END LOOP;
END;
  
/

execute table_print('v');
--rec is a record variable that temporarily holds the values of one row 
select table_name from user_tables;
