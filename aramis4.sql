--
--select  q'[execute check_plsql('list_indexes(''nikovits'',''customers'')',']'||azonosito||q'[');]'
--from nikovits.nt_hallgatok where upper(idopont)='H14'
--order by nev;
--
--Bitmap index
--------------
--
--Compress the following bit vector with run-length encoding (see in Text Book)
--0000000000000000000000010000000101
--
--run lengths: 23, 7, 1 -> In binary format: 10111, 111, 1
--compressed -> 1111010111 110111 01
--                   -----    ---  -
--                     23      7   1
--
--Decompress the following run-length encoded bit vector:
--1111010101001011
--     ----- -  --
--       21  0   3
--decompressed -> 000000000000000000000110001
--
--
--Oracle indexes
----------------
--1.
--Give the tables (table_name) which has a column indexed in descending order.
--(In the solutions only objects of Nikovits are concerned.)




SELECT * FROM dba_ind_columns WHERE descend='DESC' AND index_owner='NIKOVITS';

--See the name of the column. Why is it so strange? -> DBA_IND_EXPRESSIONS.COLUMN_NAME

SELECT * FROM dba_ind_columns WHERE index_name='EMP2' AND index_owner='NIKOVITS';
SELECT * FROM dba_ind_expressions WHERE index_name='EMP2' AND index_owner='NIKOVITS';

------------------------------------
--2.
--Give the indexes (index name) which are composite and have at least 9 columns (expressions).

SELECT index_owner, index_name FROM dba_ind_columns 
GROUP BY index_owner, index_name HAVING count(*) >=9;

-- confirm one of them
SELECT * FROM dba_ind_columns WHERE index_owner='SYS' AND index_name='I_OBJ2';

------------------------------------------
--3.
--Give the name of bitmap indexes on table NIKOVITS.CUSTOMERS.

SELECT * FROM dba_indexes 
WHERE table_owner='NIKOVITS' AND table_name='CUSTOMERS' AND index_type='BITMAP';

------------------------------------------
--4.
--Give the indexes of owner NIKOVITS which has at least 2 columns and are function-based.

SELECT index_owner, index_name FROM dba_ind_columns 
GROUP BY index_owner, index_name HAVING count(*) >=2
 INTERSECT
SELECT index_owner, index_name FROM dba_ind_expressions WHERE index_owner='NIKOVITS';

-------------------------------------------
--5.
--Give for one of the above indexes the expression for which the index was created.

SELECT * FROM dba_ind_expressions WHERE index_owner='NIKOVITS';

---------------------------------------------------------------------------------------
--6.
--Write a PL/SQL procedure which prints out the names and sizes (in bytes) of indexes created
--on the parameter table. Indexes should be in alphabetical order, and the format of the 
--output should be like this: (number of spaces doesn't count between the columns)
--CUSTOMERS_YOB_BIX:   196608
--
--CREATE OR REPLACE PROCEDURE list_indexes(p_owner VARCHAR2, p_table VARCHAR2) IS
--...
--Test:
-------

/
CREATE OR REPLACE PROCEDURE list_indexes(p_owner VARCHAR2, p_table VARCHAR2) IS
    CURSOR idx_cur IS
        SELECT i.index_name, SUM(s.bytes) AS size_bytes
        FROM dba_indexes i
        JOIN dba_segments s
          ON i.index_name = s.segment_name
         AND i.owner = s.owner
        WHERE i.table_name = UPPER(p_table)
          AND i.owner = UPPER(p_owner)
        GROUP BY i.index_name
        ORDER BY i.index_name;
BEGIN
    FOR idx_rec IN idx_cur LOOP
        DBMS_OUTPUT.PUT_LINE(idx_rec.index_name || ':   ' || idx_rec.size_bytes);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END list_indexes;
/


set serveroutput on
execute list_indexes('nikovits', 'emp');

--Check your solution with the following procedure:
EXECUTE check_plsql('list_indexes(''nikovits'',''customers'')');
---------------------------------------------------------------------------------------
--7.
--Write a PL/SQL procedure which gets a file_id and block_id as a parameter and prints out the database
--object to which this datablock is allocated. (owner, object_name, object_type).
--If the specified datablock is not allocated to any object, the procedure should print out 'Free block'.
--



CREATE OR REPLACE PROCEDURE block_usage(p_fileid NUMBER, p_blockid NUMBER) IS
    v_owner        VARCHAR2(30);
    v_object_name  VARCHAR2(30);
    v_object_type  VARCHAR2(30);
BEGIN
    -- Try to find which database object owns this specific block
    SELECT owner, segment_name, segment_type
    INTO v_owner, v_object_name, v_object_type
    FROM dba_extents
    WHERE file_id = p_fileid
      AND p_blockid BETWEEN block_id AND block_id + blocks - 1;

    -- If found, print details
    DBMS_OUTPUT.PUT_LINE('Owner: ' || v_owner);
    DBMS_OUTPUT.PUT_LINE('Object Name: ' || v_object_name);
    DBMS_OUTPUT.PUT_LINE('Object Type: ' || v_object_type);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Free block');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END block_usage;
/




