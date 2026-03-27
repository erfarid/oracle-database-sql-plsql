--1.
--Give the names and sizes of the database data files (*.dbf). (file_name, size_in_bytes)
--DBA_DATA_FILES is a data dictionary view in Oracle that shows detailed information about all data files in the entire database.



Select file_name , bytes from dba_data_files;

Select * from dba_data_files;

--| Column              | Description                                                     |
--| ------------------- | --------------------------------------------------------------- |
--| **FILE_NAME**       | The full OS path and name of the `.dbf` file.                   |
--| **FILE_ID**         | The internal numeric ID of the data file.                       |
--| **TABLESPACE_NAME** | The tablespace this file belongs to.                            |
--| **BYTES**           | The total size of the file in **bytes**.                        |
--| **BLOCKS**          | Number of Oracle database blocks in the file.                   |
--| **STATUS**          | Indicates if the file is `AVAILABLE`, `INVALID`, or `OFFLINE`.  |
--| **AUTOEXTENSIBLE**  | `YES` if Oracle can automatically increase the file size.       |
--| **MAXBYTES**        | The maximum size to which the file can autoextend.              |
--| **INCREMENT_BY**    | How much space (in blocks) is added each time the file extends. |
--| **ONLINE_STATUS**   | Shows if the file is `ONLINE`, `OFFLINE`, or `RECOVER`.         |


--2.
--Give the names of the tablespaces in the database. (tablespace_name)

Select tablespace_name from dba_data_files;


--3.
--Which datafile belongs to which tablespace? List them. (filename, tablespace_name)


select file_name ,tablespace_name from dba_data_files;




--4.
--Is there a tablespace that doesn't have any datafile in dba_data_files? -> see dba_temp_files





select * from dba_temp_files;



Select tablespace_name from dba_tablespaces WHERE tablespace_name NOT IN (SELECT tablespace_name FROM dba_data_files);

--DBA_TEMP_FILES → lists temporary datafiles (used by temporary tablespaces, like TEMP).
SELECT tablespace_name FROM dba_tablespaces;

SELECT * FROM dba_tablespaces;

--A tablespace is a logical storage unit in an Oracle database.
--Think of it as a container that holds database objects such as:
--Tables
--Indexes
--Materialized views
--Temporary segments (for sorting, joins, etc.)



--5.
--What is the datablock size in USERS tablespace? (block_size)


SELECT tablespace_name, block_size FROM dba_tablespaces WHERE tablespace_name = 'USERS';

--6.
--Find some segments whose owner is NIKOVITS. What segment types do they have? List the types. (segment_type)


select * from dba_segments;


SELECT DISTINCT segment_type FROM dba_segments WHERE owner = 'NIKOVITS';


--7.
--How many extents are there in file 'users02.dbf' ? (num_extents)
--How many bytes do they occupy? (sum_bytes)

Select * from dba_extents;
select * from dba_data_files;
    

SELECT COUNT(*) AS num_extents , SUM(bytes) AS sum_bytes 
FROM dba_extents WHERE file_id = ( SELECT file_id FROM dba_data_files WHERE file_name LIKE '%users02.dbf');

--Tablespace → Datafile → Segment → Extent → Data Blocks

--In Oracle, an extent is a contiguous set of data blocks that the database allocates to a segment (like a table, index, or LOB).
--Segment → the storage allocated for a database object.
--Extent → a chunk of storage within a segment.
--Data block → the smallest unit of storage; multiple blocks make an extent.


--8.
--How many free extents are there in file 'users02.dbf', and what is the summarized size of them ? (num, sum_bytes)
--How many percentage of file 'users02.dbf' is full (allocated to some object)?

SELECT  COUNT(*) AS num_free_extents, SUM(BYTES) AS sum_bytes FROM DBA_FREE_SPACE WHERE 
FILE_ID = (SELECT FILE_ID FROM DBA_DATA_FILES
               WHERE FILE_NAME LIKE '%users02.dbf%');

Select *  from dba_free_space;


--What is DBA_FREE_SPACE?
--DBA_FREE_SPACE is a data dictionary view in Oracle that shows all the free (unused) space in tablespaces and datafiles.
--Think of it as a map of all gaps in your database files where Oracle can put new data.

