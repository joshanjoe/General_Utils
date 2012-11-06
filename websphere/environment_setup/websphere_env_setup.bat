
REM #--------------------------------------------------------------------------------------------#
REM # Workspace Environment Setup [internally uses websphere_env_setup.py] - wrote in MS DOS     #
REM # websphere_env_setup.bat                                                                    #
REM # 10/13/2010 - Written by Joshan George                                                      #
REM # 12/23/2011 - Updated by Joshan George                                                      #
REM #--------------------------------------------------------------------------------------------#

REM echo off

echo .

echo "*** Environment Setup started. ***"

echo .

REM ***************************** DO NOT EDIT THE LINES ABOVE ********************************************************
REM   WAS_HOME need to set following properties before executing this file, 
REM   Usually we don't need to change the SERVER_NAME and SOAP_PORT if we are using profile with default port number

SET WAS_HOME="C:\Program Files (x86)\IBM\SDP\runtimes\base_v7"
SET PROFILE_NAME="DevProfile"

SET SERVER_NAME="server1"
SET SOAP_PORT=8880
REM ***************************** DO NOT EDIT LINES THE BELOW ********************************************************

REM "# ******* Main Block - Begin ******* #"

SET PROFILE_BIN=%WAS_HOME%\profiles\%PROFILE_NAME%\bin
SET CURRENTDIR=%CD%
set sys_drive=%SystemDrive%
echo "System Default Drive >> %sys_drive%"
echo "Current Directory >> %CURRENTDIR%"

attrib -s -h -r %sys_drive%\environment-setup-temp-1234
rmdir /S /Q %sys_drive%\environment-setup-temp-1234
mkdir %sys_drive%\environment-setup-temp-1234
mkdir %sys_drive%\libs
copy /Y /B .\files\libs\*.jar %sys_drive%\libs
copy /Y .\websphere_env_setup.py %sys_drive%\environment-setup-temp-1234

%sys_drive%

cd \

echo .

cmd /c "%PROFILE_BIN%\startServer.bat -profileName %PROFILE_NAME% %SERVER_NAME%"

cmd /c "%WAS_HOME%\bin\wsadmin.bat" -lang jython -conntype SOAP -host 127.0.0.1 -port %SOAP_PORT% -f %sys_drive%\environment-setup-temp-1234\websphere_env_setup.py

cd \

rmdir /S /Q %sys_drive%\environment-setup-temp-1234

cd \

cmd /c "%PROFILE_BIN%\stopServer.bat -profileName %PROFILE_NAME% %SERVER_NAME%"

cd \

cd %CURRENTDIR%

echo .

echo "*** Environment Setup Completed. ***"

echo .

echo %CURRENTDIR%

echo .

pause

REM # ******* Main Block - End ******* #

