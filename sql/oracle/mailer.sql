--#--------------------------------------------------------------------------------------------#
--# Mailer Package[sending email from Oracle] script - wrote in PL/SQL                         #
--# mailer.sql                                                                                 #
--# 03/15/2011 - Written by Joshan George                                                      #
--# Usage - Please fill the appropriate values and execute                                     #
--#--------------------------------------------------------------------------------------------#

--Mailer Package Spec
CREATE OR REPLACE PACKAGE mailer IS

  FUNCTION getEnvironmentInfo RETURN VARCHAR2;

  PROCEDURE sendMail (
    in_from VARCHAR2,
    in_to VARCHAR2,
    in_subject VARCHAR2 DEFAULT 'No Subject', 
    in_body LONG DEFAULT 'No Message',
    in_env_info NUMBER DEFAULT 1, 
    in_cc VARCHAR2 DEFAULT NULL,
    in_bcc VARCHAR2 DEFAULT NULL,
    in_sender_mail VARCHAR2 DEFAULT '<<no-replay email>>',
    in_mail_host VARCHAR2 DEFAULT '<<smtp host>>',
    in_mail_port NUMBER DEFAULT 25);

END mailer;
/

--Mailer Package Body
CREATE OR REPLACE PACKAGE BODY mailer
IS

  FUNCTION getEnvironmentInfo RETURN VARCHAR2
  IS
    datetime VARCHAR2(100) DEFAULT 'Time: ' || TO_CHAR(systimestamp, 'DD-MON-YYYY HH24:MI:SSxFF TZH:TZM');
    rtnVal VARCHAR2(2000);
  BEGIN
    SELECT ', Database: '||sys_context('USERENV', 'DB_NAME') || ', Schema: ' || sys_context('USERENV', 'CURRENT_SCHEMA') INTO rtnVal FROM dual;
    rtnVal := datetime || rtnVal;
    RETURN rtnVal;
  END getEnvironmentInfo;

  PROCEDURE sendMail (
    in_from VARCHAR2,
    in_to VARCHAR2,
    in_subject VARCHAR2 DEFAULT 'No Subject', 
    in_body LONG DEFAULT 'No Message',
    in_env_info NUMBER DEFAULT 1, 
    in_cc VARCHAR2 DEFAULT NULL,
    in_bcc VARCHAR2 DEFAULT NULL,
    in_sender_mail VARCHAR2 DEFAULT '<<no-replay email>>',
    in_mail_host VARCHAR2 DEFAULT '<<smtp host>>',
    in_mail_port NUMBER DEFAULT 25)
  IS
    conn UTL_SMTP.CONNECTION;
    crlf VARCHAR2( 2 ):= CHR( 13 ) || CHR( 10 );
    br VARCHAR2(4):='<br>';
    log_msg VARCHAR2(4000);
    error_msg VARCHAR2(4000);
    message LONG;
    n NUMBER;
    email VARCHAR2(100);
    recipients VARCHAR2(2000);
  BEGIN
    log_msg := '\nMail Server :'||in_mail_host
      ||'\nMail Server Port :'||in_mail_port
      ||'\nFrom :'||in_from
      ||'\nTo :'||in_to
      ||'\nCc :'||in_cc
      ||'\nBcc :'||in_bcc
      ||'\nSubject :'||in_subject
      ||'\nBody :'||in_body;

    --dbms_output.put_line(log_msg);
    conn:= SYS.utl_smtp.open_connection(in_mail_host,in_mail_port);
    SYS.utl_smtp.helo(conn,in_mail_host);
    SYS.utl_smtp.mail(conn,in_sender_mail);

    recipients := in_to;
    recipients := replace(recipients, ' ');
    IF recipients IS NOT NULL THEN
      recipients := ',' || recipients || ',';
      FOR i in 1 .. length(recipients) - length(replace(recipients,',','')) - 1
      LOOP
        n := instr(recipients, ',', 1, i+1) - instr(recipients, ',', 1, i) - 1;
        email := substr(recipients, instr(recipients, ',', 1, i ) + 1, n);
        SYS.utl_smtp.rcpt(conn, email );
      END LOOP;
    END IF;

    recipients := in_cc;
    recipients := replace(recipients, ' ');
    IF recipients IS NOT NULL THEN
      recipients := ',' || recipients || ',';
      FOR i in 1 .. length(recipients) - length(replace(recipients,',','')) - 1
      LOOP
        n := instr(recipients, ',', 1, i+1) - instr(recipients, ',', 1, i) - 1;
        email := substr(recipients, instr(recipients, ',', 1, i ) + 1, n);
        SYS.utl_smtp.rcpt(conn, email );
      END LOOP;
    END IF;

    recipients := in_bcc;
    recipients := replace(recipients, ' ');
    IF recipients IS NOT NULL THEN
      recipients := ',' || recipients || ',';
      FOR i in 1 .. length(recipients) - length(replace(recipients,',','')) - 1
      LOOP
        n := instr(recipients, ',', 1, i+1) - instr(recipients, ',', 1, i) - 1;
        email := substr(recipients, instr(recipients, ',', 1, i ) + 1, n);
        SYS.utl_smtp.rcpt(conn, email );
      END LOOP;
    END IF;

    --mesg:='Date:'||to_char(sysdate+(4/24),'DD-MON-RRRR HH24:MI:SS')||crlf||
    message:= 'From:'|| Nvl(in_from,in_sender_mail)|| crlf 
      || 'Subject: '|| in_subject|| crlf 
      || 'To: '|| Replace(Replace(in_to,',',';'),' ')|| crlf 
      || 'Cc: '|| Replace(Replace(in_cc,',',';'),' ')|| crlf
      || 'Bcc: '|| Replace(Replace(in_bcc,',',';'),' ')|| crlf
      || 'Content-Type: text/html' || crlf
      || '' || crlf || br;

      IF in_env_info = 1 THEN
        message:= message || '<b>' || getEnvironmentInfo || '</b>' || br || br ;
      END IF;

      message:= message || in_body;

      --You should change it before using it
      message:= message || br || br || 'Thanks,' || br || 'Mailer';

    SYS.utl_smtp.data( conn, message );
    SYS.utl_smtp.quit( conn );
  EXCEPTION
    WHEN OTHERS THEN
      error_msg := SQLERRM;
      --||'. \nSending mail using:- ' ||log_msg;
      dbms_output.put_line('Mail Sending Failed:- '|| error_msg);
  END sendMail;

END mailer;
/

/*

e.g
call mailer.sendMail('Sample From', 'sample@sample.com','Sample Subject', 'Sample Body', 0);

*/