--
--| Column            | Meaning                                                                 |
--| ----------------- | ----------------------------------------------------------------------- |
--| `FILE_ID`         | The ID of the datafile the free space belongs to.                       |
--| `TABLESPACE_NAME` | Name of the tablespace the free space is in.                            |
--| `BYTES`           | Size of the free space in bytes.                                        |
--| `BLOCKS`          | Number of database blocks in this free extent.                          |
--| `OWNER`           | Usually NULL for free space (because it’s not allocated to any object). |

SELECT 
    ROUND(100 * (1 - SUM(F.BYTES) / D.BYTES), 2) AS pct_full
FROM 
    DBA_DATA_FILES D
LEFT JOIN 
    DBA_FREE_SPACE F
ON 
    D.FILE_ID = F.FILE_ID
WHERE 
    D.FILE_NAME LIKE '%users02.dbf%';




--9.
--Who is the owner whose objects occupy the most space in the database? (owner, sum_bytes)

select * from dba_segments;

SELECT 
    OWNER, 
    SUM(BYTES) AS sum_bytes
FROM 
    DBA_SEGMENTS
GROUP BY 
    OWNER
ORDER BY 
    SUM(BYTES) DESC
FETCH FIRST 1 ROWS ONLY;


--10 Is there a table of owner NIKOVITS that has extents in at least two different datafiles? (table_name)

SELECT 
    owner,
    segment_name AS table_name
FROM 
    dba_extents
WHERE 
    owner = 'NIKOVITS'
    AND segment_type = 'TABLE'
GROUP BY 
    owner, segment_name
HAVING 
    COUNT(DISTINCT file_id) >= 2;
    
    
    

--    11.
--On which tablespace is the table ORAUSER.dolgozo?



SELECT owner, table_name, tablespace_name
FROM dba_tables
WHERE owner = 'ORAUSER' AND table_name = 'DOLGOZO';


--On which tablespace is the table NIKOVITS.eladasok? Why NULL? 
-- (-> partitioned table, stored on more than 1 tablespace)
-------------------------------------------------------

---DBA_TABLES is an Oracle data dictionary view that shows 
--information about all tables in the entire database — for all users (schemas).



select * from dba_tables;

--On which tablespace is the table NIKOVITS.eladasok? Why NULL? 
-- (-> partitioned table, stored on more than 1 tablespace)
---------------------------------------------------------


SELECT table_name, tablespace_name FROM dba_tables WHERE owner = 'ORAUSER' AND table_name = 'DOLGOZO';


--
--12.
--Write a PL/SQL procedure, which prints out for the parameter user his/her newest table (which was created last),
--the size of the table in bytes (the size of the table's segment) and the creation date. 
--The output format should be the following.
--(Number of spaces doesn't count between the columns, date format is yyyy.mm.dd.hh24:mi)
--
--Table_name: NNNNNN   Size: SSSSSS bytes   Created: yyyy.mm.dd.hh:mi
--
--CREATE OR REPLACE PROCEDURE newest_table(p_user VARCHAR2) IS 
--...
--SET SERVEROUTPUT ON
--execute newest_table('nikovits');


CREATE OR REPLACE PROCEDURE newest_table(p_user VARCHAR2) IS
    v_table_name   VARCHAR2(100);
    v_created_date DATE;
    v_size_bytes   NUMBER;
BEGIN
    -- Find the newest table (created last)
    SELECT object_name, created
    INTO v_table_name, v_created_date
    FROM (
        SELECT object_name, created
        FROM dba_objects
        WHERE owner = UPPER(p_user)
          AND object_type = 'TABLE'
        ORDER BY created DESC
    )
    WHERE ROWNUM = 1;

    -- Find its size in bytes
    SELECT NVL(SUM(bytes), 0) ---ensure v_size_bytes is 0 instead of Null 
    INTO v_size_bytes 
    FROM dba_segments
    WHERE owner = UPPER(p_user)
      AND segment_name = v_table_name
      AND segment_type = 'TABLE';

    -- Print result
    DBMS_OUTPUT.PUT_LINE(
        'Table_name: ' || v_table_name ||
        '   Size: ' || v_size_bytes || ' bytes   ' ||
        'Created: ' || TO_CHAR(v_created_date, 'yyyy.mm.dd.hh24:mi')
    );

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No tables found for user ' || p_user);
END;
/


SET SERVEROUTPUT ON execute newest_table('nikovits');
