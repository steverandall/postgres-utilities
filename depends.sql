create view objects (object_name, object_type, owner) as
  select tablename, 'Table', schemaname from pg_tables where schemaname in ('public','market_data','acme_data')
  union
  select viewname, 'View', schemaname from pg_views where schemaname in ('public','market_data','acme_data')
  union
  select foreign_table_name, 'Foreign table', foreign_table_schema from information_schema._pg_foreign_tables where foreign_table_schema in ('public','market_data','acme_data')
  union
  select matviewname, 'MatView', schemaname from pg_matviews where schemaname in ('public','market_data','acme_data')
  union
  select routine_name, 'Function', specific_schema from information_schema.routines where specific_schema in ('public','market_data','acme_data')
;

create gist index on routine_definition

create dependency table
loop thru object view to find routeine dependencies and populate above table

will only work within schema for now (won't see market_data)

create table dependencies (
   routine_name     text  not null,
   depends_on       text  not null,
   depends_on_type  text  not null
   );

pg_depend - add in for completeness

create or replace function find_dependencies(i_schema  varchar)
returns VOID as
$BODY$
DECLARE
--
c_routines cursor for
  select routine_name
  from   information_schema.routines
  where  specific_schema = i_schema
  union
  select routine_name
  from   information_schema.routines
  where  specific_schema = 'public';
--
c_names cursor for
  select object_name,
         object_type
  from   objects;
--
v_count  integer;
--
BEGIN
  delete from dependencies;
  --
  for r_routines in c_routines loop
    for r_names in c_names loop
      if r_names.object_type in ('Table','Foreign table') then
        select count(*) into v_count
        from   information_schema.routines
        where  routine_name = r_routines.routine_name
          and  routine_definition like '% ' || r_names.object_name || '%';
      else
        select count(*) into v_count
        from   information_schema.routines
        where  routine_name = r_routines.routine_name
          and  routine_definition like '%' || r_names.object_name || '%';
      end if;
      --
      if v_count > 0 then
        insert into dependencies
          values (r_routines.routine_name,
                  r_names.object_name,
                  r_names.object_type);
      end if;
    end loop;
  end loop;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


select a.classid::regclass
      ,a.objid
      ,a.objsubid
      ,a.refclassid::regclass
      ,a.refobjid
      ,a.refobjid::regclass
      ,a.refobjsubid
      ,a.deptype
from pg_depend a, pg_depend b
where a.refobjid = b.objid
 and b.refobjid in (select oid from pg_namespace where nspname = 'citi_bx')
;


select x.classid::regclass
      ,x.objid
      ,x.objsubid
      ,z.relname
      ,x.refclassid::regclass
      ,x.refobjid
      ,x.refobjid::regclass
      ,x.refobjsubid
      ,x.deptype
from pg_depend x, pg_rewrite y, pg_class z
where x.classid = 'pg_rewrite'::regclass
and x.objid = y.oid
and y.ev_class = z.oid
and x.objid in
(select a.objid
from pg_depend a, pg_class b, pg_namespace c
where a.refclassid = 'pg_class'::regclass
and a.refobjid = 'buckets'::regclass
and a.refobjid = b.oid
and b.relnamespace = c.oid
and c.nspname = 'citi_bx');



select find_dependencies('citi_bx');
select * from dependencies;
select * from objects;

select b.relname, c.relname
from pg_depend a, pg_class b, pg_class c
where a.refobjid in (select oid from pg_namespace where nspname = 'citi_bx')
and a.objid = b.oid and a.refobjid = c.oid limit 10;

select distinct classid::regclass from pg_depend;

select * from pg_class where oid = 2615;

SELECT distinct *
FROM pg_depend
JOIN pg_rewrite ON pg_depend.objid = pg_rewrite.oid
JOIN pg_class as dependee ON pg_rewrite.ev_class = dependee.oid
JOIN pg_class as dependent ON pg_depend.refobjid = dependent.oid
JOIN pg_attribute ON pg_depend.refobjid = pg_attribute.attrelid
    AND pg_depend.refobjsubid = pg_attribute.attnum
WHERE dependent.relname = 'new_orders'
AND pg_attribute.attnum > 0
AND pg_attribute.attname = 's3_order_uid';

select x.classid::regclass
      ,x.objid
      ,x.objsubid
      ,z.relname
      ,x.refclassid::regclass
      ,x.refobjid
      ,x.refobjid::regclass
      ,x.refobjsubid
      ,x.deptype
from pg_depend x, pg_rewrite y, pg_class z
where x.classid = 'pg_rewrite'::regclass
and x.objid = y.oid
and y.ev_class = z.oid
and x.objid in
(select a.objid
from pg_depend a, pg_class b, pg_namespace c
where a.refclassid = 'pg_class'::regclass
and a.refobjid = 'buckets'::regclass
and a.refobjid = b.oid
and b.relnamespace = c.oid
and c.nspname = 'citi_bx');

select * from pg_rewrite where oid = 92445;
select * from pg_class where oid = 92442;
select * from pg_namespace where oid = 84775;

