--The owner of the following tables is NIKOVITS.
--
--PRODUCT(prod_id, name, color, weight)
--SUPPLIER(supl_id, name, status, address)
--PROJECT(proj_id, name, address)
--SUPPLY(supl_id, prod_id, proj_id, amount, sDate)
--
--Exercise 1.
--Query:
--Give the sum amount of products where prod_id=2 and supl_id=2.
--Give hints in order to use the following execution plans:
--a) No index 
select /*+ no_index(supply)*/ sum(amount) from supply where prod_id =2 and supl_id =2; 

--SELECT STATEMENT +  + 
--  SORT + AGGREGATE + 
--    TABLE ACCESS + FULL + PRODUCT

explain plan set statement_id='1st' for
select /*+ full(product)*/sum(weight) from PRODUCT;



select plan_table_output from table(dbms_xplan.display('plan_table','1st','all'));
--SELECT STATEMENT +  + 
--  SORT + AGGREGATE + 
--    TABLE ACCESS + BY INDEX ROWID + PRODUCT
--      INDEX + UNIQUE SCAN + PROD_ID_IDX


explain plan set statement_id='2nd' for
select /*+ index(product) */ sum(weight) from product where prod_id=1;

select plan_table_output from table(dbms_xplan.display('plan_table','2nd','all'));
--CREATE INDEX prod_color_idx ON product(color);
--CREATE UNIQUE INDEX prod_id_idx ON product(prod_id);
--CREATE UNIQUE INDEX proj_id_idx ON PROJECT(proj_id);
--CREATE UNIQUE INDEX supplier_id_idx ON supplier(supl_id);
--CREATE INDEX supply_supplier_idx ON supply(supl_id);
--CREATE INDEX supply_proj_idx ON supply(proj_id);
--CREATE INDEX supply_prod_idx ON supply(prod_id);


--SELECT STATEMENT +  + 
--  SORT + AGGREGATE + 
--    HASH JOIN +  + 
--      TABLE ACCESS + FULL + PROJECT
--      TABLE ACCESS + FULL + SUPPLY
explain plan set statement_id ='3rd'for  
select /*+full(p) full(s) */sum(s.amount) from project p join supply s 
on p.proj_id =s.proj_id;


select plan_table_output from table(dbms_xplan.display('plan_table','3rd','all'));

--SELECT STATEMENT +  + 
--  HASH + GROUP BY + 
--    HASH JOIN +  + 
--      TABLE ACCESS + FULL + PROJECT
--      TABLE ACCESS + FULL + SUPPLY


explain plan set statement_id ='4th'for  
select /*+ full(p) */sum(s.amount) from project p join supply s 
on p.proj_id =s.proj_id group by prod_id;

select plan_table_output from table(dbms_xplan.display('plan_table','4th','all'));


--SELECT STATEMENT +  + 
--  SORT + AGGREGATE + 
--    MERGE JOIN +  + 
--      SORT + JOIN + 
--        TABLE ACCESS + BY INDEX ROWID BATCHED + PRODUCT
--          INDEX + RANGE SCAN + PROD_COLOR_IDX
--      SORT + JOIN + 
--        TABLE ACCESS + FULL + SUPPLY

explain plan set statement_id ='5th'for  
select /*+ use_merge(p,s) */sum(s.amount) from product  p join supply s 
on p.prod_id =s.prod_id  where p.color = 'red';


select plan_table_output from table(dbms_xplan.display('plan_table','5th','all'));


--SELECT STATEMENT +  + 
--  FILTER +  + 
--    HASH + GROUP BY + 
--      HASH JOIN +  + 
--        TABLE ACCESS + FULL + PROJECT
--        HASH JOIN +  + 
--          TABLE ACCESS + FULL + SUPPLIER
--          TABLE ACCESS + FULL + SUPPLY

--PRODUCT(prod_id, name, color, weight)
--SUPPLIER(supl_id, name, status, address) --------
--PROJECT(proj_id, name, address) ----
--SUPPLY(supl_id, prod_id, proj_id, amount, sDate)-------

explain plan set statement_id ='6th' for 
SELECT /*+ no_index(s) leading(sr) */ sum(amount)
FROM nikovits.supply s, nikovits.supplier sr, nikovits.project p 
WHERE s.supl_id = sr.supl_id 
  AND s.proj_id = p.proj_id 
  AND sr.address = 'Pecs'
  AND p.address = 'Szeged'
GROUP BY prod_id 
HAVING prod_id > 100;


select plan_table_output from table(dbms_xplan.display('plan_table','6th','all'));



--Exercise 4.
--Create a new copy from table NIKOVITS.PRODUCT (-> PRODUCT_TMP) and create two bitmap indexes
--on columns COLOR and WEIGHT. Write a query which uses both indexes.

create table PRODUCT_TMP as select * from  NIKOVITS.PRODUCT;

CREATE BITMAP INDEX prodtmp_color_bix
ON product_tmp(color);

create bitmap index protmp_weight on product_tmp(weight);

select * from product_tmp;
SELECT /*+ INDEX(product_tmp prodtmp_color_bix) INDEX(product_tmp prodtmp_weight_bix) */
       color, weight
FROM product_tmp
WHERE color = 'piros'
  AND weight > 10;


