create or replace function gcd (i_vol_a  integer,
                                i_vol_b  integer)
returns INTEGER as
$BODY$
DECLARE
--
v_remainder     integer;
v_vol_a         integer;
v_vol_b         integer;
v_ratio         integer;
--
BEGIN
  v_vol_a := least(i_vol_a, i_vol_b);
  v_vol_b := greatest(i_vol_a, i_vol_b);
  --
  while TRUE loop
    if v_vol_a = 0 then
      exit;
    end if;
    --
    v_remainder := v_vol_b % v_vol_a;
    if v_remainder = 0 then
      v_ratio := v_vol_a;
      exit;
    else
      v_vol_b := v_vol_a;
      v_vol_a := v_remainder;
    end if;
  end loop;
  --
  return v_ratio;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

grant execute on function gcd(integer,integer) to public;
