CREATE OR REPLACE PROCEDURE empty_blocks(p_owner VARCHAR2, p_table VARCHAR2) IS
    v_total_blocks   NUMBER;
    v_filled_blocks  NUMBER;
    v_sql            VARCHAR2(1000);
BEGIN
    -- total blocks from extents
    SELECT SUM(blocks)
    INTO v_total_blocks
    FROM dba_extents
    WHERE owner = UPPER(p_owner)
      AND segment_name = UPPER(p_table);

    -- dynamic SQL to count distinct block numbers from rowids
    v_sql := 'SELECT COUNT(DISTINCT DBMS_ROWID.ROWID_BLOCK_NUMBER(rowid)) 
              FROM ' || p_owner || '.' || p_table;

    EXECUTE IMMEDIATE v_sql INTO v_filled_blocks;

    DBMS_OUTPUT.PUT_LINE('Empty Blocks: ' || (v_total_blocks - v_filled_blocks));
END;
/


SET SERVEROUTPUT ON;

EXECUTE empty_blocks('NIKOVITS', 'EMPLOYEES');

-- check solution with:
EXECUTE check_plsql('empty_blocks(''NIKOVITS'', ''EMPLOYEES'')');



CREATE TABLE PR03 (
    text_line VARCHAR2(4000)
);


INSERT INTO pr03
SELECT text
FROM user_source
WHERE name = 'EMPTY_BLOCKS'
ORDER BY line;

SELECT * FROM pr03;

SELECT table_name
FROM user_tables
ORDER BY table_name;



