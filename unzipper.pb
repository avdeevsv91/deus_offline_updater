
; Процедура записи сообщения в лог файл
Procedure.l AddToLogFile(Message.s, DateTime.b=#True, NewLine.b=#True, Enable.b=#True)
  If Enable
    LogFile.l = OpenFile(#PB_Any, "updater.log", #PB_File_Append)
    If LogFile
      DateString$ = ""
      If DateTime
        Date.l = Date()
        Hour$ = LSet(Str(Hour(Date)), 2, "0")
        Minute$ = LSet(Str(Minute(Date)), 2, "0")
        Second$ = LSet(Str(Second(Date)), 2, "0")
        Day$ = LSet(Str(Day(Date)), 2, "0")
        Month$ = LSet(Str(Month(Date)), 2, "0")
        Year$ = LSet(Str(Year(Date)), 4)
        DateString$ = "["+Hour$+":"+Minute$+":"+Second$+" "+Day$+"/"+Month$+"/"+Year$+"]: "
      EndIf
      If NewLine
        WriteStringN(LogFile, DateString$+Message)
      Else
        WriteString(LogFile, DateString$+Message)
      EndIf
      CloseFile(LogFile)
      ProcedureReturn #True
    Else
      ProcedureReturn #False
    EndIf
  Else
    ProcedureReturn -1
  EndIf
EndProcedure

; Читаем настройки из файла
system_debug.l = 0 ; Режим отладки
If OpenPreferences("config.cfg", #PB_Preference_GroupSeparator)
  PreferenceGroup("system")
  system_debug = ReadPreferenceLong("debug", system_debug)
  ClosePreferences()
EndIf

; Получаем версию программы
ProgramFilename$ = ProgramFilename()
UnzipperVersion$ = GetFileVersion(ProgramFilename$, #GFVI_FileVersion, #False)
AddToLogFile("Unzipper started (version "+UnzipperVersion$+").", #True, #True, system_debug)

; Ждем завершения работы dou.exe
AddToLogFile("Waiting for the completion of the dou.exe program...", #True, #False, system_debug)
WaitCounter.l = 0
Repeat
  UpdaterRunning.b = #False
  EnumProcessInit()
  Repeat
    ProcessName.s = EnumProcess()
    If LCase(ProcessName) = "dou.exe"
      UpdaterRunning = #True
    EndIf
  Until ProcessName = ""
  WaitCounter + 1
  If WaitCounter>50 ; 5 second
    AddToLogFile("ERROR!", #False, #True, system_debug)
    AddToLogFile("Attempts to terminate the dou.exe process...", #True, #False, system_debug)
    DOUPid.l = GetPidProcess("dou.exe")
    If KillProcess(DOUPid)
      UpdaterRunning = #False
    Else
      AddToLogFile("ERROR!", #False, #True, system_debug)
      AddToLogFile("Unpacking interrupted!", #True, #True, system_debug)
      MessageRequester("Error", "Can`t terminate the dou.exe process!", #MB_ICONERROR)
      End
    EndIf
  EndIf
  Delay(100)
Until (Not UpdaterRunning)
AddToLogFile("DONE!", #False, #True, system_debug)

; Устанавливаем обновления
If FileSize("updates/deus_offline_updater.zip")<>-1
  AddToLogFile("Unpacking file "+Chr(34)+"updates/deus_offline_updater.zip"+Chr(34)+"...", #True, #False, system_debug)
  ;- TODO: Избавиться от внешнего 7z.exe
  sZIP.l = RunProgram("7z.exe", "e -aoa -o./ -x!unzipper.exe -y updates/deus_offline_updater.zip", GetPathPart(ProgramFilename$), #PB_Program_Open|#PB_Program_Hide)
  If sZIP
    OpenWindow(0, #PB_Any, #PB_Any, 300, 35, "Updating", #PB_Window_ScreenCentered)
    TextGadget(0, 5, 5, 290, 25, "Please, wait...", #PB_Text_Center)
    Repeat
      WaitWindowEvent(100)
    Until Not ProgramRunning(sZIP)
    CloseWindow(0)
    AddToLogFile("DONE!", #False, #True, system_debug)
    AddToLogFile("Execute file "+Chr(34)+"dou.exe"+Chr(34)+"...", #True, #False, system_debug)
    If RunProgram("dou.exe")
      AddToLogFile("DONE!", #False, #True, system_debug)
    Else
      AddToLogFile("ERROR!", #False, #True, system_debug)
      MessageRequester("Error", "Can`t execute the dou.exe file!", #MB_ICONERROR)
    EndIf
    End
  Else
    AddToLogFile("ERROR!", #False, #True, system_debug)
    MessageRequester("Error", "Can`t execute the 7z.exe file!", #MB_ICONERROR)
  EndIf
Else
  MessageRequester("Error", "Can`t find file "+Chr(34)+"updates/deus_offline_updater.zip"+Chr(34)+"!", #MB_ICONERROR)
EndIf
End

; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 66
; FirstLine = 56
; Folding = -
; EnableUnicode
; EnableThread
; EnableXP
; EnableAdmin
; UseIcon = unzipper.ico
; Executable = unzipper.exe
; EnableCompileCount = 14
; EnableBuildCount = 4
; IncludeVersionInfo
; VersionField0 = 1.0.%BUILDCOUNT.%COMPILECOUNT
; VersionField1 = 1.0.10.17
; VersionField2 = LipKop.club
; VersionField3 = Unzipper
; VersionField4 = 1.0.10.17
; VersionField5 = 1.0.%BUILDCOUNT.%COMPILECOUNT
; VersionField6 = Unofficial XP Deus updater: unzipper
; VersionField7 = deus_offline_updater_unzipper
; VersionField8 = %EXECUTABLE
; VersionField9 = SoulTaker
; VersionField13 = thesoultaker48@gmail.com
; VersionField14 = http://deus.lipkop.club
; VersionField15 = VOS_NT_WINDOWS32
; VersionField16 = VFT_APP