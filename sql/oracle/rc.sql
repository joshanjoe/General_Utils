--#--------------------------------------------------------------------------------------------#
--# Oracle DB Generic Recompile[Function, Procedure, Package etc] script - wrote in PL/SQL     #
--# rc.sql                                                                                     #
--# 07/08/2011 - Written by Joshan George                                                      #
--# 12/08/2011 - Updated by Joshan George                                                      #
--# Usage - Login as schema owner and execute                                                  #
--#--------------------------------------------------------------------------------------------#

--Note: VIEW,SYNONYM,PROCEDURE,PACKAGE,FUNCTION,TRIGGER

set echo off
--set heading off

set linesize 1000;

set serveroutput on size 1000000

DECLARE
  msg VARCHAR2(4000);
  cmd VARCHAR2(200);
  anyFlag VARCHAR2(1);
  invalidCount NUMBER;
BEGIN

  dbms_output.put_line('*** Recompile Begin ***');

  invalidCount := 0;

  --First step re-compile all invalid synonyms
  FOR all_obj_rec IN (select OWNER as OWNER, OBJECT_NAME as OBJECT_NAME, OBJECT_TYPE as OBJECT_TYPE,
                           Decode(OBJECT_TYPE,
                             'SYNONYM', 2,
                             NULL) AS recompile_order
                      FROM all_objects
                      WHERE  status != 'VALID' and owner = 'PUBLIC' and object_type = 'SYNONYM'
                      ORDER BY recompile_order nulls last)
  LOOP
    BEGIN
      anyFlag := 'Y';
      invalidCount := invalidCount + 1;
      cmd := '';
      msg := all_obj_rec.object_type || ' : ' 
        || all_obj_rec.owner || ' : ' || all_obj_rec.object_name || ' compiled successfully.';
      IF all_obj_rec.owner = 'PUBLIC' AND all_obj_rec.object_type IN ('SYNONYM') THEN
        cmd := 'alter public synonym "' 
          || all_obj_rec.owner || '"."' || all_obj_rec.object_name || '" compile';
        msg := all_obj_rec.object_type || ' : ' 
          || all_obj_rec.owner || ' : ' || all_obj_rec.object_name || ' compiled successfully.';
      ELSE
        msg := 'Unknown > '|| all_obj_rec.object_type || ' : ' 
          || all_obj_rec.owner || ' : ' || all_obj_rec.object_name || ' need to look into it.';
        cmd := 'prompt "***' || msg ||'***"';
      END IF;
      dbms_output.put_line(cmd||';');
      EXECUTE IMMEDIATE cmd;
      dbms_output.put_line(msg);
    EXCEPTION
      WHEN OTHERS THEN
        dbms_output.put_line(all_obj_rec.object_type || ' : ' 
          || all_obj_rec.owner || ' : ' || all_obj_rec.object_name || ' ' || SQLERRM);
    END;
  END LOOP;

  --Second step re-compile all invalid synonyms
  FOR user_obj_rec IN (select sys_context('USERENV', 'SESSION_USER') as OWNER, 
                         OBJECT_NAME as OBJECT_NAME, OBJECT_TYPE as OBJECT_TYPE,
                         Decode(OBJECT_TYPE,
                           'VIEW', 1,
                           'SYNONYM', 2,
                           'FUNCTION', 3,
                           'PROCEDURE', 4,
                           'TRIGGER', 5,
                           'PACKAGE', 6,
                           'PACKAGE BODY', 7,
                           'UNDEFINED', 8,
                           'JAVA CLASS',9,
                           'TYPE BODY', 10,
                           NULL) AS recompile_order
                       FROM user_objects
                       WHERE  status != 'VALID'
                       ORDER BY recompile_order nulls last)
  LOOP
    BEGIN
      anyFlag := 'Y';
      invalidCount := invalidCount + 1;
      cmd := '';
      msg := user_obj_rec.object_type || ' : ' 
        || user_obj_rec.owner || ' : ' || user_obj_rec.object_name || ' compiled successfully.';
      IF user_obj_rec.object_type IN ('VIEW','SYNONYM','PROCEDURE','FUNCTION','PACKAGE','TRIGGER') THEN
        cmd := 'alter ' || user_obj_rec.object_type 
          ||' "' || user_obj_rec.owner || '"."' || user_obj_rec.object_name || '" compile';
      ElSIF user_obj_rec.object_type IN ('PACKAGE BODY') THEN
        cmd := 'alter package ' 
          ||' "'|| user_obj_rec.owner || '"."' || user_obj_rec.object_name || '" compile body';
      ElSIF user_obj_rec.object_type IN ('UNDEFINED') THEN
        cmd := 'alter materizlized view "' 
          || user_obj_rec.owner || '"."' || user_obj_rec.object_name || '" compile';
      ElSIF user_obj_rec.object_type IN ('JAVA CLASS') THEN
        cmd := 'alter java class "' 
          || user_obj_rec.owner || '"."' || user_obj_rec.object_name || '" resolve';
      ElSIF user_obj_rec.object_type IN ('TYPE BODY') THEN
        cmd := 'alter type "' 
          || user_obj_rec.owner || '"."' || user_obj_rec.object_name || '" compile body';
      ElSIF user_obj_rec.owner = 'PUBLIC' AND user_obj_rec.object_type IN ('SYNONYM') THEN
        cmd := 'alter public synonym "' 
          || user_obj_rec.owner || '"."' || user_obj_rec.object_name || '" compile';
      ELSE
        msg := 'Unknown > '|| user_obj_rec.object_type || ' : '
          || user_obj_rec.owner || ' : ' || user_obj_rec.object_name || ' need to look into it.';
        cmd := 'prompt "***' || msg ||'***"';
      END IF;
      dbms_output.put_line(cmd||';');
      EXECUTE IMMEDIATE cmd;
      dbms_output.put_line(msg);
    EXCEPTION
      WHEN OTHERS THEN
        msg := user_obj_rec.object_type || ' : ' 
          || user_obj_rec.owner || ' : ' || user_obj_rec.object_name || ' ' || SQLERRM;
        dbms_output.put_line(msg);
    END;
  END LOOP;

  dbms_output.put_line('*******************************');

  IF anyFlag = 'Y' THEN
    dbms_output.put_line(invalidCount || ' - invalid object(s) processed.');
  ELSE
    dbms_output.put_line('No invalid object(s) found.');
  END IF;

  dbms_output.put_line('*******************************');

  dbms_output.put_line('*** Recompile Completed ***');

END;
/

