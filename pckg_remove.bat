@echo off
rem pckg_remove.bat
rem Lists installed or provisioned Windows (modern app) packages.
rem Example: 'pckg_remove.bat xbox'
rem   Removes the packages 'Microsoft.XboxApp', 'Microsoft.XboxGameOverlay',
rem   'Microsoft.XboxIdentityProvider' and 'Microsoft.XboxSpeechToTextOverlay'
rem   from provisioning. They will not be installed anymore for newly created
rem   user accounts. Additionally, it creates a script for uninstalling those
rem   packages in the 'Startup' folder of the start menu, for each user who
rem   has the respective package installed. The automatically created script
rem   deletes itself after the first run which is triggered at login time.
rem Tested with Win 10 Pro 64bit.
rem by Ingo Breßler in 2017 (dev at ingobressler.net)
cls

rem Check for admin permissions
fltmc >nul 2>&1 && (
	echo Admin permissions detected.
) || (
	echo Unprivileged user detected.
	rem exit /b
)

rem extracts usernames from between brackets [], mind the escape char ^
set userpattern=\"\[^([^^^^\]]+^)\]\"
set tmpfile=%TEMP%\_pckg_remove_tmp.txt
rem add autostart script
set autostartscript=AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\remove_packages.bat
set users=
setlocal enabledelayedexpansion
for %%a in (%*) do (
	rem for each provided package name search key
	echo Uninstall installed package '%%a' first
	rem get the full package name first
	set basecmd=get-appxpackage -AllUsers ^| where-object {$_.name -like \"*%%a*\"}
	set pfncmd=powershell -Command "& {!basecmd! | select-string -inputobject {$_.packagefullname} -pattern ".*" -all; }"
	echo pfncmd: !pfncmd!
	!pfncmd!
	for /f "tokens=*" %%i in ('!pfncmd!') do (
		rem for each package matching the given search key
		set pfn=%%i
		echo pfn: '!pfn!'
		set usercmd=powershell -Command "& {get-appxpackage -AllUsers ^| where-object {$_.packagefullname -like \"!pfn!\"} ^| select-string -inputobject {$_.packageuserinformation} -pattern %userpattern% -all ^| %% { $_.Matches } ^| %% { $_.captures.groups[1].Value } }"
		rem  echo usercmd: !usercmd!
		rem  !usercmd!
		rem this does not work for some reason (pattern?)
		rem for /f "tokens=*" %%u in ('!usercmd!') do echo un: '%%u'
		rem using a temorary file to get the user names
		!usercmd! > %tmpfile%
		echo start:
		for /f %%u in (%tmpfile%) do (
			echo Stage package !pfn! to be removed for %%u
			set scriptabs=%appdata%\..\..\..\%%u\%autostartscript%
			echo as: '!scriptabs!'
			rem add each user to the list once
			set "TRUE="
			rem username is not in the list yet
			if "x!users:%%u=!"=="x!users!" set TRUE=1
			rem list is empty
			if "x!users!"=="x" set TRUE=1
			if defined TRUE (
				set users=!users! %%u
				rem clear autostart script first
				if exist "!scriptabs!" del "!scriptabs!"
				echo @echo off>> "!scriptabs!"
			)
			echo echo Removing '!pfn!'>> "!scriptabs!"
			echo pause>> "!scriptabs!"
			set rmcmd=powershell -Command "& {remove-appxpackage !pfn!}"
			echo rem !rmcmd! >> "!scriptabs!"
		)
	)
	echo done.
	rem echo Remove '%%a' for new users (provisioned)
	rem powershell -Command "& {get-appxprovisionedpackage -online | where-object {$_.packagename -like \"*%%a*\"} | select packagename | remove-appxprovisionedpackage -online;}"
)
:end
if exist %tmpfile% del %tmpfile%
echo users found: !users!
for %%u in (!users!) do (
	echo user: %%u
	set scriptabs=%appdata%\..\..\..\%%u\%autostartscript%
	echo as: '!scriptabs!'
	if exist "!scriptabs!" (
		echo set scriptpath=%%~dpf0>> "!scriptabs!"
		echo echo Finally removing '%%scriptpath%%'>> "!scriptabs!"
		echo exit /b>> "!scriptabs!"
		echo pause>> "!scriptabs!"
		echo del %%scriptpath%% >> "!scriptabs!"
		echo del "!scriptabs!" >> "!scriptabs!"
	)
)

pause