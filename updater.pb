InitNetwork()

; Список файлов, из которых состоит прошивка
Structure FirmwareFile
  Directory.s ; Название дирректории, в которой находится файл
  File.s      ; Имя файла прошивки
  Required.b  ; Этот файл обязателен или нет
EndStructure
Global NewList FirmwareFiles.FirmwareFile()
AddElement(FirmwareFiles()) : FirmwareFiles()\Directory = "Casque" : FirmwareFiles()\File = "C01.txt" : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\Directory = "Disques" : FirmwareFiles()\File = "004.txt" : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\Directory = "Disques" : FirmwareFiles()\File = "104.txt" : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\Directory = "Disques" : FirmwareFiles()\File = "R_004.txt" : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\Directory = "Disques" : FirmwareFiles()\File = "R_104.txt" : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\Directory = "Telecommande" : FirmwareFiles()\File = "Restaure20130108.txt" : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\Directory = "Telecommande" : FirmwareFiles()\File = "T01.txt" : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\Directory = "Telecommande" : FirmwareFiles()\File = "T02.txt" : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\Directory = "Telecommande" : FirmwareFiles()\File = "T03.txt" : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\Directory = "Telecommande" : FirmwareFiles()\File = "T04.txt" : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\Directory = "Telecommande" : FirmwareFiles()\File = "T05.txt" : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\Directory = "Telecommande" : FirmwareFiles()\File = "T06.txt" : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\Directory = "Telecommande" : FirmwareFiles()\File = "T07.txt" : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\Directory = "Telecommande" : FirmwareFiles()\File = "T08.txt" : FirmwareFiles()\Required = #False
AddElement(FirmwareFiles()) : FirmwareFiles()\Directory = "Telecommande" : FirmwareFiles()\File = "T09.txt" : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\Directory = "Telecommande" : FirmwareFiles()\File = "T0A.txt" : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\Directory = "Telecommande" : FirmwareFiles()\File = "T0B.txt" : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\Directory = "Telecommande" : FirmwareFiles()\File = "T0C.txt" : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\Directory = "Telecommande" : FirmwareFiles()\File = "T0D.txt" : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\Directory = "Telecommande" : FirmwareFiles()\File = "T0E.txt" : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\Directory = "Telecommande" : FirmwareFiles()\File = "T0F.txt" : FirmwareFiles()\Required = #True

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

