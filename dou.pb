; Зависимости
XIncludeFile #PB_Compiler_Home+"hmod\DroopyLib.pbi"
UseModule DroopyLib

; Инициализация перевода
XIncludeFile #PB_Compiler_FilePath+"includes\i18n\i18n.pbi"
Translator_init("languages", #Null$)

; Инициализация сети
InitNetwork()

; Список файлов, из которых состоит прошивка
Structure FirmwareFile
  File.s      ; Имя файла прошивки
  Required.b  ; Этот файл обязателен или нет
EndStructure
Global NewList FirmwareFiles.FirmwareFile()
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "md5sums.txt"          : FirmwareFiles()\Required = #False
; Casque
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "Casque.txt"           : FirmwareFiles()\Required = #False ; ???
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "Casque_B.txt"         : FirmwareFiles()\Required = #False ; ???
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "C01.txt"              : FirmwareFiles()\Required = #True
; Disques
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "004.txt"              : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "004_R.txt"            : FirmwareFiles()\Required = #False ; ???
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "104.txt"              : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "104_R.txt"            : FirmwareFiles()\Required = #False ; ???
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "104_7.txt"            : FirmwareFiles()\Required = #False ; V4 only
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "R_004.txt"            : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "R_104.txt"            : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "coil_hf_22.txt"       : FirmwareFiles()\Required = #False ; ???
; Telecommande
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "Telecommande.txt"     : FirmwareFiles()\Required = #False ; ???
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "Restaure.txt"         : FirmwareFiles()\Required = #False
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "Restaure20130108.txt" : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T01.txt"              : FirmwareFiles()\Required = #False
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T02.txt"              : FirmwareFiles()\Required = #False ; English
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T03.txt"              : FirmwareFiles()\Required = #False
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T04.txt"              : FirmwareFiles()\Required = #False
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T05.txt"              : FirmwareFiles()\Required = #False
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T06.txt"              : FirmwareFiles()\Required = #False
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T07.txt"              : FirmwareFiles()\Required = #False
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T08.txt"              : FirmwareFiles()\Required = #False ; VIP
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T09.txt"              : FirmwareFiles()\Required = #False
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T15.txt"              : FirmwareFiles()\Required = #False
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T0A.txt"              : FirmwareFiles()\Required = #False
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T0B.txt"              : FirmwareFiles()\Required = #False
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T0C.txt"              : FirmwareFiles()\Required = #False
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T0D.txt"              : FirmwareFiles()\Required = #False ; Russian
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T0E.txt"              : FirmwareFiles()\Required = #False
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T0F.txt"              : FirmwareFiles()\Required = #False
; Other
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "Release.txt"          : FirmwareFiles()\Required = #False ; ???
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "soft.txt"             : FirmwareFiles()\Required = #False    ; ???
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "PinpointerMI6.txt"    : FirmwareFiles()\Required = #False ; ???


; Функция подсчета количества строк в файле
Procedure.l CountFileStrings(FileName.s)
  File.l = ReadFile(#PB_Any, FileName)
  If File
    Count.l = 0
    While Eof(File) = 0
      ReadString(File)
      Count + 1
    Wend
    CloseFile(File)
    ProcedureReturn Count
  Else
    ProcedureReturn -1
  EndIf
EndProcedure

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

; Получаем версию программы
Global ProgramFilename$ = ProgramFilename()
Global CurrentUpdaterVersion$ = GetFileVersion(ProgramFilename$, #GFVI_FileVersion, #False)

; Читаем настройки из файла
Global system_debug.l = 0 ; Режим отладки
cache_updates.l = 1 ; Обновлять кеш с сервера
cache_hidden.l = 0  ; Загружать скрытые обновления
If OpenPreferences("config.cfg", #PB_Preference_GroupSeparator)
  PreferenceGroup("system")
  system_debug = ReadPreferenceLong("debug", system_debug)
  PreferenceGroup("cache")
  cache_updates = ReadPreferenceLong("updates", cache_updates)
  cache_hidden = ReadPreferenceLong("hidden", cache_hidden)
  ClosePreferences()
  AddToLogFile(FormatStr(__("Updater started (version %1)."), CurrentUpdaterVersion$), #True, #True, system_debug)
Else
  AddToLogFile(FormatStr(__("Updater started (version %1)."), CurrentUpdaterVersion$), #True, #True, system_debug)
  AddToLogFile(__("Can`t open config file! Will be used default settings."), #True, #True, system_debug)
  DisclaimerTitle$ = "Warning!"
  DisclaimerText$ = "This program update IS NOT OFFICIAL and is intended for use solely for informational purposes." + Chr(13)
  DisclaimerText$ + Chr(13)
  DisclaimerText$ + "The author is not responsible for any damage (material or moral) caused to you or third parties resulting from the use of this software." + Chr(13)
  DisclaimerText$ + Chr(13)
  DisclaimerText$ + "All the steps you are at your own risk!" + Chr(13)
  MessageRequester(__(DisclaimerTitle$), __(DisclaimerText$), #MB_ICONWARNING)
EndIf
AddToLogFile(__("Current settings:"), #True, #True, system_debug)
AddToLogFile(LSet(#Null$, 3, Chr(9))+FormatStr(__("system_debug = %1;"), Str(system_debug)), #False, #True, system_debug)
AddToLogFile(LSet(#Null$, 3, Chr(9))+FormatStr(__("cache_updates = %1;"), Str(cache_updates)), #False, #True, system_debug)
AddToLogFile(LSet(#Null$, 3, Chr(9))+FormatStr(__("cache_hidden = %1;"), Str(cache_hidden)), #False, #True, system_debug)

; Создаем дирректории
If FileSize("updates")=-1
  AddToLogFile(FormatStr(__("The directory "+Chr(34)+"%1"+Chr(34)+" does Not exist! Create it..."), "updates")+" ", #True, #False, system_debug)
  If CreateDirectory("updates")
    AddToLogFile(__("DONE!"), #False, #True, system_debug)
  Else
    AddToLogFile(__("ERROR!"), #False, #True, system_debug)
  EndIf
EndIf
If FileSize("updates/cache_updates")=-1
  AddToLogFile(FormatStr(__("The directory "+Chr(34)+"%1"+Chr(34)+" does not exist! Create it..."), "updates/cache_updates")+" ", #True, #False, system_debug)
  If CreateDirectory("updates/cache_updates")
    AddToLogFile(__("DONE!"), #False, #True, system_debug)
  Else
    AddToLogFile(__("ERROR!"), #False, #True, system_debug)
  EndIf
EndIf
; Update: 4.0 -> 4.1
If FileSize("updates/cache_updates/DEUS_V4.1")=-1
  If FileSize("updates/cache_updates/DEUS_V4")=-2
    AddToLogFile(FormatStr(__("Rename the directory with cache (%1 to %2)..."), "DEUS_V4", "DEUS_V4.1")+" ", #True, #False, system_debug)
    If RenameFile("updates/cache_updates/DEUS_V4", "updates/cache_updates/DEUS_V4.1")
      AddToLogFile(__("DONE!"), #False, #True, system_debug)
    Else
      AddToLogFile(__("ERROR!"), #False, #True, system_debug)
    EndIf
  Else
    AddToLogFile(FormatStr(__("The directory "+Chr(34)+"%1"+Chr(34)+" does not exist! Create it..."), "updates/cache_updates/DEUS_V4.1")+" ", #True, #False, system_debug)
    If CreateDirectory("updates/cache_updates/DEUS_V4.1")
      AddToLogFile(__("DONE!"), #False, #True, system_debug)
    Else
      AddToLogFile(__("ERROR!"), #False, #True, system_debug)
    EndIf
  EndIf
Else
  If FileSize("updates/cache_updates/DEUS_V4")=-2
    AddToLogFile(FormatStr(__("Delete directory "+Chr(34)+"%1"+version$+Chr(34)+"..."), "updates/cache_updates/DEUS_V4")+" ", #True, #False, system_debug)
    If DeleteDirectory("updates/cache_updates/DEUS_V4", "", #PB_FileSystem_Recursive | #PB_FileSystem_Force)
      AddToLogFile(__("DONE!"), #False, #True, system_debug)
    Else
      AddToLogFile(__("ERROR!"), #False, #True, system_debug)
    EndIf      
  EndIf
EndIf
; Update: 4.1 -> 5.0
If FileSize("updates/cache_updates/DEUS_V5.0")=-1
  If FileSize("updates/cache_updates/DEUS_V4.1")=-2
    AddToLogFile(FormatStr(__("Rename the directory with cache (%1 to %2)..."), "DEUS_V4.1", "DEUS_V5.0")+" ", #True, #False, system_debug)
    If RenameFile("updates/cache_updates/DEUS_V4.1", "updates/cache_updates/DEUS_V5.0")
      AddToLogFile(__("DONE!"), #False, #True, system_debug)
    Else
      AddToLogFile(__("ERROR!"), #False, #True, system_debug)
    EndIf
  Else
    AddToLogFile(FormatStr(__("The directory "+Chr(34)+"%1"+Chr(34)+" does not exist! Create it..."), "updates/cache_updates/DEUS_V5.0")+" ", #True, #False, system_debug)
    If CreateDirectory("updates/cache_updates/DEUS_V5.0")
      AddToLogFile(__("DONE!"), #False, #True, system_debug)
    Else
      AddToLogFile(__("ERROR!"), #False, #True, system_debug)
    EndIf
  EndIf
Else
  If FileSize("updates/cache_updates/DEUS_V4.1")=-2
    AddToLogFile(FormatStr(__("Delete directory "+Chr(34)+"%1"+version$+Chr(34)+"..."), "updates/cache_updates/DEUS_V4.1")+" ", #True, #False, system_debug)
    If DeleteDirectory("updates/cache_updates/DEUS_V4.1", "", #PB_FileSystem_Recursive | #PB_FileSystem_Force)
      AddToLogFile(__("DONE!"), #False, #True, system_debug)
    Else
      AddToLogFile(__("ERROR!"), #False, #True, system_debug)
    EndIf      
  EndIf
EndIf

; Обработка внешних ключей запуска
For i=0 To CountProgramParameters()-1
  CurrentParemeter$ = ProgramParameter(i)
  CurrentParemeter$ = Trim(CurrentParemeter$)
  CurrentParemeter$ = LCase(CurrentParemeter$)
  Select CurrentParemeter$
    Case "/installed":
      If FileSize("updates/deus_offline_updater.exe")<>-1
        AddToLogFile(__("The program was successfully updated!"), #True, #True, system_debug)
        MessageRequester(__("Information"), __("The program was successfully updated!"), #MB_ICONINFORMATION)
      Else
        AddToLogFile(__("The program was successfully installed!"), #True, #True, system_debug)
        MessageRequester(__("Information"), __("The program was successfully installed!"), #MB_ICONINFORMATION)
      EndIf
      Goto ProgramEndPoint
      End
    Default:
      AddToLogFile(FormatStr(__("Unsupported startup key: %1"), CurrentParemeter$), #True, #True, system_debug)
  EndSelect
Next i

; Сравнивает два номера версий программ и возвращает True, если последняя новее
Procedure CompareProgramsVersions(CurrentVersion.s, LatestVersion.s)
  CVC.l = CountString(CurrentVersion, ".")
  LVC.l = CountString(LatestVersion, ".")
  If CVC>LVC : DVC.l = CVC : Else : DVC.l = LVC : EndIf
  For i=1 To DVC+1
    CVF$ = StringField(CurrentVersion, i, ".")
    LVF$ = StringField(LatestVersion, i, ".")
    If Val(LVF$)>Val(CVF$)
      ProcedureReturn #True
    ElseIf Val(LVF$)<Val(CVF$)
      ProcedureReturn #False
    EndIf
  Next i
  ProcedureReturn #False
EndProcedure

; Обновление программы и прошивок
Global VersionsFileName$ = "5_0_01" ;- FIXME: определить алгоритм формирования имени файла
Global UpdateSuccess.b = #False
Procedure CheckForNewUpdates(hidden)
  ; Обновление самой программы
  AddToLogFile(__("Checking the program update..."), #True, #True, system_debug)
  ; Получаем информацию о последней версии
  AddToLogFile(FormatStr(__("Download file "+Chr(34)+"%1"+Chr(34)+"..."), "http://deus.lipkop.club/dou/index.php")+" ", #True, #False, system_debug)
  LastUpdaterVersion$ = CurrentUpdaterVersion$
  If ReceiveHTTPFile("http://deus.lipkop.club/dou/index.php", "updates/dou.txt")
    AddToLogFile(__("DONE!"), #False, #True, system_debug)
    AddToLogFile(FormatStr(__("Read last program version from file "+Chr(34)+"%1"+Chr(34)+"..."), "updates/dou.txt")+" ", #True, #False, system_debug)
    If ReadFile(0, "updates/dou.txt")
      LastUpdaterVersion$ = #Null$
      AddToLogFile(__("DONE!"), #False, #True, system_debug)
      While Eof(0) = 0
        LastUpdaterVersion$ + ReadString(0)
      Wend
      LastUpdaterVersion$ = Trim(LastUpdaterVersion$)
      CloseFile(0)
    Else
      AddToLogFile(__("ERROR!"), #False, #True, system_debug)
    EndIf
  Else
    AddToLogFile(__("ERROR!"), #False, #True, system_debug)
  EndIf
  ; Если есть новая версия программы
  If CompareProgramsVersions(CurrentUpdaterVersion$, LastUpdaterVersion$)
    AddToLogFile(FormatStr(__("A new version %1 of the program is available."), LastUpdaterVersion$), #True, #True, system_debug)
    AddToLogFile(FormatStr(__("Download file "+Chr(34)+"%1"+Chr(34)+"..."), "http://deus.lipkop.club/dou/deus_offline_updater.exe")+" ", #True, #False, system_debug)
    If ReceiveHTTPFile("http://deus.lipkop.club/dou/deus_offline_updater.exe", "updates/deus_offline_updater.exe")
      AddToLogFile(__("DONE!"), #False, #True, system_debug)
      ; Запускаем установщик обновлений
      AddToLogFile(FormatStr(__("Execute file "+Chr(34)+"%1"+Chr(34)+"..."), "updates/deus_offline_updater.exe")+" ", #True, #False, system_debug)
      ProgramPathPart$ = GetPathPart(ProgramFilename$)
      hSFX.l = RunProgram("updates/deus_offline_updater.exe", "-s -d"+Chr(34)+ProgramPathPart$+Chr(34), ProgramPathPart$, #PB_Program_Open|#PB_Program_Hide)
      If hSFX
        AddToLogFile(__("DONE!"), #False, #True, system_debug)
        End
      Else
        AddToLogFile(__("ERROR!"), #False, #True, system_debug)
      EndIf
    Else
      AddToLogFile(__("ERROR!"), #False, #True, system_debug)
    EndIf
  Else ; Если новой версии нет, то проверим, возможно мы только что обновились и надо подчистить за собой
    AddToLogFile(__("There are no updates available."), #True, #True, system_debug)
    If FileSize("updates/deus_offline_updater.exe")<>-1
      AddToLogFile(FormatStr(__("Delete file "+Chr(34)+"updates/deus_offline_updater.exe"+Chr(34)+"..."), "")+" ", #True, #False, system_debug)
      If DeleteFile("updates/deus_offline_updater.exe", #PB_FileSystem_Force)
        AddToLogFile(__("DONE!"), #False, #True, system_debug)
      Else
        AddToLogFile(__("ERROR!"), #False, #True, system_debug)
      EndIf
      AddToLogFile(__("Software update finished."), #True, #True, system_debug)
    EndIf
  EndIf
  AddToLogFile(FormatStr(__("Delete file "+Chr(34)+"%1"+Chr(34)+"..."), "updates/dou.txt")+" ", #True, #False, system_debug)
  If DeleteFile("updates/dou.txt", #PB_FileSystem_Force)
    AddToLogFile(__("DONE!"), #False, #True, system_debug)
  Else
    AddToLogFile(__("ERROR!"), #False, #True, system_debug)
  EndIf
  ; Обновление прошивок в локальном каталоге
  ;- TODO: Обновление отдельных файлов по MD5 хешу
  HideGadget(1, #True) : HideGadget(0, #False)
  AddToLogFile(__("Checking the firmware update..."), #True, #True, system_debug)
  If hidden>0
    versions_url$ = "http://deus.lipkop.club/dou/updates/versions.php?show=all"
  Else
    versions_url$ = "http://deus.lipkop.club/dou/updates/versions.php"
  EndIf
  AddToLogFile(FormatStr(__("Download file "+Chr(34)+"%1"+Chr(34)+"..."), versions_url$)+" ", #True, #False, system_debug)
  If ReceiveHTTPFile(versions_url$, "updates/cache_updates/Versions_"+VersionsFileName$+".txt")
    AddToLogFile(__("DONE!"), #False, #True, system_debug)
    Count.l = CountFileStrings("updates/cache_updates/Versions_"+VersionsFileName$+".txt")
    If Count>0 And ReadFile(0, "updates/cache_updates/Versions_"+VersionsFileName$+".txt")
      SetGadgetAttribute(0, #PB_ProgressBar_Maximum, Count*ListSize(FirmwareFiles()))
      While Eof(0) = 0
        version$ = Trim(ReadString(0))
        If Len(version$)>0
          If FileSize("updates/cache_updates/DEUS_V5.0/"+version$) = -1 ; Если в локальном кеше такой прошивки нету
            AddToLogFile(FormatStr(__("Get firmware "+Chr(34)+"%1"+Chr(34)+"..."), version$), #True, #True, system_debug)
            ; Качаем ее во временный каталог
            DownloadOfSuccessful.b = #True
            AddToLogFile(FormatStr(__("Create directory "+Chr(34)+"%1"+version$+Chr(34)+"..."), "updates/cache_updates/")+" ", #True, #False, system_debug)
            If CreateDirectory("updates/cache_updates/"+version$)
              AddToLogFile(__("DONE!"), #False, #True, system_debug)
            Else
              AddToLogFile(__("ERROR!"), #False, #True, system_debug)
            EndIf
            ResetList(FirmwareFiles())
            While NextElement(FirmwareFiles())
              AddToLogFile(FormatStr(__("Download file "+Chr(34)+"%1"+Chr(34)+"..."), "http://deus.lipkop.club/dou/updates/"+version$+"/"+FirmwareFiles()\File)+" ", #True, #False, system_debug)
              If Not ReceiveHTTPFile("http://deus.lipkop.club/dou/updates/"+version$+"/"+FirmwareFiles()\File, "updates/cache_updates/"+version$+"/"+FirmwareFiles()\File) And FirmwareFiles()\Required = #True
                DownloadOfSuccessful.b = #False
                SetGadgetState(0, GetGadgetState(0)+ListSize(FirmwareFiles())-ListIndex(FirmwareFiles()))
                AddToLogFile(__("ERROR!"), #False, #True, system_debug)
                Break 1
              Else
                SetGadgetState(0, GetGadgetState(0)+1)
                AddToLogFile(__("DONE!"), #False, #True, system_debug)
              EndIf
            Wend
            If DownloadOfSuccessful ; Если прошивка скачалась успешно
              AddToLogFile(FormatStr(__("Copy directory "+Chr(34)+"%1"+Chr(34)+" to "+Chr(34)+"%2"+Chr(34)+"..."), "updates/cache_updates/"+version$, "updates/cache_updates/DEUS_V5.0/"+version$)+" ", #True, #False, system_debug)
              If CopyDirectory("updates/cache_updates/"+version$, "updates/cache_updates/DEUS_V5.0/"+version$, "", #PB_FileSystem_Recursive | #PB_FileSystem_Force)
                AddToLogFile(__("DONE!"), #False, #True, system_debug)
              Else
                AddToLogFile(__("ERROR!"), #False, #True, system_debug)
              EndIf
            EndIf
            AddToLogFile(FormatStr(__("Delete directory "+Chr(34)+"%1"+version$+Chr(34)+"..."), "updates/cache_updates/")+" ", #True, #False, system_debug)
            If DeleteDirectory("updates/cache_updates/"+version$, "", #PB_FileSystem_Recursive | #PB_FileSystem_Force)
              AddToLogFile(__("DONE!"), #False, #True, system_debug)
            Else
              AddToLogFile(__("ERROR!"), #False, #True, system_debug)
            EndIf
          Else
            SetGadgetState(0, GetGadgetState(0)+ListSize(FirmwareFiles()))
          EndIf
        EndIf
      Wend
      CloseFile(0)
    Else
      SetGadgetState(0, 1)
      AddToLogFile(FormatStr(__("Can`t open file "+Chr(34)+"%1"+Chr(34)+"!"), "updates/cache_updates/Versions_"+VersionsFileName$+".txt"), #True, #True, system_debug)
    EndIf
    AddToLogFile(FormatStr(__("Delete file "+Chr(34)+"%1"+Chr(34)+"..."), "updates/cache_updates/Versions_"+VersionsFileName$+".txt")+" ", #True, #False, system_debug)
    If DeleteFile("updates/cache_updates/Versions_"+VersionsFileName$+".txt", #PB_FileSystem_Force)
      AddToLogFile(__("DONE!"), #False, #True, system_debug)
    Else
      AddToLogFile(__("ERROR!"), #False, #True, system_debug)
    EndIf
  Else
    AddToLogFile(__("ERROR!"), #False, #True, system_debug)
  EndIf
  UpdateSuccess = #True
  AddToLogFile(__("Update finished."), #True, #True, system_debug)
EndProcedure

; Если интернет доступен
If cache_updates>0
  If CheckInternetConnection()
    Exit.b = #False
    OpenWindow(0, #PB_Any, #PB_Any, 300, 35, __("Updating"), #PB_Window_ScreenCentered)
    ProgressBarGadget(0, 5, 5, 290, 25, 0, 1) : HideGadget(0, #True)
    TextGadget(1, 5, 10, 290, 25, __("Please, wait..."), #PB_Text_Center) : HideGadget(1, #False)
    AddToLogFile(__("Check for new updates..."), #True, #True, system_debug)
    CreateThread(@CheckForNewUpdates(), cache_hidden)
    Repeat
      WaitWindowEvent(100)
    Until UpdateSuccess
    CloseWindow(0)
  Else
    AddToLogFile(__("Updating the cache is impossible: no network connection."), #True, #True, system_debug)
  EndIf
Else
  AddToLogFile(__("Updating the cache is disabled in settings."), #True, #True, system_debug)
EndIf

; Обновление versions.txt
AddToLogFile(FormatStr(__("Updating file "+Chr(34)+"%1"+Chr(34)+"..."), "updates/cache_updates/DEUS_V5.0/Versions_"+VersionsFileName$+".txt"), #True, #True, system_debug)
If OpenFile(1, "updates/cache_updates/DEUS_V5.0/Versions_"+VersionsFileName$+".txt") Or CreateFile(1, "updates/cache_updates/DEUS_V5.0/Versions_"+VersionsFileName$+".txt")
  TruncateFile(1)
  If ExamineDirectory(0, "updates/cache_updates/DEUS_V5.0/", "")
    While NextDirectoryEntry(0)
      If DirectoryEntryType(0) = #PB_DirectoryEntry_Directory
        DirectoryName$ = DirectoryEntryName(0)
        If DirectoryName$<>"." And DirectoryName$<>".."
          WriteStringN(1, DirectoryName$)
          AddToLogFile(LSet(#Null$, 3, Chr(9))+FormatStr(__("Add version string "+Chr(34)+"%1"+Chr(34)+";"), DirectoryName$), #False, #True, system_debug)
        EndIf
      EndIf
    Wend
    FinishDirectory(0)
  Else
    AddToLogFile(FormatStr(__("Can`t examine directory "+Chr(34)+"%1"+Chr(34)+"!"), "updates/cache_updates/DEUS_V5.0/"), #True, #True, system_debug)
  EndIf
  CloseFile(1)
Else
  AddToLogFile(FormatStr(__("Can`t open file "+Chr(34)+"%1"+Chr(34)+"!"), "updates/cache_updates/DEUS_V5.0/Versions_"+VersionsFileName$+".txt"), #True, #True, system_debug)
EndIf

; Процедура обработки запроса для HTTP сервера
Procedure RequestProcess(ClientID.l)
  *Memory = AllocateMemory(1024)
  MemorySize.l = ReceiveNetworkData(ClientID, *Memory, MemorySize(*Memory))
  ClientRequest$ = PeekS(*Memory, MemorySize, #PB_UTF8)
  If Len(Trim(ClientRequest$))=0 : ProcedureReturn #False : EndIf
  FreeMemory(*Memory) : RequestFile$ = Chr(32)
  For i=1 To CountString(ClientRequest$, #LF$)
    RequestLine$ = Trim(StringField(ClientRequest$, i, #LF$))
    If Left(RequestLine$, 3) = "GET"
      RequestFile$ = Trim(StringField(RequestLine$, 2, " "))
      AddToLogFile(FormatStr(__("HTTP/GET file "+Chr(34)+"%1"+Chr(34)+"..."), RequestFile$)+" ", #True, #False, system_debug)
    EndIf
  Next i
  ; Читаем запрошенный файл с диска
  If Len(Trim(RequestFile$))>0
    RequestFile$ = Mid(RequestFile$, 2)
    File.l = ReadFile(#PB_Any, RequestFile$)
    If File
      FileSize.l = Lof(File)
      *Memory = AllocateMemory(FileSize)
      ReadData(File, *Memory, FileSize)
      CloseFile(File)
      SendNetworkString(ClientID, "HTTP/1.1 200 OK"+#CR$+#LF$)
      SendNetworkString(ClientID, "Content-Length: "+Str(FileSize)+#CR$+#LF$)
      SendNetworkString(ClientID, "Content-Type: application/octet-stream"+#CR$+#LF$)
      SendNetworkString(ClientID, "Connection: close"+#CR$+#LF$)
      SendNetworkString(ClientID, #CR$+#LF$)
      SendNetworkData(ClientID, *Memory, FileSize)
      FreeMemory(*Memory)
      AddToLogFile(FormatStr(__("OK-200 (%1 bytes)!"), Str(FileSize)), #False, #True, system_debug)
    Else ; Ошибка 404
      If Len(RequestFile$)>0
        AddToLogFile(__("ERROR-404!"), #False, #True, system_debug)
        Answer$ = #Null$
        Answer$ + "<!DOCTYPE HTML PUBLIC "+Chr(34)+"-//IETF//DTD HTML 2.0//EN"+Chr(34)+">"+#CR$+#LF$
        Answer$ + "<html><head>"+#CR$+#LF$
        Answer$ + "<title>"+__("404 Not Found")+"</title>"+#CR$+#LF$
        Answer$ + "</head><body>"+#CR$+#LF$
        Answer$ + "<h1>"+__("Not Found")+"</h1>"+#CR$+#LF$
        Answer$ + "<p>"+FormatStr(__("The requested URL %1 was not found on this server."), "/"+RequestFile$)+"</p>"+#CR$+#LF$
        Answer$ + "<p>"+FormatStr(__("Additionally, a %1 error was encountered while trying to use an ErrorDocument to handle the request."), __("404 Not Found"))+"</p>"+#CR$+#LF$
        Answer$ + "</body></html>"+#CR$+#LF$
        SendNetworkString(ClientID, "HTTP/1.1 404 Not Found"+#CR$+#LF$)
        SendNetworkString(ClientID, "Content-Length: "+Len(Answer$)+#CR$+#LF$)
        SendNetworkString(ClientID, "Content-Type: text/html"+#CR$+#LF$)
        SendNetworkString(ClientID, "Connection: close"+#CR$+#LF$)
        SendNetworkString(ClientID, #CR$+#LF$)
        SendNetworkString(ClientID, Answer$)
      Else
        AddToLogFile(FormatStr(__("ERROR-404 (header location %1)!"), "http://deus.lipkop.club/wiki/Альтернативный_сервер_обновлений"), #False, #True, system_debug)
        SendNetworkString(ClientID, "HTTP/1.1 302 Moved Temporarily"+#CR$+#LF$)
        SendNetworkString(ClientID, "Location: http://deus.lipkop.club/wiki/Альтернативный_сервер_обновлений"+#CR$+#LF$)
        SendNetworkString(ClientID, "Content-Length: 0"+#CR$+#LF$)
        SendNetworkString(ClientID, "Content-Type: text/html"+#CR$+#LF$)
        SendNetworkString(ClientID, "Connection: close"+#CR$+#LF$)
        SendNetworkString(ClientID, #CR$+#LF$)
        SendNetworkString(ClientID, Answer$)
      EndIf
    EndIf
  Else ; Ошибка 400
    If RequestFile$=Chr(32)
      AddToLogFile(__("HTTP/UNKNOWN request...")+" ", #True, #False, system_debug)
    EndIf
    AddToLogFile(__("ERROR-400!"), #False, #True, system_debug)
    Answer$ = #Null$
    Answer$ + "<!DOCTYPE HTML PUBLIC "+Chr(34)+"-//IETF//DTD HTML 2.0//EN"+Chr(34)+">"+#CR$+#LF$
    Answer$ + "<html><head>"+#CR$+#LF$
    Answer$ + "<title>"+__("400 Bad Request")+"</title>"+#CR$+#LF$
    Answer$ + "</head><body>"+#CR$+#LF$
    Answer$ + "<h1>"+__("Bad Request")+"</h1>"+#CR$+#LF$
    Answer$ + "<p>"+__("Your browser sent a request that this server could not understand.")+"</p>"+#CR$+#LF$
    Answer$ + "<p>"+FormatStr(__("Additionally, a %1 error was encountered while trying to use an ErrorDocument to handle the request."), __("400 Bad Request"))+"</p>"+#CR$+#LF$
    Answer$ + "</body></html>"+#CR$+#LF$
    SendNetworkString(ClientID, "HTTP/1.1 400 Bad Request"+#CR$+#LF$)
    SendNetworkString(ClientID, "Content-Length: "+Len(Answer$)+#CR$+#LF$)
    SendNetworkString(ClientID, "Content-Type: text/html"+#CR$+#LF$)
    SendNetworkString(ClientID, "Connection: close"+#CR$+#LF$)
    SendNetworkString(ClientID, #CR$+#LF$)
    SendNetworkString(ClientID, Answer$)
  EndIf
EndProcedure

; Запускаем HTTP сервер
If CreateNetworkServer(0, 8080, #PB_Network_TCP)
  ; Запускаем DEUS UPDATE
  DeusUpdate.l = RunProgram("DEUS_UPDATE.exe", "", "", #PB_Program_Open)
  If DeusUpdate
    Repeat
      Select NetworkServerEvent()
        Case #PB_NetworkEvent_Data
          ClientID.l = EventClient()
          CreateThread(@RequestProcess(), ClientID)
      EndSelect
    Until Not ProgramRunning(DeusUpdate)
  Else
    AddToLogFile(FormatStr(__("Can`t execute the %1 file!"), "DEUS_UPDATE.exe"), #True, #True, system_debug)
    MessageRequester(__("Error"), FormatStr(__("Can`t execute the %1 file!"), "DEUS_UPDATE.exe"), #MB_ICONERROR)
  EndIf
Else
  AddToLogFile(FormatStr(__("Can`t create the http server on port %1!"), "8080"), #True, #True, system_debug)
  MessageRequester(__("Error"), FormatStr(__("Can`t create the http server on port %1!"), "8080"), #MB_ICONERROR)
EndIf

ProgramEndPoint:
AddToLogFile(__("ALL DONE."), #True, #True, system_debug)
AddToLogFile(LSet(#Null$, 64, Chr(45)), #False, #True, system_debug)
AddToLogFile(#Null$, #False, #True, system_debug)

End

; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 534
; FirstLine = 495
; Folding = -
; EnableThread
; EnableXP
; EnableAdmin
; UseIcon = dou.ico
; Executable = dou.exe
; EnableCompileCount = 33
; EnableBuildCount = 18
; IncludeVersionInfo
; VersionField0 = 1.0.%BUILDCOUNT.%COMPILECOUNT
; VersionField1 = 1.0.%BUILDCOUNT.%COMPILECOUNT
; VersionField2 = LipKop.club
; VersionField3 = Updater
; VersionField4 = 1.0.%BUILDCOUNT.%COMPILECOUNT
; VersionField5 = 1.0.%BUILDCOUNT.%COMPILECOUNT
; VersionField6 = Unofficial XP Deus updater
; VersionField7 = deus_offline_updater
; VersionField8 = %EXECUTABLE
; VersionField9 = SoulTaker
; VersionField13 = thesoultaker48@gmail.com
; VersionField14 = http://deus.lipkop.club
; VersionField15 = VOS_NT_WINDOWS32
; VersionField16 = VFT_APP
; EnableUnicode