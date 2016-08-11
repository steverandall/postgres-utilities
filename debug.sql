create table debugs (
  client_mpid   text,
  security_type text,
  checkpoint    text,
  datetime      timestamp default localtimestamp
  );

  

CREATE OR REPLACE FUNCTION debug(i_client_mpid   text,
                                 i_security_type text,
                                 i_checkpoint    text)
RETURNS VOID AS
$BODY$
DECLARE
--
sql              text;
conn             text := 'debug';
db               text;
insert_query     text;
dispatch_result  integer;
dispatch_error   text;
do_it            boolean;
--
BEGIN
  select case when value = 'Y' then true else false end
  into   do_it
  from   client_properties
  where  key = 'Debug';
  --
  if coalesce(do_it,false) then
    set client_min_messages to WARNING;
    select current_database() into db;
    --
    sql := 'SELECT dblink_connect(' || QUOTE_LITERAL(conn) || ',' || QUOTE_LITERAL('dbname=' || db) ||');';
    execute sql;
    --
    insert_query := 'SET SEARCH_PATH=public; INSERT INTO debugs(client_mpid,security_type,checkpoint) VALUES (' || QUOTE_LITERAL(i_client_mpid) ||','|| QUOTE_LITERAL(i_security_type) ||','|| QUOTE_LITERAL(i_checkpoint) || ');';
    raise notice '%', insert_query;
    sql := 'SELECT dblink_send_query(' || QUOTE_LITERAL(conn) || ',' || QUOTE_LITERAL(insert_query) || ');';
    execute sql into dispatch_result;
    --
    -- check for errors dispatching the query
    if dispatch_result = 0 then
      sql := 'SELECT dblink_error_message(' || QUOTE_LITERAL(conn)  || ');';
      execute sql into dispatch_error;
      RAISE '%', dispatch_error;
    end if;
    --
    sql := 'SELECT dblink_disconnect(' || QUOTE_LITERAL(conn) || ');';
    execute sql;
  end if;
  --
  exception when others then
    BEGIN
    RAISE NOTICE '% %', SQLERRM, SQLSTATE;
    sql := 'SELECT dblink_disconnect(' || QUOTE_LITERAL(conn) || ');';
    execute sql;
    exception when others then
      RAISE NOTICE '% %', SQLERRM, SQLSTATE;
  end;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
