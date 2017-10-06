@echo off
rem onedrive_remove.bat
rem Disables and removes OneDrive from Windows 10.
rem Inspired by https://answers.microsoft.com/en-us/onedrive/forum/odoptions-oddesktop/how-to-uninstall-onedrive-completely-in-windows-10/e735a3b8-09f1-40e2-89c3-b93cf7fe6994
rem Tested with Win 10 Pro 64bit (1703).
rem by Ingo Breßler in 2017 (dev at ingobressler.net)
cls

rem Check for admin permissions
fltmc >nul 2>&1 || (
	echo Please run with admin permissions!
	exit /b
)

set x86="%SYSTEMROOT%\System32\OneDriveSetup.exe"
set x64="%SYSTEMROOT%\SysWOW64\OneDriveSetup.exe"

rem try to disable OneDrive system-wide first
set scriptpath=%~dp0
set scriptpath=%scriptpath:~0,-1%
echo scriptpath: %scriptpath%
set lgpo="%scriptpath%\lgpo\lgpo.exe"
if not exist %lgpo% (
	echo The Group Policy tool was not found in
	echo  %lgpo%^!
	echo It is part of the 'Microsoft Security Compliance Toolkit':
	echo https://www.microsoft.com/en-us/download/details.aspx?id=55319
	exit /b
)
set regpol="%scriptpath%\onedrive_registry.pol"
if exist %regpol% (
	%lgpo% /m %regpol%
)

echo Closing OneDrive process.
echo.
taskkill /f /im OneDrive.exe > NUL 2>&1
ping 127.0.0.1 -n 5 > NUL 2>&1

echo Uninstalling OneDrive.
echo.
set setupfile=""
if exist %x64% (
	set setupfile=%x64%
) else (
	set setupfile=%x86%
)
%setupfile% /uninstall
ping 127.0.0.1 -n 5 > NUL 2>&1

echo Removing OneDrive leftovers.
echo.
rd "%USERPROFILE%\OneDrive" /Q /S > NUL 2>&1
rd "C:\OneDriveTemp" /Q /S > NUL 2>&1
rd "%LOCALAPPDATA%\Microsoft\OneDrive" /Q /S > NUL 2>&1
rd "%PROGRAMDATA%\Microsoft OneDrive" /Q /S > NUL 2>&1 

echo Removeing OneDrive from the Explorer Side Panel.
echo.
REG DELETE "HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f > NUL 2>&1
REG DELETE "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f > NUL 2>&1

rem prevent any future invocation of onedrive setup
echo Take ownership of '%setupfile%'
takeown /f "%setupfile%"
ping 127.0.0.1 -n 5 > NUL 2>&1
del %setupfile%
type NUL > %setupfile%
icacls %setupfile% /inheritance:d
icacls %setupfile% /grant %username%:F
icacls %setupfile% /deny *S-1-15-2-1:F
icacls %setupfile% /deny SYSTEM:F
icacls %setupfile% /deny "NT SERVICE\TrustedInstaller":F
pause
dir %setupfile%
icacls %setupfile%
echo Should be zero size. If not, run again
pause
