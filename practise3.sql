--
--1.
--How many data blocks are allocated in the database for the table NIKOVITS.CIKK?
--There can be empty blocks, but we count them too.
--The same question: how many data blocks does the segment of the table have?

SELECT * FROM dba_segments WHERE owner='NIKOVITS'
AND segment_name='CIKK' AND segment_type='TABLE'; -- answer: Blocks column





---------------------------------------------------------
--2.
--How many filled data blocks does the previous table have?
--Filled means that the block is not empty (there is at least one row in it).
--This question is not the same as the previous !!!
--How many empty data blocks does the table have?

--Every row in an Oracle table has a unique ROWID, which encodes:
--File number – where the row is stored (datafile ID)
--Block number – the specific data block inside the file
--Row number – position of the row inside that block


SELECT DISTINCT 
    dbms_rowid.rowid_relative_fno(ROWID) AS file_id,
    dbms_rowid.rowid_object(ROWID)       AS data_object,
    dbms_rowid.rowid_block_number(ROWID) AS block_nr
FROM nikovits.cikk;

-- The number of these data blocks:
SELECT count(*) FROM
(SELECT DISTINCT dbms_rowid.rowid_relative_fno(ROWID) file_id, 
 dbms_rowid.rowid_object(ROWID) data_object, dbms_rowid.rowid_block_number(ROWID) block_nr
 FROM nikovits.cikk);

------------------------------------------------------------
--3.
--How many rows are there in each block of the previous table?

--🔹 Why Both File + Block?
--Block numbers are unique only inside a single file
--Two different files can have a block 45, but these are completely different physical blocks.
--If you grouped only by block number, rows from different files but same block number would be counted together incorrectly

SELECT dbms_rowid.rowid_relative_fno(ROWID) file_no,
       dbms_rowid.rowid_block_number(ROWID) block_no, count(*)
FROM nikovits.cikk
GROUP BY dbms_rowid.rowid_block_number(ROWID), dbms_rowid.rowid_relative_fno(ROWID);

------------------------------------------------------
--4.
--There is a table NIKOVITS.ELADASOK which has the following row:
--szla_szam = 100 (szla_szam is a column name)
--In which datafile is the given row stored?
--Within the datafile in which block? (block number) 
--In which data object? (Give the name of the segment.)


Select * from NIKOVITS.ELADASOK;



SELECT dbms_rowid.rowid_relative_fno(ROWID) file_id, dbms_rowid.rowid_object(ROWID) data_object,
dbms_rowid.rowid_block_number(ROWID) block_nr, dbms_rowid.rowid_row_number(ROWID) row_nr 
FROM nikovits.eladasok WHERE szla_szam = 100;

SELECT * FROM dba_data_files WHERE file_id=2;             -- in ULLMAN database
SELECT * FROM dba_objects WHERE data_object_id=81153;

-- We combine the previous two together:
SELECT dbms_rowid.rowid_relative_fno(e.ROWID) file_id, f.file_name 
FROM nikovits.eladasok e, dba_data_files f
WHERE szla_szam = 100 AND dbms_rowid.rowid_relative_fno(e.ROWID)=f.file_id;

--> The table is stored specially, it is a PARTITIONED table, having 3 segments. See the following query:
SELECT * FROM dba_objects WHERE OWNER='NIKOVITS' AND object_name LIKE 'ELADASOK';
-------------------------------------------------------
--5.
--Write a PL/SQL procedure which prints out the number of rows in each data block for the 
--following table: NIKOVITS.TABLA_123. (Output format: file_id; block_id -> num_of_rows)
--CREATE OR REPLACE PROCEDURE num_of_rows IS 
--...
--Test:
-------
--SET SERVEROUTPUT ON
--execute num_of_rows();

--Hint:
--Find the extents of the table. You can find the first block of the extents and the sizes in blocks
--in DBA_EXTENTS. Check the individual blocks, how many rows they contain. (use rowid)
--!!!
--  For large tables it will be very slow, see the time limit below!!! 
--  Change TABLA_123 to CUSTOMERS with a different procedure name (num_of_rows2).
--  Conclusion: for large tables you shouldn't write inefficient SQL or PL/SQL.
--!!!
create or replace procedure num_of_rows IS
  cnt NUMBER;          -- to store number of rows in each block
  start_time DATE;     -- to measure elapsed time
  run_time NUMBER;     -- runtime in seconds
