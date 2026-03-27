# Oracle Database Lecture SQL/PLSQL Exercises

This repository contains Oracle SQL and PL/SQL lecture, practice, and homework scripts created for a database course. The scripts focus on query writing, PL/SQL procedures, database storage internals, indexing, and execution plan analysis using Oracle-specific tools and data dictionary views.

## Repository Description

Collection of Oracle SQL and PL/SQL lecture exercises, homework, and practice scripts covering DBA views, storage internals, indexing, query optimization, and execution plans.

## Recommended Repository Name

`oracle-database-lecture-sql-plsql`

## Other Good Repository Names

- `database-lecture-sql-plsql`
- `oracle-sql-plsql-practice`
- `oracle-database-exercises`
- `database-course-oracle-sql`
- `oracle-query-optimization-lab`

## Topics Covered

- Oracle SQL queries
- PL/SQL procedures
- Data dictionary and DBA views
- Database objects and tablespaces
- Segments, extents, blocks, and ROWID analysis
- Indexes and bitmap indexes
- Function-based and composite indexes
- Execution plans with `EXPLAIN PLAN`
- Query plan display with `DBMS_XPLAN`
- Join strategies and optimizer hints
- Query tuning and performance comparison

## Files Included

- `practise01.sql` — introductory Oracle metadata and DBA view exercises, object types, tablespaces, and a `newest_table` PL/SQL procedure
- `practise2.sql` — storage-related Oracle practice queries using DBA views
- `practise3.sql` — block, rowid, segment, and empty-block analysis, including PL/SQL procedures
- `aramis4.sql` — index-related exercises, bitmap indexes, function-based indexes, and procedures such as `list_indexes` and `block_usage`
- `aramis7.sql` — execution plan analysis with `PLAN_TABLE`, `EXPLAIN PLAN`, and formatted hierarchical plan output
- `ullman7.sql` — additional optimizer, execution plan, join method, and performance exercises
- `prac7exttra.sql` — practice tasks on joins, indexes, salary-category filtering, and execution plans
- `practise8.sql` — optimizer hints, index usage, join strategies, and bitmap index exercises
- `HW3.sql` — homework script including the `empty_blocks` PL/SQL procedure and related checks

## Environment

These scripts are written for an Oracle Database environment and use Oracle-specific features such as:

- `DBA_OBJECTS`
- `DBA_TABLES`
- `DBA_SEGMENTS`
- `DBA_EXTENTS`
- `DBA_INDEXES`
- `DBA_IND_COLUMNS`
- `DBA_IND_EXPRESSIONS`
- `DBMS_ROWID`
- `DBMS_XPLAN`
- `EXPLAIN PLAN`

Some scripts also reference course-specific schemas and tables such as `NIKOVITS.EMP`, `NIKOVITS.DEPT`, `NIKOVITS.SAL_CAT`, `NIKOVITS.PRODUCT`, and related tables.

## How to Use

1. Open the `.sql` files in Oracle SQL Developer, SQLcl, or another Oracle-compatible SQL environment.
2. Run the scripts step by step instead of executing all files at once.
3. Make sure the required schemas, privileges, and referenced tables exist in your database.
4. Enable server output when testing PL/SQL procedures:

```sql
SET SERVEROUTPUT ON;
```

## Notes

- The repository is best presented as a course exercise collection rather than a single application.
- Some scripts are practice files, while others are homework or lecture-based solutions.
- A few files depend on access to DBA views and instructor-provided schemas.

## Suggested GitHub Description

Oracle SQL and PL/SQL database course exercises covering DBA views, storage internals, indexing, optimizer hints, and execution plan analysis.

## License

This project is intended for educational use.
