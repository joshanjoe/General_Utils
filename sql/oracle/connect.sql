
set define on
set termout off
connect &1
col prom new_value prom
select lower(sys_context('USERENV','SESSION_USER'))||'@'||lower(sys_context('USERENV','DB_NAME'))||'['||lower(machine)||']' prom from SYS.V_$SESSION where sid = 1;
set sqlprompt "&prom> "
set termout on
show user
@setup.sql

