@echo off
rem pckg_list.bat
rem Lists installed or provisioned Windows (modern app) packages.
rem Tested with Win 10 Pro 64bit.
rem by Ingo Breßler in 2017 (dev at ingobressler.net)
cls

rem Check for admin permissions
fltmc >nul 2>&1 || (
	echo Please run with admin permissions!
	exit /b
)

if "%*"=="" (
	echo packages:
	powershell -Command "& {get-appxpackage -AllUsers | sort packagefullname | select name;}"

	echo packages provisioned:
	powershell -Command "& {get-appxprovisionedpackage -online | sort packagename | select displayname;}"
) else (
	for %%p in (%*) do (
		echo Searching for %%p:
		powershell -Command "& {get-appxpackage -AllUsers | sort packagefullname | where-object {$_.name -like \"*%%p*\"}; }"
	)
)

pause