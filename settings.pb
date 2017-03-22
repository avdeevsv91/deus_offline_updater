system_debug.l = 0 ; Режим отладки
cache_updates.l = 1 ; Обновлять кеш с сервера
cache_hidden.l = 0  ; Загружать скрытые обновления

; Читаем настройки из файла
If OpenPreferences("config.cfg", #PB_Preference_GroupSeparator)
  PreferenceGroup("system")
  system_debug = ReadPreferenceLong("debug", system_debug)
  PreferenceGroup("cache")
  cache_updates = ReadPreferenceLong("updates", cache_updates)
  cache_hidden = ReadPreferenceLong("hidden", cache_hidden)
  ClosePreferences()
EndIf

; Окно настроек
Exit.b = #False
If OpenWindow(0, #PB_Any, #PB_Any, 230, 160, "Settings", #PB_Window_ScreenCentered)
  FrameGadget(0, 5, 5, 220, 80, " Online updates ")
  CheckBoxGadget(1, 15, 25, 200, 25, "Download new updates") : If cache_updates : SetGadgetState(1, #PB_Checkbox_Checked) : Else : SetGadgetState(1, #PB_Checkbox_Unchecked) : EndIf
  CheckBoxGadget(2, 15, 50, 200, 25, "Show hidden updates") : If cache_hidden : SetGadgetState(2, #PB_Checkbox_Checked) : Else : SetGadgetState(2, #PB_Checkbox_Unchecked) : EndIf
  CheckBoxGadget(3, 15, 90, 200, 25, "Enable debug mode") : If system_debug : SetGadgetState(3, #PB_Checkbox_Checked) : Else : SetGadgetState(3, #PB_Checkbox_Unchecked) : EndIf
  ButtonGadget(4, 10, 125, 100, 25, "Cancel")
  ButtonGadget(5, 120, 125, 100, 25, "Save")
  Repeat
    Select WaitWindowEvent(100)
      Case #PB_Event_Gadget
        Select EventGadget()
          Case 4 ; Cancel
            Exit = #True
          Case 5 ; Save
            cache_updates = GetGadgetState(1)
            cache_hidden  = GetGadgetState(2)
            system_debug  = GetGadgetState(3)
            Exit = #True
        EndSelect
    EndSelect
  Until Exit
  CloseWindow(0)
EndIf

; Сохраняем настройки в файл
If Not OpenPreferences("config.cfg", #PB_Preference_GroupSeparator)
  If Not CreatePreferences("config.cfg", #PB_Preference_GroupSeparator)
    MessageRequester("Error", "Can`t create config file! The current settings will be lost.", #MB_ICONERROR)
    End
  EndIf
EndIf
PreferenceGroup("system")
WritePreferenceLong("debug", system_debug)
PreferenceGroup("cache")
WritePreferenceLong("updates", cache_updates)
WritePreferenceLong("hidden", cache_hidden)
ClosePreferences()

End

; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 12
; FirstLine = 7
; EnableUnicode
; EnableThread
; EnableXP
; EnableAdmin
; UseIcon = settings.ico
; Executable = settings.exe
; EnableCompileCount = 5
; EnableBuildCount = 3
; IncludeVersionInfo
; VersionField0 = 1.0.%BUILDCOUNT.%COMPILECOUNT
; VersionField1 = 1.0.9.15
; VersionField2 = TheSoulTaker48
; VersionField3 = Deus Offline Updater Settings
; VersionField4 = 1.0.9.15
; VersionField5 = 1.0.%BUILDCOUNT.%COMPILECOUNT
; VersionField6 = Unofficial XP Deus update settings
; VersionField7 = deus_offline_updater_settings
; VersionField8 = %EXECUTABLE
; VersionField9 = TheSoulTaker48
; VersionField13 = thesoultaker48@gmail.com
; VersionField14 = http://deus.lipkop.club
; VersionField15 = VOS_NT_WINDOWS32
; VersionField16 = VFT_APP