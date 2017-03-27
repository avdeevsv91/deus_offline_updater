@echo off

del /q "sfx.exe"
"%ProgramFiles%\WinRAR\WinRAR.exe" a -ibck -iadm -inul -sfx -iiconsfx.ico -iimgsfx.bmp -zsfx.opt sfx @sfx.lst
if errorlevel 1 echo There was an error on creating the SFX archive!
