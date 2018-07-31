; Зависимости
XIncludeFile #PB_Compiler_Home+"hmod\DroopyLib.pbi"
UseModule DroopyLib

; Инициализация перевода
XIncludeFile #PB_Compiler_FilePath+"includes\i18n\i18n.pbi"
Translator_init("languages/", #Null$)

; Инициализация подсистем
InitNetwork()
UseMD5Fingerprint()

; Функция подсчета количества строк в файле
Procedure.l CountFileStrings(FileName.s, CountEmpty.b=#True)
  File.l = ReadFile(#PB_Any, FileName)
  If File
    Count.l = 0
    While Eof(File) = 0
      str$ = ReadString(File)
      str$ = Trim(str$)
      If Len(str$) > 0 Or CountEmpty = #True
        Count = Count + 1
      EndIf
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

; Получаем версию программы
Global ProgramFilename$ = ProgramFilename()
Global CurrentUpdaterVersion$ = GetFileVersion(ProgramFilename$, #GFVI_FileVersion, #False)

; Читаем настройки из файла
Global system_updates.l = 1 ; Проверять обновления программы
Global system_debug.l   = 0 ; Режим отладки
Global cache_updates.l  = 1 ; Обновлять кеш с сервера
Global cache_beta.l     = 0 ; Загружать бета версии прошивок
Global cache_delete.l   = 0 ; Разрешить удаление файлов
If OpenPreferences("config.cfg", #PB_Preference_GroupSeparator)
  PreferenceGroup("system")
  system_updates = ReadPreferenceLong("updates", system_updates)
  system_debug   = ReadPreferenceLong("debug",   system_debug)
  PreferenceGroup("cache")
  cache_updates = ReadPreferenceLong("updates",  cache_updates)
  cache_beta    = ReadPreferenceLong("hidden",   cache_beta)
  cache_delete  = ReadPreferenceLong("delete",   cache_delete)
  ClosePreferences()
  AddToLogFile(FormatStr(__("Deus Offline Updater started (version %1)."), CurrentUpdaterVersion$), #True, #True, system_debug)
Else
  AddToLogFile(FormatStr(__("Deus Offline Updater started (version %1)."), CurrentUpdaterVersion$), #True, #True, system_debug)
  AddToLogFile(__("Can`t open config file! Will be used default settings."), #True, #True, system_debug)
  MessageRequester(__("Warning!"), __("This software IS NOT OFFICIAL updater and is intended for use solely for informational purposes.\n\nThe author is not responsible for any damage (material, moral or other) caused to you or third parties resulting from the use of this software.\n\nAll the steps you are at your own risk!\n"), #MB_ICONWARNING)
EndIf
AddToLogFile(__("Current settings:"), #True, #True, system_debug)
AddToLogFile(LSet(#Null$, 3, Chr(9))+FormatStr(__("Software updates = %1;"), Str(system_updates)), #False, #True, system_debug)
AddToLogFile(LSet(#Null$, 3, Chr(9))+FormatStr(__("Debug mode       = %1;"), Str(system_debug)),   #False, #True, system_debug)
AddToLogFile(LSet(#Null$, 3, Chr(9))+FormatStr(__("Firmware updates = %1;"), Str(cache_updates)),  #False, #True, system_debug)
AddToLogFile(LSet(#Null$, 3, Chr(9))+FormatStr(__("Beta firmwares   = %1;"), Str(cache_beta)),     #False, #True, system_debug)
AddToLogFile(LSet(#Null$, 3, Chr(9))+FormatStr(__("File deletion    = %1;"), Str(cache_delete)),   #False, #True, system_debug)

; Создаем дирректории
If FileSize("updates")=-1
  AddToLogFile(FormatStr(__("The directory &#34;%1&#34; does not exist! Create it..."), "updates/"), #True, #False, system_debug)
  If CreateDirectory("updates/")
    AddToLogFile(__("DONE!"), #False, #True, system_debug)
  Else
    AddToLogFile(__("ERROR!"), #False, #True, system_debug)
  EndIf
EndIf
If FileSize("updates/cache_updates")=-1
  AddToLogFile(FormatStr(__("The directory &#34;%1&#34; does not exist! Create it..."), "updates/cache_updates/"), #True, #False, system_debug)
  If CreateDirectory("updates/cache_updates/")
    AddToLogFile(__("DONE!"), #False, #True, system_debug)
  Else
    AddToLogFile(__("ERROR!"), #False, #True, system_debug)
  EndIf
EndIf

; Update: 3.2 -> 4.0 (с версии 1.0.5.9)
If CompareProgramsVersions(CurrentUpdaterVersion$, "1.1.14.16") ; DEUS_UPDATE.exe <= 4.1
  If FileSize("updates/cache_updates/DEUS_V4")=-1
    If FileSize("updates/cache_updates/versions.txt") >= 0
      AddToLogFile(FormatStr(__("Clear directory &#34;%1&#34;..."), "updates/cache_updates/"), #True, #False, system_debug)
      If DeleteDirectory("updates/cache_updates/", "", #PB_FileSystem_Recursive | #PB_FileSystem_Force) And CreateDirectory("updates/cache_updates/")
        AddToLogFile(__("DONE!"), #False, #True, system_debug)
      Else
        AddToLogFile(__("ERROR!"), #False, #True, system_debug)
      EndIf
    EndIf
    AddToLogFile(FormatStr(__("The directory &#34;%1&#34; does not exist! Create it..."), "updates/cache_updates/DEUS_V4/"), #True, #False, system_debug)
    If CreateDirectory("updates/cache_updates/DEUS_V4/")
      AddToLogFile(__("DONE!"), #False, #True, system_debug)
    Else
      AddToLogFile(__("ERROR!"), #False, #True, system_debug)
    EndIf
  Else
    If FileSize("updates/cache_updates/versions.txt") >= 0
      AddToLogFile(FormatStr(__("Clear directory &#34;%1&#34;..."), "updates/cache_updates/"), #True, #False, system_debug)
      VersionsFile.l = ReadFile(#PB_Any, "updates/cache_updates/versions.txt")
      If VersionsFile
        AddToLogFile("", #False, #True, system_debug)
        While Eof(VersionsFile) = 0
          file$ = ReadString(VersionsFile)
          file$ = Trim(file$)
          If Len(file$) > 0
            AddToLogFile(FormatStr(__("Delete directory &#34;%1&#34;..."), "updates/cache_updates/"+file$+"/"), #True, #False, system_debug)
            If DeleteDirectory("updates/cache_updates/"+file$+"/", "", #PB_FileSystem_Recursive | #PB_FileSystem_Force)
              AddToLogFile(__("DONE!"), #False, #True, system_debug)
            Else
              AddToLogFile(__("ERROR!"), #False, #True, system_debug)
            EndIf
          EndIf
        Wend
        CloseFile(VersionsFile)
        AddToLogFile(FormatStr(__("Delete file &#34;%1&#34;..."), "updates/cache_updates/versions.txt"), #True, #False, system_debug)
        If DeleteFile("updates/cache_updates/versions.txt", #PB_FileSystem_Force)
          AddToLogFile(__("DONE!"), #False, #True, system_debug)
        Else
          AddToLogFile(__("ERROR!"), #False, #True, system_debug)
        EndIf
      Else
        AddToLogFile(__("ERROR!"), #False, #True, system_debug)
      EndIf
    EndIf
  EndIf
EndIf

; Update: 4.0 -> 4.1 (с версии 1.1.14.16)
If CompareProgramsVersions(CurrentUpdaterVersion$, "1.1.16.31") ; DEUS_UPDATE.exe <= 4.1
  If FileSize("updates/cache_updates/DEUS_V4.1")=-1
    If FileSize("updates/cache_updates/DEUS_V4")=-2
      AddToLogFile(FormatStr(__("Rename the directory with cache &#34;%1&#34; to &#34;%2&#34;..."), "DEUS_V4/", "DEUS_V4.1/"), #True, #False, system_debug)
      If RenameFile("updates/cache_updates/DEUS_V4/", "updates/cache_updates/DEUS_V4.1/")
        AddToLogFile(__("DONE!"), #False, #True, system_debug)
        If FileSize("updates/cache_updates/DEUS_V4.1/Versions_4_0_01.txt") >= 0
          AddToLogFile(FormatStr(__("Delete file &#34;%1&#34;..."), "updates/cache_updates/DEUS_V4.1/Versions_4_0_01.txt"), #True, #False, system_debug)
          If DeleteFile("updates/cache_updates/DEUS_V4.1/Versions_4_0_01.txt", #PB_FileSystem_Force)
            AddToLogFile(__("DONE!"), #False, #True, system_debug)
          Else
            AddToLogFile(__("ERROR!"), #False, #True, system_debug)
          EndIf
        EndIf
      Else
        AddToLogFile(__("ERROR!"), #False, #True, system_debug)
      EndIf
    Else
      AddToLogFile(FormatStr(__("The directory &#34;%1&#34; does not exist! Create it..."), "updates/cache_updates/DEUS_V4.1/"), #True, #False, system_debug)
      If CreateDirectory("updates/cache_updates/DEUS_V4.1/")
        AddToLogFile(__("DONE!"), #False, #True, system_debug)
      Else
        AddToLogFile(__("ERROR!"), #False, #True, system_debug)
      EndIf
    EndIf
  Else
    If FileSize("updates/cache_updates/DEUS_V4")=-2
      AddToLogFile(FormatStr(__("Delete directory &#34;%1&#34;..."), "updates/cache_updates/DEUS_V4/"), #True, #False, system_debug)
      If DeleteDirectory("updates/cache_updates/DEUS_V4/", "", #PB_FileSystem_Recursive | #PB_FileSystem_Force)
        AddToLogFile(__("DONE!"), #False, #True, system_debug)
      Else
        AddToLogFile(__("ERROR!"), #False, #True, system_debug)
      EndIf      
    EndIf
  EndIf
EndIf

; Update: 4.1 -> 5.0 (с версии 1.1.16.31)
; TODO: при переходе на новую версию DEUS_UPDATE.exe не забыть убрать Not и исправить номер версии!
If Not CompareProgramsVersions(CurrentUpdaterVersion$, "1.1.16.31") ; DEUS_UPDATE.exe <= 5.0
  If FileSize("updates/cache_updates/DEUS_V5.0")=-1
    If FileSize("updates/cache_updates/DEUS_V4.1")=-2
      AddToLogFile(FormatStr(__("Rename the directory with cache &#34;%1&#34; to &#34;%2&#34;..."), "DEUS_V4.1/", "DEUS_V5.0/"), #True, #False, system_debug)
      If RenameFile("updates/cache_updates/DEUS_V4.1/", "updates/cache_updates/DEUS_V5.0/")
        AddToLogFile(__("DONE!"), #False, #True, system_debug)
        If FileSize("updates/cache_updates/DEUS_V5.0/Versions_4_1_04.txt") >= 0
          AddToLogFile(FormatStr(__("Delete file &#34;%1&#34;..."), "updates/cache_updates/DEUS_V5.0/Versions_4_1_04.txt"), #True, #False, system_debug)
          If DeleteFile("updates/cache_updates/DEUS_V5.0/Versions_4_1_04.txt", #PB_FileSystem_Force)
            AddToLogFile(__("DONE!"), #False, #True, system_debug)
          Else
            AddToLogFile(__("ERROR!"), #False, #True, system_debug)
          EndIf
        EndIf
      Else
        AddToLogFile(__("ERROR!"), #False, #True, system_debug)
      EndIf
    Else
      AddToLogFile(FormatStr(__("The directory &#34;%1&#34; does not exist! Create it..."), "updates/cache_updates/DEUS_V5.0/"), #True, #False, system_debug)
      If CreateDirectory("updates/cache_updates/DEUS_V5.0/")
        AddToLogFile(__("DONE!"), #False, #True, system_debug)
      Else
        AddToLogFile(__("ERROR!"), #False, #True, system_debug)
      EndIf
    EndIf
  Else
    If FileSize("updates/cache_updates/DEUS_V4.1")=-2
      AddToLogFile(FormatStr(__("Delete directory &#34;%1&#34;..."), "updates/cache_updates/DEUS_V4.1/"), #True, #False, system_debug)
      If DeleteDirectory("updates/cache_updates/DEUS_V4.1/", "", #PB_FileSystem_Recursive | #PB_FileSystem_Force)
        AddToLogFile(__("DONE!"), #False, #True, system_debug)
      Else
        AddToLogFile(__("ERROR!"), #False, #True, system_debug)
      EndIf      
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
        AddToLogFile(__("The software was successfully updated!"), #True, #True, system_debug)
        MessageRequester(__("Information"), __("The software was successfully updated!"), #MB_ICONINFORMATION)
      Else
        AddToLogFile(__("The software was successfully installed!"), #True, #True, system_debug)
        MessageRequester(__("Information"), __("The software was successfully installed!"), #MB_ICONINFORMATION)
      EndIf
      Goto ProgramEndPoint
      End
    Default:
      AddToLogFile(FormatStr(__("Unsupported startup key: %1"), CurrentParemeter$), #True, #True, system_debug)
  EndSelect
Next i

; Обновление программы и прошивок
Global VersionsFileName$ = "5_0_01" ;- FIXME: определить алгоритм формирования имени файла
Global UpdateSuccess.b = #False
Procedure CheckForNewUpdates(hidden)
  ; Обновление самой программы
  If system_updates > 0
    SetWindowTitle(0, __("Software updating"))
    AddToLogFile(__("Check for software updates..."), #True, #True, system_debug)
    ; Получаем информацию о последней версии
    AddToLogFile(FormatStr(__("Download file &#34;%1&#34;..."), "http://deus.lipkop.club/dou/index.php"), #True, #False, system_debug)
    LastUpdaterVersion$ = CurrentUpdaterVersion$
    If URLDownloadToFile_(#Null, "http://deus.lipkop.club/dou/index.php", "updates/dou.txt", 0, #Null) = #S_OK
      AddToLogFile(__("DONE!"), #False, #True, system_debug)
      AddToLogFile(FormatStr(__("Read last software version from file &#34;%1&#34;..."), "updates/dou.txt"), #True, #False, system_debug)
      DouFile.l = ReadFile(#PB_Any, "updates/dou.txt")
      If DouFile
        LastUpdaterVersion$ = #Null$
        AddToLogFile(__("DONE!"), #False, #True, system_debug)
        While Eof(DouFile) = 0
          LastUpdaterVersion$ + ReadString(DouFile)
        Wend
        LastUpdaterVersion$ = Trim(LastUpdaterVersion$)
        CloseFile(DouFile)
      Else
        AddToLogFile(__("ERROR!"), #False, #True, system_debug)
      EndIf
    Else
      AddToLogFile(__("ERROR!"), #False, #True, system_debug)
    EndIf
    ; Если есть новая версия программы
    If CompareProgramsVersions(CurrentUpdaterVersion$, LastUpdaterVersion$)
      AddToLogFile(FormatStr(__("A new version %1 of the software is available."), LastUpdaterVersion$), #True, #True, system_debug)
      ; Спрашиваем пользователя, нужно ли обновляться
      If MessageRequester(__("Question"), FormatStr(__("New version %1 is available! Install the update?\n\nInformation: it is recommended to always install the latest versions of the software, as they may contain important updates, fixes for the correct installation of firmware or new functionality."), LastUpdaterVersion$), #MB_ICONQUESTION | #PB_MessageRequester_YesNo) = #PB_MessageRequester_Yes
        AddToLogFile(FormatStr(__("Download file &#34;%1&#34;..."), "http://deus.lipkop.club/dou/deus_offline_updater.exe"), #True, #False, system_debug)
        If URLDownloadToFile_(#Null, "http://deus.lipkop.club/dou/deus_offline_updater.exe", "updates/deus_offline_updater.exe", 0, #Null) = #S_OK
          AddToLogFile(__("DONE!"), #False, #True, system_debug)
          ; Запускаем установщик обновлений
          AddToLogFile(FormatStr(__("Execute file &#34;%1&#34;..."), "updates/deus_offline_updater.exe"), #True, #False, system_debug)
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
      Else
        AddToLogFile(__("The software update has been canceled by user."), #True, #True, system_debug)
      EndIf
    Else ; Если новой версии нет, то проверим, возможно мы только что обновились и надо подчистить за собой
      AddToLogFile(__("There are no updates available."), #True, #True, system_debug)
      If FileSize("updates/deus_offline_updater.exe")<>-1
        AddToLogFile(FormatStr(__("Delete file &#34;%1&#34;..."), "updates/deus_offline_updater.exe"), #True, #False, system_debug)
        If DeleteFile("updates/deus_offline_updater.exe", #PB_FileSystem_Force)
          AddToLogFile(__("DONE!"), #False, #True, system_debug)
        Else
          AddToLogFile(__("ERROR!"), #False, #True, system_debug)
        EndIf
        AddToLogFile(__("Software update finished."), #True, #True, system_debug)
      EndIf
    EndIf
    If FileSize("updates/dou.txt") >= 0
      AddToLogFile(FormatStr(__("Delete file &#34;%1&#34;..."), "updates/dou.txt"), #True, #False, system_debug)
      If DeleteFile("updates/dou.txt", #PB_FileSystem_Force)
        AddToLogFile(__("DONE!"), #False, #True, system_debug)
      Else
        AddToLogFile(__("ERROR!"), #False, #True, system_debug)
      EndIf
    EndIf
  Else
    AddToLogFile(__("The software update is disabled in the settings."), #True, #True, system_debug)
  EndIf
  ; Обновление прошивок в локальном каталоге
  If cache_updates > 0
    SetWindowTitle(0, __("Firmware updating..."))
    AddToLogFile(__("Checking the firmware update..."), #True, #True, system_debug)
    If hidden>0
      versions_url$ = "http://deus.lipkop.club/dou/updates/versions.php?show=all"
    Else
      versions_url$ = "http://deus.lipkop.club/dou/updates/versions.php"
    EndIf
    AddToLogFile(FormatStr(__("Download file &#34;%1&#34;..."), versions_url$), #True, #False, system_debug)
    If URLDownloadToFile_(#Null, versions_url$, "updates/cache_updates/Versions_"+VersionsFileName$+".txt", 0, #Null) = #S_OK
      AddToLogFile(__("DONE!"), #False, #True, system_debug)
      CountVersions.l = CountFileStrings("updates/cache_updates/Versions_"+VersionsFileName$+".txt", #False)
      If CountVersions>0
        VersionsFile.l = ReadFile(#PB_Any, "updates/cache_updates/Versions_"+VersionsFileName$+".txt")
        If VersionsFile
          ; Перебираем все прошивки, доступные на сервере
          CounterVersions.l = 0
          While Eof(VersionsFile) = 0
            version$ = Trim(ReadString(VersionsFile))
            If Len(version$)>0
              ; Меняем заголовок окна
              CounterVersions = CounterVersions + 1
              SetWindowTitle(0, FormatStr(__("Firmware updating (%1 of %2)..."), Str(CounterVersions), Str(CountVersions)))
              ; Обнуляем прогресс бар
              SetGadgetState(0, 0)
              ; Создаем временный каталог
              AddToLogFile(FormatStr(__("Create directory &#34;%1&#34;..."), "updates/cache_updates/"+version$+".tmp/"), #True, #False, system_debug)
              If CreateDirectory("updates/cache_updates/"+version$+".tmp/")
                AddToLogFile(__("DONE!"), #False, #True, system_debug)
              Else
                AddToLogFile(__("ERROR!"), #False, #True, system_debug)
              EndIf
              ; Получаем md5sums.txt с сервера
              AddToLogFile(FormatStr(__("Download file &#34;%1&#34;..."), "http://deus.lipkop.club/dou/updates/"+version$+"/md5sums.txt"), #True, #False, system_debug)
              If URLDownloadToFile_(#Null, "http://deus.lipkop.club/dou/updates/"+version$+"/md5sums.txt", "updates/cache_updates/"+version$+".tmp/md5sums.txt", 0, #Null) = #S_OK
                AddToLogFile(__("DONE!"), #False, #True, system_debug)
                CountSums.l = CountFileStrings("updates/cache_updates/"+version$+".tmp/md5sums.txt", #False)
                If CountSums > 0
                  MD5SumsFile.l = ReadFile(#PB_Any, "updates/cache_updates/"+version$+".tmp/md5sums.txt")
                  If MD5SumsFile
                    ; Устанавливаем максимальное значение для прогресс бара
                    SetGadgetAttribute(0, #PB_ProgressBar_Maximum, CountSums)
                    ; Перебираем все файлы данной прошивки
                    CounterSums.l = 0
                    While Eof(MD5SumsFile) = 0
                      file_line$ = Trim(ReadString(MD5SumsFile))
                      If Len(file_line$) > 0
                        ; Разбиваем строку на хеш и имя файла
                        file_md5$  = Trim(StringField(file_line$, 1, Chr(9)))
                        file_name$ = GetFilePart(Trim(StringField(file_line$, 2, Chr(9))))
                        If (Len(file_md5$) > 0) And (Len(file_name$) > 0)
                          ; Если такого файла нет в кеше прошивок, либо на сервере есть более свежая версия
                          If (FileSize("updates/cache_updates/DEUS_V5.0/"+version$+"/"+file_name$) = -1) Or (FileFingerprint("updates/cache_updates/DEUS_V5.0/"+version$+"/"+file_name$, #PB_Cipher_MD5) <> file_md5$)
                            ; Скачиваем его
                            AddToLogFile(FormatStr(__("Download file &#34;%1&#34;..."), "http://deus.lipkop.club/dou/updates/"+version$+"/"+file_name$), #True, #False, system_debug)
                            If URLDownloadToFile_(#Null, "http://deus.lipkop.club/dou/updates/"+version$+"/"+file_name$, "updates/cache_updates/"+version$+".tmp/"+file_name$, 0, #Null) = #S_OK
                              AddToLogFile(__("DONE!"), #False, #True, system_debug)
                              ; Если каталог с кешем прошивки отсутствует, то создаем его
                              If FileSize("updates/cache_updates/DEUS_V5.0/"+version$) = -1
                                AddToLogFile(FormatStr(__("Create directory &#34;%1&#34;..."), "updates/cache_updates/DEUS_V5.0/"+version$+"/"), #True, #False, system_debug)
                                If CreateDirectory("updates/cache_updates/DEUS_V5.0/"+version$+"/")
                                  AddToLogFile(__("DONE!"), #False, #True, system_debug)
                                Else
                                  AddToLogFile(__("ERROR!"), #False, #True, system_debug)
                                EndIf
                              EndIf
                              ; Копируем файл в основной каталог кеша прошивки
                              AddToLogFile(FormatStr(__("Copy file &#34;%1&#34; to &#34;%2&#34;..."), "updates/cache_updates/"+version$+".tmp/"+file_name$, "updates/cache_updates/DEUS_V5.0/"+version$+"/"+file_name$), #True, #False, system_debug)
                              If CopyFile("updates/cache_updates/"+version$+".tmp/"+file_name$, "updates/cache_updates/DEUS_V5.0/"+version$+"/"+file_name$)
                                AddToLogFile(__("DONE!"), #False, #True, system_debug)
                              Else
                                AddToLogFile(__("ERROR!"), #False, #True, system_debug)
                              EndIf
                            Else
                              AddToLogFile(__("ERROR!"), #False, #True, system_debug)
                            EndIf
                          EndIf
                        EndIf
                        ; Увеличиваем прогресс бар
                        CounterSums = CounterSums + 1
                        SetGadgetState(0, CounterSums)
                      EndIf
                    Wend
                    ; Удаляем лишние файлы из каталога с прошивкой
                    If cache_delete > 0
                      FirmwareDirectory.l = ExamineDirectory(#PB_Any, "updates/cache_updates/DEUS_V5.0/"+version$+"/", "")
                      If FirmwareDirectory
                        While NextDirectoryEntry(FirmwareDirectory)
                          DirectoryEntryName$ = DirectoryEntryName(FirmwareDirectory)
                          If DirectoryEntryName$ <> "." And DirectoryEntryName$ <> ".."
                            DeleteFile.b = #True
                            FileSeek(MD5SumsFile, 0)
                            While Eof(MD5SumsFile) = 0
                              file_line$ = Trim(ReadString(MD5SumsFile))
                              If Len(file_line$) > 0
                                file_name$ = GetFilePart(Trim(StringField(file_line$, 2, Chr(9))))
                                If Len(file_name$) > 0
                                  If file_name$ = DirectoryEntryName$
                                    DeleteFile = #False
                                    Break
                                  EndIf
                                EndIf
                              EndIf
                            Wend
                            If DeleteFile
                              If DirectoryEntryType(FirmwareDirectory) = #PB_DirectoryEntry_File
                                AddToLogFile(FormatStr(__("Delete file &#34;%1&#34;..."), "updates/cache_updates/DEUS_V5.0/"+version$+"/"+DirectoryEntryName$), #True, #False, system_debug)
                                If DeleteFile("updates/cache_updates/DEUS_V5.0/"+version$+"/"+DirectoryEntryName$, #PB_FileSystem_Force)
                                  AddToLogFile(__("DONE!"), #False, #True, system_debug)
                                Else
                                  AddToLogFile(__("ERROR!"), #False, #True, system_debug)
                                EndIf
                              Else
                                AddToLogFile(FormatStr(__("Delete directory &#34;%1&#34;..."), "updates/cache_updates/DEUS_V5.0/"+version$+"/"+DirectoryEntryName$), #True, #False, system_debug)
                                If DeleteDirectory("updates/cache_updates/DEUS_V5.0/"+version$+"/"+DirectoryEntryName$, "", #PB_FileSystem_Recursive | #PB_FileSystem_Force)
                                  AddToLogFile(__("DONE!"), #False, #True, system_debug)
                                Else
                                  AddToLogFile(__("ERROR!"), #False, #True, system_debug)
                                EndIf
                              EndIf
                            EndIf
                          EndIf
                        Wend
                        FinishDirectory(FirmwareDirectory)
                      EndIf
                    EndIf
                    ; Закрываем файл md5sums.txt
                    CloseFile(MD5SumsFile)
                  Else
                    AddToLogFile(FormatStr(__("Can`t open file &#34;%1&#34;!"), "updates/cache_updates/"+version$+".tmp/md5sums.txt"), #True, #True, system_debug)
                  EndIf
                Else
                  AddToLogFile(FormatStr(__("The &#34;%1&#34; file may be corrupted!"), "updates/cache_updates/"+version$+".tmp/md5sums.txt"), #True, #True, system_debug)
                EndIf
              Else
                AddToLogFile(__("ERROR!"), #False, #True, system_debug)
              EndIf
              ; Удаляем временный каталог
              AddToLogFile(FormatStr(__("Delete directory &#34;%1&#34;..."), "updates/cache_updates/"+version$+".tmp/"), #True, #False, system_debug)
              If DeleteDirectory("updates/cache_updates/"+version$+".tmp/", "", #PB_FileSystem_Recursive | #PB_FileSystem_Force)
                AddToLogFile(__("DONE!"), #False, #True, system_debug)
              Else
                AddToLogFile(__("ERROR!"), #False, #True, system_debug)
              EndIf
            EndIf
          Wend
          ; Удаляем лишние файлы из каталога с кешем
          If cache_delete > 0
            VersionsDirectory.l = ExamineDirectory(#PB_Any, "updates/cache_updates/DEUS_V5.0/", "")
            If VersionsDirectory
              While NextDirectoryEntry(VersionsDirectory)
                DirectoryEntryName$ = DirectoryEntryName(VersionsDirectory)
                If DirectoryEntryName$ <> "." And DirectoryEntryName$ <> ".."
                  DeleteFile.b = #True
                  FileSeek(VersionsFile, 0)
                  While Eof(VersionsFile) = 0
                    file_line$ = Trim(ReadString(VersionsFile))
                    If Len(file_line$) > 0
                        If file_line$ = DirectoryEntryName$
                          DeleteFile = #False
                          Break
                        EndIf
                    EndIf
                  Wend
                  If DeleteFile
                    If DirectoryEntryType(VersionsDirectory) = #PB_DirectoryEntry_File
                      AddToLogFile(FormatStr(__("Delete file &#34;%1&#34;..."), "updates/cache_updates/DEUS_V5.0/"+DirectoryEntryName$), #True, #False, system_debug)
                      If DeleteFile("updates/cache_updates/DEUS_V5.0/"+DirectoryEntryName$, #PB_FileSystem_Force)
                        AddToLogFile(__("DONE!"), #False, #True, system_debug)
                      Else
                        AddToLogFile(__("ERROR!"), #False, #True, system_debug)
                      EndIf
                    Else
                      AddToLogFile(FormatStr(__("Delete directory &#34;%1&#34;..."), "updates/cache_updates/DEUS_V5.0/"+DirectoryEntryName$), #True, #False, system_debug)
                      If DeleteDirectory("updates/cache_updates/DEUS_V5.0/"+DirectoryEntryName$, "", #PB_FileSystem_Recursive | #PB_FileSystem_Force)
                        AddToLogFile(__("DONE!"), #False, #True, system_debug)
                      Else
                        AddToLogFile(__("ERROR!"), #False, #True, system_debug)
                      EndIf
                    EndIf
                  EndIf
                EndIf
              Wend
              FinishDirectory(VersionsDirectory)
            EndIf
          EndIf  
          ; Закрываем файл со списком версий
          CloseFile(VersionsFile)
        Else
          SetGadgetState(0, 1)
          AddToLogFile(FormatStr(__("Can`t open file &#34;%1&#34;!"), "updates/cache_updates/Versions_"+VersionsFileName$+".txt"), #True, #True, system_debug)
        EndIf
      Else
        SetGadgetState(0, 1)
        AddToLogFile(FormatStr(__("The &#34;%1&#34; file may be corrupted!"), "updates/cache_updates/Versions_"+VersionsFileName$+".txt"), #True, #True, system_debug)
      EndIf
      AddToLogFile(FormatStr(__("Delete file &#34;%1&#34;..."), "updates/cache_updates/Versions_"+VersionsFileName$+".txt"), #True, #False, system_debug)
      If DeleteFile("updates/cache_updates/Versions_"+VersionsFileName$+".txt", #PB_FileSystem_Force)
        AddToLogFile(__("DONE!"), #False, #True, system_debug)
      Else
        AddToLogFile(__("ERROR!"), #False, #True, system_debug)
      EndIf
    Else
      AddToLogFile(__("ERROR!"), #False, #True, system_debug)
    EndIf
  Else
    AddToLogFile(__("The firmware update is disabled in the settings."), #True, #True, system_debug)
  EndIf
  UpdateSuccess = #True
  AddToLogFile(__("Updates finished."), #True, #True, system_debug)
EndProcedure

; Если включены обновления (программы или прошивок)
If (system_updates > 0) Or (cache_updates > 0)
  ; Если интернет доступен
  If CheckInternetConnection()
    Exit.b = #False
    OpenWindow(0, #PB_Any, #PB_Any, 300, 75, __("Updating"), #PB_Window_ScreenCentered)
    ProgressBarGadget(0, 5, 5, 290, 25, 0, 1) : SetGadgetState(0, #PB_ProgressBar_Unknown)
    ButtonGadget(1, 100, 40, 100, 25, __("Cancel"))
    AddToLogFile(__("Check for new updates..."), #True, #True, system_debug)
    Thread.l = CreateThread(@CheckForNewUpdates(), cache_beta)
    Repeat
      Select WaitWindowEvent(100)
        Case #PB_Event_Gadget:
          Select EventGadget()
            Case 1:
              If IsThread(Thread)
                ;- FIXME: безопасное завершение потока
                KillThread(Thread)
                UpdateSuccess = #True
                AddToLogFile(__("The update has been canceled by user."), #True, #True, system_debug)
              EndIf
          EndSelect
      EndSelect
    Until UpdateSuccess
    CloseWindow(0)
  Else
    AddToLogFile(__("Updating is impossible: no network connection."), #True, #True, system_debug)
  EndIf
Else
  AddToLogFile(__("Updating is disabled in settings."), #True, #True, system_debug)
EndIf

; Обновление versions.txt
AddToLogFile(FormatStr(__("Formation of the &#34;%1&#34; file..."), "updates/cache_updates/DEUS_V5.0/Versions_"+VersionsFileName$+".txt"), #True, #True, system_debug)
VersionsFile.l = OpenFile(#PB_Any, "updates/cache_updates/DEUS_V5.0/Versions_"+VersionsFileName$+".txt")
If Not VersionsFile
  VersionsFile = CreateFile(#PB_Any, "updates/cache_updates/DEUS_V5.0/Versions_"+VersionsFileName$+".txt")
EndIf
If VersionsFile
  TruncateFile(VersionsFile)
  VersionsDirectory.l = ExamineDirectory(#PB_Any, "updates/cache_updates/DEUS_V5.0/", "")
  If VersionsDirectory
    While NextDirectoryEntry(VersionsDirectory)
      If DirectoryEntryType(VersionsDirectory) = #PB_DirectoryEntry_Directory
        DirectoryName$ = DirectoryEntryName(VersionsDirectory)
        If DirectoryName$<>"." And DirectoryName$<>".."
          WriteStringN(VersionsFile, DirectoryName$)
          AddToLogFile(LSet(#Null$, 3, Chr(9))+FormatStr(__("Add version string &#34;%1&#34;;"), DirectoryName$), #False, #True, system_debug)
        EndIf
      EndIf
    Wend
    FinishDirectory(VersionsDirectory)
  Else
    AddToLogFile(FormatStr(__("Can`t examine directory &#34;%1&#34;!"), "updates/cache_updates/DEUS_V5.0/"), #True, #True, system_debug)
  EndIf
  CloseFile(VersionsFile)
Else
  AddToLogFile(FormatStr(__("Can`t open file &#34;%1&#34;!"), "updates/cache_updates/DEUS_V5.0/Versions_"+VersionsFileName$+".txt"), #True, #True, system_debug)
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
      AddToLogFile(FormatStr(__("HTTP/GET file &#34;%1&#34;..."), RequestFile$), #True, #False, system_debug)
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
        Answer$ + "<!DOCTYPE HTML PUBLIC &#34;-//IETF//DTD HTML 2.0//EN&#34;>"+#CR$+#LF$
        Answer$ + "<html><head>"+#CR$+#LF$
        Answer$ + "<title>"+__("404 Not Found")+"</title>"+#CR$+#LF$
        Answer$ + "</head><body>"+#CR$+#LF$
        Answer$ + "<h1>"+__("Not Found")+"</h1>"+#CR$+#LF$
        Answer$ + "<p>"+FormatStr(__("The requested URL %1 was not found on this server."), "/"+RequestFile$)+"</p>"+#CR$+#LF$
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
      AddToLogFile(__("HTTP/UNKNOWN request..."), #True, #False, system_debug)
    EndIf
    AddToLogFile(__("ERROR-400!"), #False, #True, system_debug)
    Answer$ = #Null$
    Answer$ + "<!DOCTYPE HTML PUBLIC &#34;-//IETF//DTD HTML 2.0//EN&#34;>"+#CR$+#LF$
    Answer$ + "<html><head>"+#CR$+#LF$
    Answer$ + "<title>"+__("400 Bad Request")+"</title>"+#CR$+#LF$
    Answer$ + "</head><body>"+#CR$+#LF$
    Answer$ + "<h1>"+__("Bad Request")+"</h1>"+#CR$+#LF$
    Answer$ + "<p>"+__("Your browser sent a request that this server could not understand.")+"</p>"+#CR$+#LF$
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
AddToLogFile(FormatStr(__("Create a network server on port %1..."), "8080"), #True, #False, system_debug)
NetworkServer.l = CreateNetworkServer(#PB_Any, 8080, #PB_Network_TCP)
If NetworkServer
  AddToLogFile(__("DONE!"), #False, #True, system_debug)
  ; Запускаем DEUS UPDATE
  AddToLogFile(FormatStr(__("Execute file %1..."), "DEUS_UPDATE.exe"), #True, #False, system_debug)
  DeusUpdate.l = RunProgram("DEUS_UPDATE.exe", "", "", #PB_Program_Open)
  If DeusUpdate
    AddToLogFile(__("DONE!"), #False, #True, system_debug)
    Repeat
      Select NetworkServerEvent(NetworkServer)
        Case #PB_NetworkEvent_Data
          ClientID.l = EventClient()
          CreateThread(@RequestProcess(), ClientID)
      EndSelect
    Until Not ProgramRunning(DeusUpdate)
  Else
    AddToLogFile(__("ERROR!"), #False, #True, system_debug)
    MessageRequester(__("Error"), FormatStr(__("Can`t execute the %1 file!"), "DEUS_UPDATE.exe"), #MB_ICONERROR)
  EndIf
  CloseNetworkServer(NetworkServer)
Else
  AddToLogFile(__("ERROR!"), #False, #True, system_debug)
  MessageRequester(__("Error"), FormatStr(__("Can`t create the http server on port %1!"), "8080"), #MB_ICONERROR)
EndIf

ProgramEndPoint:
AddToLogFile(__("The program is completed."), #True, #True, system_debug)
AddToLogFile(LSet(#Null$, 64, Chr(45)), #False, #True, system_debug)
AddToLogFile(#Null$, #False, #True, system_debug)

End 0

; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 538
; FirstLine = 514
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