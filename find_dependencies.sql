set search_path=public;

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
c_tables cursor for
  select i_schema || '.' || tablename as tablename
  from   pg_tables
  where  schemaname = i_schema
  union
  select i_schema || '.' || viewname
  from   pg_views
  where  schemaname = i_schema;
--
v_count  integer;
v_sql    text;
--
BEGIN
  v_sql :=          'create or replace view objects (object_name, object_type, owner) as';
  v_sql := v_sql || ' select tablename, ''Table'', schemaname from pg_tables where schemaname in (''public'',''' || i_schema || ''')';
  v_sql := v_sql || ' union';
  v_sql := v_sql || ' select viewname, ''View'', schemaname from pg_views where schemaname in (''public'',''' || i_schema || ''')';
  v_sql := v_sql || ' union';
  v_sql := v_sql || ' select foreign_table_name, ''Foreign table'', foreign_table_schema from information_schema._pg_foreign_tables where foreign_table_schema in (''public'',''' || i_schema || ''')';
  v_sql := v_sql || ' union';
  v_sql := v_sql || ' select matviewname, ''MatView'', schemaname from pg_matviews where schemaname in (''public'',''' || i_schema || ''')';
  v_sql := v_sql || ' union';
  v_sql := v_sql || ' select routine_name, ''Function'', specific_schema from information_schema.routines where specific_schema in (''public'',''' || i_schema || ''');';
  execute v_sql;
  --
  delete from dependencies;
  --
  for r_routines in c_routines loop
    for r_names in c_names loop
      if r_names.object_type in ('Table','Foreign table','View','MatView') then
        select count(*) into v_count
        from   information_schema.routines
        where  routine_name = r_routines.routine_name
          and  (lower(routine_definition) like '% ' || lower(r_names.object_name) || ' %' OR
                lower(routine_definition) like '% ' || lower(r_names.object_name) || '.%' OR
                lower(routine_definition) like '% ' || lower(r_names.object_name) || ';%');
      else -- function
        select count(*) into v_count
        from   information_schema.routines
        where  routine_name = r_routines.routine_name
          and  lower(routine_definition) like '% ' || lower(r_names.object_name) || '(%';
      end if;
      --
      if v_count > 0 then
        insert into dependencies
          values (r_routines.routine_name,
                  'Function',
                  r_names.object_name,
                  r_names.object_type);
      end if;
    end loop;
  end loop;
  --
  delete from view_dep_tmp;
  --
  for r_tables in c_tables loop
    insert into view_dep_tmp
      select distinct r_tables.tablename, dependency('pg_class'::regclass,r_tables.tablename::regclass,0,' ');
  end loop;
  --
  delete from view_dep_tmp where dependency like 'default %';
  delete from view_dep_tmp where dependency like 'constraint %';
  update view_dep_tmp set dependency = substr(dependency,1,length(dependency)-4);
  update view_dep_tmp set dependency = substr(dependency,position('.' in dependency) + 1);
  update view_dep_tmp set table_name = substr(table_name,position('.' in table_name) + 1);
  --
  insert into dependencies
  select dependency, 'View', table_name, 'Table'
  from   view_dep_tmp;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