; Обновление прошивок в локальном каталоге
Global UpdateSuccess.b = #False
Procedure UpdateCacheFirmware(Null)
  If ReceiveHTTPFile("http://deus.lipkop.club/Update/deus_updates/versions.php", "updates/versions.txt")
    Count.l = CountFileStrings("updates/versions.txt")
    If Count>0 And ReadFile(0, "updates/versions.txt")
      SetGadgetAttribute(0, #PB_ProgressBar_Maximum, Count*ListSize(FirmwareFiles()))
      While Eof(0) = 0
        version$ = Trim(ReadString(0))
        If Len(version$)>0
          If FileSize("updates/cache_updates/"+version$) = -1 ; Если в локальном кеше такой прошивки нету
            ; Качаем ее во временный каталог
            DownloadOfSuccessful.b = #True
            CreateDirectory("updates/"+version$)
            ResetList(FirmwareFiles())
            While NextElement(FirmwareFiles())
              If FileSize("updates/"+version$+"/"+FirmwareFiles()\Directory) = -1
                CreateDirectory("updates/"+version$+"/"+FirmwareFiles()\Directory)
              EndIf
              If Not ReceiveHTTPFile("http://deus.lipkop.club/Update/deus_updates/"+version$+"/"+FirmwareFiles()\Directory+"/"+FirmwareFiles()\File, "updates/"+version$+"/"+FirmwareFiles()\Directory+"/"+FirmwareFiles()\File) And FirmwareFiles()\Required = #True
                DownloadOfSuccessful.b = #False
                SetGadgetState(0, GetGadgetState(0)+ListSize(FirmwareFiles())-ListIndex(FirmwareFiles()))
                Break 1
              Else
                SetGadgetState(0, GetGadgetState(0)+1)
              EndIf
            Wend
            If DownloadOfSuccessful ; Если прошивка скачалась успешно
              CopyDirectory("updates/"+version$, "updates/cache_updates/"+version$, "", #PB_FileSystem_Recursive | #PB_FileSystem_Force)
            EndIf
            DeleteDirectory("updates/"+version$, "", #PB_FileSystem_Recursive | #PB_FileSystem_Force)
          Else
            SetGadgetState(0, GetGadgetState(0)+ListSize(FirmwareFiles()))
          EndIf
        EndIf
      Wend
      CloseFile(0)
    Else
      SetGadgetState(0, 1)
    EndIf
    DeleteFile("updates/versions.txt", #PB_FileSystem_Force)
  EndIf
  UpdateSuccess = #True
EndProcedure

; Если интернет доступен
If CheckInternetConnection()
  Exit.b = #False
  OpenWindow(0, #PB_Any, #PB_Any, 300, 35, "Updating...", #PB_Window_ScreenCentered)
  ProgressBarGadget(0, 5, 5, 290, 25, 0, 1)
  CreateThread(@UpdateCacheFirmware(), #Null)
  Repeat
    WaitWindowEvent(100)
  Until UpdateSuccess
  CloseWindow(0)
EndIf

; Обновление versions.txt
If OpenFile(1, "updates/cache_updates/versions.txt") Or CreateFile(1, "updates/cache_updates/versions.txt")
  TruncateFile(1)
  If ExamineDirectory(0, "updates/cache_updates/", "")
    While NextDirectoryEntry(0)
      If DirectoryEntryType(0) = #PB_DirectoryEntry_Directory
        DirectoryName$ = DirectoryEntryName(0)
        If DirectoryName$<>"." And DirectoryName$<>".."
          WriteStringN(1, DirectoryName$)
        EndIf
      EndIf
    Wend
    FinishDirectory(0)
  EndIf
  CloseFile(1)
EndIf

; Процедура обработки запроса для HTTP сервера
Procedure RequestProcess(ClientID.l)
  *Memory = AllocateMemory(1024)
  MemorySize.l = ReceiveNetworkData(ClientID, *Memory, MemorySize(*Memory))
  ClientRequest$ = PeekS(*Memory, MemorySize, #PB_UTF8)
  If Len(Trim(ClientRequest$))=0 : ProcedureReturn #False : EndIf
  FreeMemory(*Memory) : RequestFile$ = ""
  For i=1 To CountString(ClientRequest$, #LF$)
    RequestLine$ = Trim(StringField(ClientRequest$, i, #LF$))
    If Left(RequestLine$, 3) = "GET"
      RequestFile$ = Trim(StringField(RequestLine$, 2, " "))
    EndIf
  Next i
  ; Читаем запрошенный файл с диска
  If Len(RequestFile$)>0
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
      If Len(RequestFile$)>0
        Answer$ = #NULL$
        Answer$ + "<!DOCTYPE HTML PUBLIC "+Chr(34)+"-//IETF//DTD HTML 2.0//EN"+Chr(34)+">"+#CR$+#LF$
        Answer$ + "<html><head>"+#CR$+#LF$
        Answer$ + "<title>404 Not Found</title>"+#CR$+#LF$
        Answer$ + "</head><body>"+#CR$+#LF$
        Answer$ + "<h1>Not Found</h1>"+#CR$+#LF$
        Answer$ + "<p>The requested URL /"+RequestFile$+" was not found on this server.</p>"+#CR$+#LF$
        Answer$ + "<p>Additionally, a 404 Not Found error was encountered while trying to use an ErrorDocument to handle the request.</p>"+#CR$+#LF$
        Answer$ + "</body></html>"+#CR$+#LF$
        SendNetworkString(ClientID, "HTTP/1.1 404 Not Found"+#CR$+#LF$)
        SendNetworkString(ClientID, "Content-Length: "+Len(Answer$)+#CR$+#LF$)
        SendNetworkString(ClientID, "Content-Type: text/html"+#CR$+#LF$)
        SendNetworkString(ClientID, "Connection: close"+#CR$+#LF$)
        SendNetworkString(ClientID, #CR$+#LF$)
        SendNetworkString(ClientID, Answer$)
      Else
        SendNetworkString(ClientID, "HTTP/1.1 302 Moved Temporarily"+#CR$+#LF$)
        SendNetworkString(ClientID, "Location: http://deus.lipkop.club"+#CR$+#LF$)
        SendNetworkString(ClientID, "Content-Length: 0"+#CR$+#LF$)
        SendNetworkString(ClientID, "Content-Type: text/html"+#CR$+#LF$)
        SendNetworkString(ClientID, "Connection: close"+#CR$+#LF$)
        SendNetworkString(ClientID, #CR$+#LF$)
        SendNetworkString(ClientID, Answer$)
      EndIf
    EndIf
  Else ; Ошибка 400
    Answer$ = #NULL$
    Answer$ + "<!DOCTYPE HTML PUBLIC "+Chr(34)+"-//IETF//DTD HTML 2.0//EN"+Chr(34)+">"+#CR$+#LF$
    Answer$ + "<html><head>"+#CR$+#LF$
    Answer$ + "<title>400 Bad Request</title>"+#CR$+#LF$
    Answer$ + "</head><body>"+#CR$+#LF$
    Answer$ + "<h1>Bad Request</h1>"+#CR$+#LF$
    Answer$ + "<p>Your browser sent a request that this server could not understand.</p>"+#CR$+#LF$
    Answer$ + "<p>Additionally, a 400 Bad Request error was encountered while trying to use an ErrorDocument to handle the request.</p>"+#CR$+#LF$
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
    MessageRequester("Error", "Can`t execute the DEUS_UPDATE.exe file!", #MB_ICONERROR)
  EndIf
Else
  MessageRequester("Error", "Can`t create the http server on port 8080!", #MB_ICONERROR)
EndIf
End

; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 178
; FirstLine = 153
; Folding = -
; EnableUnicode
; EnableThread
; EnableXP
; UseIcon = updater.ico
; Executable = updater.exe