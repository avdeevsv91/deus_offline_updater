; Зависимости
XIncludeFile #PB_Compiler_Home+"hmod\DroopyLib.pbi"
UseModule DroopyLib

; Инициализация перевода
XIncludeFile #PB_Compiler_FilePath+"includes\i18n\i18n.pbi"
Translator_init("languages/", #Null$)

UsePNGImageDecoder() ; Для иконок

system_updates.l = 1 ; Проверять обновления программы
system_debug.l   = 0 ; Режим отладки
cache_updates.l  = 1 ; Обновлять прошивки с сервера
cache_beta.l   = 0   ; Загружать бета версии прошивок

; Читаем настройки из файла
If OpenPreferences("config.cfg", #PB_Preference_GroupSeparator)
  PreferenceGroup("system")
  system_updates = ReadPreferenceLong("updates", system_updates)
  system_debug   = ReadPreferenceLong("debug",   system_debug)
  PreferenceGroup("cache")
  cache_updates = ReadPreferenceLong("updates",  cache_updates)
  cache_beta    = ReadPreferenceLong("beta",     cache_beta)
  ClosePreferences()
EndIf

; Получаем версию программы
CurrentUpdaterVersion$ = GetFileVersion("dou.exe", #GFVI_FileVersion, #False)

; Окно настроек
Exit.b = #False
If OpenWindow(0, #PB_Any, #PB_Any, 230, 185, FormatStr(__("DOU: Settings (version %1)"), CurrentUpdaterVersion$), #PB_Window_ScreenCentered)
  FrameGadget(0, 5, 5, 220, 105, " "+__("Online updates")+" ")
  CheckBoxGadget(7, 15, 25, 200, 25, __("Check for software updates")) : If system_updates : SetGadgetState(7, #PB_Checkbox_Checked) : Else : SetGadgetState(7, #PB_Checkbox_Unchecked) : EndIf
  CheckBoxGadget(1, 15, 50, 200, 25, __("Download firmware updates")) : If cache_updates : SetGadgetState(1, #PB_Checkbox_Checked) : Else : SetGadgetState(1, #PB_Checkbox_Unchecked) : EndIf
  CheckBoxGadget(2, 15, 75, 200, 25, __("Including beta versions")) : If cache_beta : SetGadgetState(2, #PB_Checkbox_Checked) : Else : SetGadgetState(2, #PB_Checkbox_Unchecked) : EndIf
  CheckBoxGadget(3, 15, 115, 200, 25, __("Enable debug mode")) : If system_debug : SetGadgetState(3, #PB_Checkbox_Checked) : Else : SetGadgetState(3, #PB_Checkbox_Unchecked) : EndIf
  ButtonGadget(4, 10, 150, 85, 25, __("Cancel"))
  ButtonGadget(5, 100, 150, 85, 25, __("Save"))
  ButtonImageGadget(6, 195, 150, 25, 25, ImageID(CatchImage(#PB_Any, ?HelpButton))) : GadgetToolTip(6, __("Help"))
  Repeat
    Select WaitWindowEvent(100)
      Case #PB_Event_Gadget
        Select EventGadget()
          Case 4 ; Cancel
            Exit = #True
          Case 5 ; Save
            cache_updates   = GetGadgetState(1)
            cache_beta      = GetGadgetState(2)
            system_updates  = GetGadgetState(7)
            system_debug    = GetGadgetState(3)
            Exit = #True
          Case 6 ; Help
            RunProgram("http://deus.lipkop.club/wiki/Альтернативный_сервер_обновлений")
        EndSelect
    EndSelect
  Until Exit
  CloseWindow(0)
EndIf

; Сохраняем настройки в файл
If Not OpenPreferences("config.cfg", #PB_Preference_GroupSeparator)
  If Not CreatePreferences("config.cfg", #PB_Preference_GroupSeparator)
    MessageRequester(__("Error"), __("Can`t create config file! The current settings will be lost."), #MB_ICONERROR)
    End
  EndIf
EndIf
PreferenceGroup("system")
WritePreferenceLong("updates", system_updates)
WritePreferenceLong("debug",   system_debug)
PreferenceGroup("cache")
WritePreferenceLong("updates", cache_updates)
WritePreferenceLong("hidden",  cache_beta)
ClosePreferences()

End 0

DataSection
  HelpButton:
  IncludeBinary "help_button.png"
EndDataSection


; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 31
; FirstLine = 18
; EnableThread
; EnableXP
; EnableAdmin
; UseIcon = settings.ico
; Executable = settings.exe
; EnableCompileCount = 10
; EnableBuildCount = 8
; IncludeVersionInfo
; VersionField0 = 1.0.%BUILDCOUNT.%COMPILECOUNT
; VersionField1 = 1.0.15.28
; VersionField2 = LipKop.club
; VersionField3 = Settings
; VersionField4 = 1.0.15.28
; VersionField5 = 1.0.%BUILDCOUNT.%COMPILECOUNT
; VersionField6 = Unofficial XP Deus updater: settings
; VersionField7 = deus_offline_updater_settings
; VersionField8 = %EXECUTABLE
; VersionField9 = SoulTaker
; VersionField13 = thesoultaker48@gmail.com
; VersionField14 = http://deus.lipkop.club
; VersionField15 = VOS_NT_WINDOWS32
; VersionField16 = VFT_APP
; EnableUnicode