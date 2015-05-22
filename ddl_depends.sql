set search_path=public;

create or replace view objects (object_name, object_type, owner) as
  select tablename, 'Table', schemaname from pg_tables where schemaname in ('public','acme_data')
  union
  select viewname, 'View', schemaname from pg_views where schemaname in ('public','acme_data')
  union
  select foreign_table_name, 'Foreign table', foreign_table_schema from information_schema._pg_foreign_tables where foreign_table_schema in ('public','acme_data')
  union
  select matviewname, 'MatView', schemaname from pg_matviews where schemaname in ('public','acme_data')
  union
  select routine_name, 'Function', specific_schema from information_schema.routines where specific_schema in ('public','acme_data')
;

create table dependencies (
   object_name      text  not null,
   object_type      text  not null,
   depends_on       text  not null,
   depends_on_type  text  not null
   );

create table view_dep_tmp (
   table_name  text not null,
   dependency  text not null
   );
