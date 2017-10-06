@echo off
rem cortana_disable.bat
rem Disables the cortana process and prevents it from restarting by moving
rem cortana related folders from the SystemApps dir to a backup directory.
rem Inspired by https://superuser.com/a/949641
rem Tested with Win 10 Pro 64bit (1703).
rem by Ingo Breßler in 2017 (dev at ingobressler.net)
cls

set "DBG="

rem Check for admin permissions
fltmc >nul 2>&1 || (
	echo Please run with admin permissions!
	exit /b
)

set disable_reg=cortana_disable.reg
if exist %disable_reg% regedit /s %disable_reg%

rem get a timestamp for creating multiple autostart files
for /f "usebackq tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do if '.%%i.'=='.LocalDateTime.' set ldt=%%j
rem echo TS0: '%ldt%'
set ldt=%ldt:~0,4%-%ldt:~4,2%-%ldt:~6,2%-%ldt:~8,2%%ldt:~10,2%%ldt:~12,2%%ldt:~15,3%
if defined DBG echo using timestamp '%ldt%'

rem set up the target folder
set basedir=%SystemRoot%\SystemApps
set backupdir=%basedir%\..\SystemApps_%ldt%
echo using backup dir '%backupdir%'
mkdir "%backupdir%"

rem get the install folders of cortana apps
set key=cortana
set basecmd=get-appxpackage -AllUsers ^| sort packagefullname ^| where-object {$_.name -like \"*%key%*\"}
set pathcmd=powershell -Command "& {%basecmd% | select-string -inputobject {$_.installlocation} -pattern ".*" -all; }"
if defined DBG echo '%pathcmd%'
for /f "tokens=*" %%i in ('%pathcmd%') do (
	rem for each install location
	echo moving folder '%%i'
	rem set the permissions to all files and folders recursively
	takeown /f "%%i" /r /skipsl
	rem quit cortana process
	taskkill /IM searchui.exe /F
	ping -n 1 -w 127.0.0.1 > NUL 2>&1
	rem now move the folder
	if exist "%backupdir%" move "%%i" "%backupdir%\"
)
if exist "%backupdir%" (
	for /f %%i in ('dir /b /a "%backupdir%"') do (
		rem backup folder is not empty, done here
		goto end
	)
	echo Removing empty backup dir '%backupdir%'
	rd "%backupdir%"
)

:end
pause