BEGIN 
  -- Start timer
  SELECT sysdate INTO start_time FROM dual;

  -- Loop through each extent of the table
  FOR rec IN (
    SELECT file_id, block_id, blocks 
    FROM dba_extents
    WHERE owner='NIKOVITS' AND segment_name='TABLA_123'
    ORDER BY 1,2,3
  ) LOOP

    -- Loop through each block in the extent
    FOR i IN 1..rec.blocks LOOP

      -- Count rows in the specific block
      SELECT count(*) 
      INTO cnt
      FROM nikovits.tabla_123
      WHERE dbms_rowid.rowid_relative_fno(ROWID) = rec.file_id
        AND dbms_rowid.rowid_block_number(ROWID) = rec.block_id + i - 1;

      -- Print file_id.block_id -> number of rows
      dbms_output.put_line(rec.file_id || '.' || TO_CHAR(rec.block_id + i - 1) || '->' || cnt);

      -- Check if the procedure is running too long (timeout)
      SELECT (sysdate - start_time) * 24 * 60 * 60 INTO run_time FROM dual;
      IF run_time > 60 THEN
        dbms_output.put_line('Timeout!!!');
        RETURN;
      END IF;

    END LOOP;  -- end of block loop

  END LOOP;  -- end of extent loop
END;
/
set serveroutput on
execute num_of_rows;
-------------------------------------------------------
--6.
--Write a PL/SQL procedure which counts and prints the number of empty blocks of a table.
--CREATE OR REPLACE PROCEDURE empty_blocks(p_owner VARCHAR2, p_table VARCHAR2) IS
--...
--Test:
-------
--set serveroutput on
--EXECUTE empty_blocks('nikovits', 'employees');
--
--Check your solution with the following procedure:

--
--Hint: 
--Count the total number of blocks (see the segment), the filled blocks (use rowid), 
--the difference is the number of empty blocks.
--You have to use dynamic SQL statement in the PL/SQL program, see pl_dynamicSQL.txt
---------------------------------------------------------
--
--
--Displaying download.
CREATE OR REPLACE PROCEDURE empty_blocks(p_owner VARCHAR2, p_table VARCHAR2) IS
  v_total_blocks Number;
  v_filled_blocks Number;
  v_empty_blocks Number;
  v_sql varchar2(2000);  -- increase size if needed
Begin
  -- get total blocks of the segment 
  select sum(blocks) into v_total_blocks 
  from dba_extents
  where owner = upper(p_owner) and segment_name = upper(p_table);

  -- Count filled blocks dynamically using GROUP BY
  v_sql := 'SELECT COUNT(*) FROM ( ' ||
           'SELECT dbms_rowid.rowid_relative_fno(ROWID) AS file_id, ' ||
           'dbms_rowid.rowid_block_number(ROWID) AS block_id ' ||
           'FROM ' || p_owner || '.' || p_table || ' ' ||
           'GROUP BY dbms_rowid.rowid_relative_fno(ROWID), dbms_rowid.rowid_block_number(ROWID)' ||
           ')';

--  v_sql := 'SELECT COUNT(DISTINCT dbms_rowid.rowid_relative_fno(ROWID) || ''.'' || dbms_rowid.rowid_block_number(ROWID)) 
--           FROM ' || p_owner || '.' || p_table;


  EXECUTE IMMEDIATE v_sql INTO v_filled_blocks;

  -- Compute empty blocks
  v_empty_blocks := v_total_blocks - v_filled_blocks;

  -- Print result 
  DBMS_OUTPUT.PUT_LINE('Table ' || p_owner || '.' || p_table || 
                       ' has ' || v_empty_blocks || ' empty blocks.');
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Table ' || p_owner || '.' || p_table || ' not found.');
END;
/
SET SERVEROUTPUT ON;
EXECUTE empty_blocks('NIKOVITS', 'EMPLOYEES');



EXECUTE check_plsql('empty_blocks(''NIKOVITS'', ''EMPLOYEES'')');

