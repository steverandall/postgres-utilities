-- found on StackExchange, posted by Klin

create or replace function dependency
    (class_id regclass, obj_id regclass, obj_subid integer, dep_type "char")
returns setof text language plpgsql as $$
declare
--
r record;
--
begin
  return query
    select pg_describe_object(class_id, obj_id, obj_subid) || ' ('|| dep_type|| ')'
    where  dep_type = 'n'
      and  pg_describe_object(class_id, obj_id, obj_subid) like '%etrs_data.%';
  --
  for r in
    select classid, objid, objsubid, deptype
    from pg_depend
    where class_id = refclassid
    and obj_id = refobjid
    and (obj_subid = refobjsubid or obj_subid = 0)
  loop
    return query select dependency(r.classid, r.objid, r.objsubid, r.deptype);
  end loop;
end;
$$;

select dependency('pg_class','buckets',0,' ')
