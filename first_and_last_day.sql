create or replace function first_day (i_day date)
returns date as
$BODY$
--
begin
  return date_trunc('month',i_day);
end;
$BODY$
LANGUAGE plpgsql
STABLE;

create or replace function last_day (i_day date)
returns date as
$BODY$
--
begin
  return date_trunc('month',i_day) + interval '1 month' - interval '1 day';
end;
$BODY$
LANGUAGE plpgsql
STABLE;

create or replace function first_day (i_day integer)
returns date as
$BODY$
--
begin
  return date_trunc('month',to_date(to_char(i_day,'99999999'),'YYYYMMDD'));
end;
$BODY$
LANGUAGE plpgsql
STABLE;

create or replace function last_day (i_day integer)
returns date as
$BODY$
--
begin
  return date_trunc('month',to_date(to_char(i_day,'99999999'),'YYYYMMDD')) + interval '1 month' - interval '1 day';
end;
$BODY$
LANGUAGE plpgsql
STABLE;

create or replace function first_day (i_day varchar)
returns date as
$BODY$
--
begin
  return date_trunc('month',to_date(i_day,'YYYYMMDD'));
end;
$BODY$
LANGUAGE plpgsql
STABLE;

create or replace function last_day (i_day varchar)
returns date as
$BODY$
--
begin
  return date_trunc('month',to_date(i_day,'YYYYMMDD')) + interval '1 month' - interval '1 day';
end;
$BODY$
LANGUAGE plpgsql
STABLE;


grant execute on function first_day(date) to public;
grant execute on function first_day(integer) to public;
grant execute on function first_day(varchar) to public;
grant execute on function last_day(date) to public;
grant execute on function last_day(integer) to public;
grant execute on function last_day(varchar) to public;
