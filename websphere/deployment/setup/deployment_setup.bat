
REM #-----------------------------------------------------------------------------------------------------------------#
REM # Deployment Setup                                                                                                #
REM # This will create the folder structure and copy the required files to the appropriate places] - wrote in MS DOS  #
REM # deployment_setup.bat - can be used in windows platforms                                                         #
REM # Usage - Navigate to the setup directory [parent directory of deployment_setup.bat]                              #
REM #         and then execute deployment_setup.bat - can be used in windows platforms                                #
REM #                                                                                                                 #
REM # 12/08/2011 - Written by Joshan George                                                                           #
REM #-----------------------------------------------------------------------------------------------------------------#

echo off
echo "*** Deployment Setup Begin ***"

REM # Create Ear Location Base Directory

SET CURRENTDIR=%CD%
set sys_drive=%SystemDrive%
echo "System Default Drive >> %sys_drive%"
echo "Current Directory >> %CURRENTDIR%"
%sys_drive%

SET ENV_LOCATION=c:/project_build1
mkdir "%ENV_LOCATION%"
SET SCRIPT_LOCATION=%ENV_LOCATION%/env_setup/scripts
echo %SCRIPT_LOCATION%
mkdir "%SCRIPT_LOCATION%"
mkdir "%SCRIPT_LOCATION%/config"
SET DEPLOYMENT_BASE_EAR_LOCATION=%ENV_LOCATION%/deployment
echo %DEPLOYMENT_BASE_EAR_LOCATION%
mkdir "%DEPLOYMENT_BASE_EAR_LOCATION%"
mkdir "%DEPLOYMENT_BASE_EAR_LOCATION%/backup"
mkdir "%DEPLOYMENT_BASE_EAR_LOCATION%/logs"

attrib -s -h -r "%SCRIPT_LOCATION%/*.*"
copy /Y /B "./*.pl" "%SCRIPT_LOCATION%"
copy /Y /B "./*.py" "%SCRIPT_LOCATION%"
copy /Y /B "./*.htm*" "%SCRIPT_LOCATION%/config"
copy /Y /B "./*.txt" "%SCRIPT_LOCATION%"

cd \

cd %CURRENTDIR%

echo "*** Deployment Setup Completed ***"

pause

