; Инициализация перевода
XIncludeFile #PB_Compiler_FilePath+"includes\i18n\i18n.pbi"
Translator_init("languages/", #NULL$)

; Инициализация сети
InitNetwork()

; Создаем дирректории
If FileSize("updates")=-1
  CreateDirectory("updates/")
EndIf
If FileSize("updates/cache_updates")=-1
  CreateDirectory("updates/cache_updates/")
EndIf

; Обновление versions.txt
Global VersionsFileName$ = "5_0_01" ; Method:HIDBootLoader.Form1.Thread_ReadVersion()
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
        EndIf
      EndIf
    Wend
    FinishDirectory(VersionsDirectory)
  EndIf
  CloseFile(VersionsFile)
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
    Else ; Ошибка 404
      Answer$ = #NULL$
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
    EndIf
  Else ; Ошибка 400
    Answer$ = #NULL$
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
NetworkServer.l = CreateNetworkServer(#PB_Any, 8080, #PB_Network_TCP)
If NetworkServer
  ; Запускаем DEUS UPDATE
  DeusUpdate.l = RunProgram("DEUS_UPDATE.exe", "", "", #PB_Program_Open)
  If DeusUpdate
    Repeat
      Select NetworkServerEvent(NetworkServer)
        Case #PB_NetworkEvent_Data
          ClientID.l = EventClient()
          CreateThread(@RequestProcess(), ClientID)
      EndSelect
    Until Not ProgramRunning(DeusUpdate)
  Else
    MessageRequester(__("Error"), FormatStr(__("Can`t execute the %1 file!"), "DEUS_UPDATE.exe"), #MB_ICONERROR)
  EndIf
  CloseNetworkServer(NetworkServer)
Else
  MessageRequester(__("Error"), FormatStr(__("Can`t create the http server on port %1!"), "8080"), #MB_ICONERROR)
EndIf

End 0

; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 73
; FirstLine = 61
; Folding = -
; EnableUnicode
; EnableThread
; EnableXP
; EnableAdmin
; UseIcon = dou.ico
; Executable = dou_x32.exe
; EnableCompileCount = 0
; EnableBuildCount = 0
; IncludeVersionInfo
; VersionField0 = 1.1.%BUILDCOUNT.%COMPILECOUNT
; VersionField1 = 1.1.%BUILDCOUNT.%COMPILECOUNT
; VersionField2 = LipKop.club
; VersionField3 = Updater
; VersionField4 = 1.1.%BUILDCOUNT.%COMPILECOUNT
; VersionField5 = 1.1.%BUILDCOUNT.%COMPILECOUNT
; VersionField6 = Unofficial XP Deus updater
; VersionField7 = deus_offline_updater
; VersionField8 = %EXECUTABLE
; VersionField9 = Sergey Avdeev
; VersionField13 = avdeevsv91@gmail.com
; VersionField14 = http://io-net.ru
; VersionField15 = VOS_NT
; VersionField16 = VFT_APP