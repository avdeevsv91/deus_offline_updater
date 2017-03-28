@echo off

set PATH=%PATH%;%CD%\utilities
set PATH=%PATH%;%ProgramFiles%\WinRar
set PATH=%PATH%;%ProgramFiles%\PureBasic 5.31

echo ****************************************
echo Deus Offline Updater (build.bat)
echo.
echo Author: SoulTaker
echo URL: http://deus.lipkop.club
echo E-Mail: thesoultaker48@gmail.com
echo ****************************************
echo.
echo With this tool, you can build a project from the source code.
pause
echo.

echo Build main.pbp (target: dou)...
purebasic /quiet /build "main.pbp" /target "dou"
for /f "tokens=1,2 delims=	" %%i in ('filever /v "dou.exe"^|find /i "FileVersion"') do (
	set VERSION_STRING=%%j
)
echo Build main.pbp (target: settings)...
rplstr -s:"{VERSION_STRING}" -r:"%VERSION_STRING%" "main.pbp"
purebasic /quiet /build "main.pbp" /target "settings"
rplstr -s:"%VERSION_STRING%" -r:"{VERSION_STRING}" "main.pbp"

echo.
echo Build done!
echo.

echo The current version of the product is %VERSION_STRING%
echo.

echo Create an readme.txt file...
copy /y "info.txt" "readme.txt"
rplstr -s:"{VERSION_STRING}" -r:"%VERSION_STRING%" "readme.txt"

echo Create an SFX script file...
echo ;Расположенный ниже комментарий содержит команды SFX-сценария>sfx.opt
echo.>>sfx.opt
echo Path=Deus Offline Updater>>sfx.opt
echo Presetup=taskkill /im dou.exe /f>>sfx.opt
echo Setup=dou.exe /installed>>sfx.opt
echo SetupCode>>sfx.opt
echo Overwrite=^1>>sfx.opt
echo Title=Deus Offline Updater v%VERSION_STRING%>>sfx.opt
echo Text>>sfx.opt
echo {>>sfx.opt
setlocal EnableDelayedExpansion
for /f "delims=" %%i in (readme.txt) do (
	set line=%%i
	set line=!line: =!
	if not "!line!"=="" (
	 	echo %%i>>sfx.opt
	)
	echo.>>sfx.opt
)
setlocal DisableDelayedExpansion
echo }>>sfx.opt
echo Shortcut=D, dou.exe, , , "Deus Offline Updater", >>sfx.opt
echo Shortcut=P, dou.exe, "Deus Offline Updater", , "Deus Offline Updater", >>sfx.opt
echo Shortcut=P, settings.exe, "Deus Offline Updater", , Settings, >>sfx.opt

echo Create an SFX archive...
del /q "deus_offline_updater.exe"
winrar a -ibck -iadm -inul -sfx -iiconsfx.ico -iimgsfx.bmp -zsfx.opt deus_offline_updater @sfx.lst
del /q "readme.txt"
del /q "sfx.opt"
echo.

echo SFX done!

pause
