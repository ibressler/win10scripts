::@echo off
:: Install winhlp32 on Win10, using Win8.1 update KB917607
::
:: Tested on 32bit and 64bit Win10
:: expects Windows8.1-KB917607-x86.msu or Windows8.1-KB917607-x64.msu to be present
:: (microsoft.com/en-us/download/details.aspx?id=47671)
::
:: source:
:: tenforums.com/general-support/16982-cant-read-older-hlp-files-windows-10-a-3.html#post377638
:: 2018-11-12, fixes and adjustments by Ingo Bressler (dev@ingobressler.net)

setlocal enableExtensions

%windir%\system32\reg.exe query "HKU\S-1-5-19" >nul 2>&1 || goto :eof
set arch=x86
%windir%\system32\reg.exe query "hklm\software\microsoft\Windows NT\currentversion" /v buildlabex | find /i "amd64" 1>nul && set arch=x64
cd /d "%~dp0"

if not exist Windows8.1-KB917607-%arch%.msu (
  echo Windows8.1-KB917607-%arch%.msu was not found in the current folder
  echo.
  echo Press any key to Exit
  pause >nul
  exit
)

if not exist "%windir%\servicing\packages\*Winhelp*.mum" (
  Windows8.1-KB917607-%arch%.msu /quiet /norestart
)

:: determine the locale, winhlp32 translation file, available on the system
for /d %%I IN (c:\windows\*-*) DO if exist %%~fI\winhlp32.exe.mui set lang=%%~nI
set lang=en-us

:: extract the archive if not done already
if exist .\temp goto test32
mkdir .\temp
expand -f:*Windows*.cab Windows8.1-KB917607-%arch%.msu .\ >nul
expand -f:* Windows8.1-KB917607-%arch%.cab .\temp >nul
del /f /q Windows8.1-KB917607-%arch%.cab >nul

:test32
if /i NOT "%arch%"=="x86" goto test64
:: figure out the necessary paths first
for /d %%I IN (temp\x86_microsoft-windows-winhstb_*) DO set src32=%%~fI
if not exist "%src32%" goto cleanup
for /d %%I IN (temp\x86_microsoft-windows-winhstb.res*_%lang%_*) DO set lang32=%%~fI
:: use english fallback if language was not found in the update package
if not exist "%lang32%" set lang=en-us
for /d %%I IN (temp\x86_microsoft-windows-winhstb.res*_%lang%_*) DO set lang32=%%~fI

:: start copying over files from the update package
copy /y %src32%\ftlx0411.dll %windir%\system32
copy /y %src32%\ftlx041e.dll %windir%\system32
copy /y %src32%\ftsrch.dll %windir%\system32
::icacls     "%windir%\winhlp32.exe" /save "%temp%\AclFile" >nul
takeown /f "%windir%\winhlp32.exe" >nul
icacls     "%windir%\winhlp32.exe" /grant *S-1-5-32-544:F >nul
takeown /f "%windir%\%lang%\winhlp32.exe.mui" >nul
icacls     "%windir%\%lang%\winhlp32.exe.mui" /grant *S-1-5-32-544:F >nul
copy /y %src32%\winhlp32.exe %windir%
copy /y %lang32%\winhlp32.exe.mui %windir%\%lang%
icacls     "%windir%\winhlp32.exe" /setowner "NT Service\TrustedInstaller" >nul
icacls     "%windir%\%lang%\winhlp32.exe.mui" /setowner "NT Service\TrustedInstaller" >nul
::icacls "%windir%" /restore "%temp%\AclFile" >nul
::del /f /q "%temp%\AclFile" >nul

:test64
if /i NOT "%arch%"=="x64" goto cleanup

for /d %%I IN (temp\x86_microsoft-windows-winhstb_*) DO set src32=%%~fI
if not exist "%src32%" goto cleanup
for /d %%I IN (temp\amd64_microsoft-windows-winhstb_*) DO set src64=%%~fI
if not exist "%src64%" goto cleanup
:: find language file location
for /d %%I IN (temp\x86_microsoft-windows-winhstb.res*_%lang%_*) DO set lang32=%%~fI
:: use english fallback if language was not found in the update package
if not exist "%lang32%" set lang=en-us
for /d %%I IN (temp\x86_microsoft-windows-winhstb.res*_%lang%_*) DO set lang32=%%~fI
for /d %%I IN (temp\amd64_microsoft-windows-winhstb.res*_%lang%_*) DO set lang64=%%~fI

:: start copying over files from the update package
copy /y %src64%\ftlx0411.dll %windir%\syswow64
copy /y %src64%\ftlx041e.dll %windir%\syswow64
copy /y %src64%\ftsrch.dll %windir%\syswow64
copy /y %src32%\ftlx0411.dll %windir%\system32
copy /y %src32%\ftlx041e.dll %windir%\system32
copy /y %src32%\ftsrch.dll %windir%\system32
::icacls     "%windir%\winhlp32.exe" /save "%temp%\AclFile" >nul
takeown /f "%windir%\winhlp32.exe" >nul
icacls     "%windir%\winhlp32.exe" /grant *S-1-5-32-544:F >nul
takeown /f "%windir%\%lang%\winhlp32.exe.mui" >nul
icacls     "%windir%\%lang%\winhlp32.exe.mui" /grant *S-1-5-32-544:F >nul
copy /y %src64%\winhlp32.exe %windir%
copy /y %lang64%\winhlp32.exe.mui %windir%\%lang%
icacls     "%windir%\winhlp32.exe" /setowner "NT Service\TrustedInstaller" >nul
icacls     "%windir%\%lang%\winhlp32.exe.mui" /setowner "NT Service\TrustedInstaller" >nul
::icacls "%windir%" /restore "%temp%\AclFile" >nul
::del /f /q "%temp%\AclFile" >nul

:cleanup
rd /s /q .\temp >nul
echo.
echo Done.
echo.
echo Press any key to Exit
pause >nul
exit /b
