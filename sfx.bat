@echo off

del /q "%sfx_name%.exe"
"C:\Program Files\WinRAR\rar.exe" a -sfxdefault.sfx -zsfx.opt sfx @sfx.lst
