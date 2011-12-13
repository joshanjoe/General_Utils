@echo off
REM #-------------------------------------------------------------------------------------------------------------#
REM # Websphere Profile Setup [WAS61/WAS70] With Default Ports[9080,9060 etc] for Development - written in MS DOS #
REM # websphere_profile_setup_with_default_ports.bat                                                              #
REM # 06/14/2009 - Written by Joshan George                                                                       #
REM # 10/19/2010 - Written by Joshan George                                                                       #
REM # 05/17/2011 - Modified by Joshan George                                                                      #
REM # 12/01/2011 - Modified by Joshan George                                                                      #
REM #                                                                                                             #
REM #                                                                                                             #
REM # Note:It will always delete the existing profile if the given profile name exists [Default Name: DevProfile] #
REM #-------------------------------------------------------------------------------------------------------------#
echo "Websphere Profile Setup [ WAS6.1 / WAS7.0 ] With Default Ports for Development"
echo "You need to change the WAS_HOME value based on your machine"
set WAS_HOME=C:/Program Files/IBM/SDP/runtimes/base_v7
echo "WAS_HOME => %WAS_HOME%"
echo "You need to give the profile name: '<<Name>>Profile' "
set PROFILE_NAME=DevProfile
echo "PROFILE_NAME => %WAS_HOME%"
echo "You may need to give security option [false/true] based on your choice, by default false"
set ENABLE_ADMIN_SECURITY=false
echo "ENABLE_ADMIN_SECURITY => %ENABLE_ADMIN_SECURITY%"
set USER_NAME=wsadmin
set PASSWORD=wsadmin
REM ##### TEMPLATES [default, JPA/default.jpafep, aries/default.ariesfep] #####
set TEMPLATE_PATH=default

REM ##### DO NOT CHANGE #####
echo "Profile Setup Started"
SET CURRENTDIR=%CD%
set SYS_DRIVE=%SystemDrive%
echo "System Default Drive >> %SYS_DRIVE%"
echo "Current Directory >> %CURRENTDIR%"
set DATE_STR=%date:~10,4%%date:~4,2%%date:~7,2%%time:~0,2%%time:~3,2%%time:~6,2%
cd \
c:
cd %WAS_HOME%
set TEMPLATE_BASE=%WAS_HOME%/profileTemplates
echo "Profile Name: %PROFILE_NAME%"
set PROFILE_PATH=%WAS_HOME%/profiles/%PROFILE_NAME%
echo "Profile Path: %PROFILE_PATH%"
echo "##### Listing existing Profile(s) #####"
call "%WAS_HOME%/bin/manageprofiles.bat" -listProfiles
echo "##### Profile [%PROFILE_NAME%] Deleting #####"
call "%WAS_HOME%/bin/manageprofiles.bat" -delete -profileName %PROFILE_NAME%
echo "##### Profile [%PROFILE_NAME%] Deleted #####"
rmdir /s /q "%PROFILE_PATH%"
call "%WAS_HOME%/bin/manageprofiles.bat" -validateAndUpdateRegistry 
echo "##### Profile [%PROFILE_NAME%] Validated&Updated #####"
echo "##### Listing Profile Template(s) #####"
call dir "%WAS_HOME%/profileTemplates" /D /B
echo "##### Profile [%PROFILE_NAME%] Creating #####"
mkdir "%PROFILE_PATH%"
set TEMPLATE_DEFINITION=%TEMPLATE_BASE%/%TEMPLATE_PATH%
echo "Profile Template Path: %TEMPLATE_DEFINITION%"
cd \
c:
cd %WAS_HOME%
set PORTS_DEFAULT_FILE_PATH=%TEMPLATE_BASE%/default/actions/portsUpdate/portdef.props
REM "%WAS_HOME%/bin/manageprofiles.bat" -create -templatePath "%TEMPLATE_DEFINITION%"
REM "%WAS_HOME%/bin/manageprofiles.bat" -create -templatePath "%TEMPLATE_DEFINITION%" -nodeDefaultPorts -enableAdminSecurity %ENABLE_ADMIN_SECURITY% -adminUserName %USER_NAME% -adminPassword %PASSWORD%
REM ##### Profile with node generated default ports [Profile will pick the ports auto matically without any conflicts] #####
REM "%WAS_HOME%/bin/manageprofiles.bat" -create -templatePath "%TEMPLATE_DEFINITION%" -profileName %PROFILE_NAME% -profile_root "%PROFILE_PATH%" -nodeDefaultPorts -enableAdminSecurity %ENABLE_ADMIN_SECURITY% -adminUserName %USER_NAME% -adminPassword %PASSWORD% -omitAction samplesInstallAndConfig defaultAppDeployAndConfig
REM ##### Profile with default ports [Profile will pick the ports from the prots definition file 'portdef.props'] #####
call "%WAS_HOME%/bin/manageprofiles.bat" -create -templatePath "%TEMPLATE_DEFINITION%" -profileName %PROFILE_NAME% -profile_root "%PROFILE_PATH%" -portsFile "%PORTS_DEFAULT_FILE_PATH%" -enableAdminSecurity %ENABLE_ADMIN_SECURITY% -adminUserName %USER_NAME% -adminPassword %PASSWORD% -omitAction samplesInstallAndConfig defaultAppDeployAndConfig
echo "##### Profile [%PROFILE_NAME%] Created #####"
echo "##### Profile [%PROFILE_NAME%] Information Begin #####"
set PROFILE_INFO_FILE=%WAS_HOME%/profiles/%PROFILE_NAME%/logs/AboutThisProfile.txt
REM ** Tweaking DOS **
set PROFILE_INFO_FILE=%PROFILE_INFO_FILE:/=\%
type "%PROFILE_INFO_FILE%"
echo "##### Profile [%PROFILE_NAME%] Information Begin #####"
echo "##### Listing existing Profile(s) #####"
call "%WAS_HOME%/bin/manageprofiles.bat" -listProfiles
echo "##### Listing Profile [%PROFILE_NAME%] Features #####"
call "%WAS_HOME%/bin/manageprofiles.bat" -profileName %PROFILE_NAME% -listAugments
cd \
cd "%CURRENTDIR%"
echo "##### Server [%PROFILE_NAME%] Starting #####"
echo call "%WAS_HOME%/profiles/%PROFILE_NAME%/bin/startServer.bat" server1 -profileName %PROFILE_NAME%
call "%WAS_HOME%/profiles/%PROFILE_NAME%/bin/startServer.bat" server1 -profileName %PROFILE_NAME%
echo "##### Server [%PROFILE_NAME%] Started #####"
echo "##### Server [%PROFILE_NAME%] Stopping #####"
echo call "%WAS_HOME%/profiles/%PROFILE_NAME%/bin/stopServer.bat" server1 -profileName %PROFILE_NAME% -username %USER_NAME% -password %PASSWORD%
call "%WAS_HOME%/profiles/%PROFILE_NAME%/bin/stopServer.bat" server1 -profileName %PROFILE_NAME% -username %USER_NAME% -password %PASSWORD%
echo "##### Server [%PROFILE_NAME%] Stopped #####"

echo "Profile Setup Completed"

pause
