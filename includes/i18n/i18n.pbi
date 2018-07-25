; Translator
; JCV @ PureBasic Forum
; http://www.JCVsite.com
; Corrected by djes@free.fr Jul 18th 2011


XIncludeFile "locale.pbi"

#COUNT_OFFSET = 8
#ORIG_TABLE_POINTER_OFFSET = 12
#TRANSLATION_TABLE_POINTER_OFFSET = 16

Global origTableOffset.l, translationTableOffset.l
Global *Translator_MemoryID, Translator_Filesize.l
Global NewMap TranslationTable.s()

Declare.s Translator_Autodetect(podir.s, requested_locale.s)
Declare   Translator(FileName.s)
Declare.s Translator_getOrigMessage(index.l)
Declare.s Translator_getTranslationMessage(index.l)
Declare.s Translator_translate(message.s)

Procedure Translator_init(podir.s, locale.s)
  ProcedureReturn Translator(Translator_Autodetect(podir, locale))
EndProcedure

Procedure Translator_destroy()
  ClearMap(TranslationTable())
EndProcedure
  
Procedure.s Translator_Autodetect(podir.s, requested_locale.s)
  Protected locale.s
  If requested_locale=#Null$
    locale = getLanguageName()
    If locale = #Null$
      ProcedureReturn #Null$
    EndIf
  Else
    locale = requested_locale
  EndIf
  ; ≈сли нет перевода дл€ украинского €зыка
  If locale="uk_UA" And FileSize(podir+locale+".mo")<0
    locale = "ru_RU" ; “о будем пытатьс€ использовать русский
  EndIf
  ; ѕровер€ем наличие перевода дл€ текущего €зыка
  If FileSize(podir+locale+".mo")>0
    ProcedureReturn podir + locale + ".mo"
  EndIf
  ProcedureReturn #Null$
EndProcedure

Procedure.s Translator_getOrigMessage(index.l)
  Protected len.l, msgOffset.l
  len       = PeekL(*Translator_MemoryID + origTableOffset + index * 8)
  msgOffset = PeekL(*Translator_MemoryID + origTableOffset + index * 8 + 4)
  ProcedureReturn PeekS(*Translator_MemoryID + msgOffset, len)
EndProcedure

Procedure.s Translator_getTranslationMessage(index.l)
  Protected len.l, msgOffset.l
  len       = PeekL(*Translator_MemoryID + translationTableOffset + index * 8)
  msgOffset = PeekL(*Translator_MemoryID + translationTableOffset + index * 8 + 4)
  ProcedureReturn PeekS(*Translator_MemoryID + msgOffset, len)
EndProcedure

Procedure Translator(FileName.s)
  Protected hFile.l, count.l, i.l
  hFile = ReadFile(#PB_Any, FileName)
  If hFile
    Translator_Filesize = Lof(hFile)
    *Translator_MemoryID = AllocateMemory(Translator_Filesize)
    If *Translator_MemoryID
      ReadData(hFile, *Translator_MemoryID, Translator_Filesize)
    Else
      ProcedureReturn 1
    EndIf
    CloseFile(hFile)
  Else
    ProcedureReturn 2
  EndIf
  ; Sanity check file Size.
  If (Translator_Filesize < #TRANSLATION_TABLE_POINTER_OFFSET)
    ProcedureReturn 0
  EndIf
  ; Further sanity check file Size.
  If (Translator_Filesize < origTableOffset Or Translator_Filesize < translationTableOffset)
    ProcedureReturn 1
  EndIf
  count                  = PeekL(*Translator_MemoryID + #COUNT_OFFSET)
  origTableOffset        = PeekL(*Translator_MemoryID + #ORIG_TABLE_POINTER_OFFSET)
  translationTableOffset = PeekL(*Translator_MemoryID + #TRANSLATION_TABLE_POINTER_OFFSET)
  For i = 0 To count - 1
    TranslationTable(Translator_getOrigMessage(i)) = Translator_getTranslationMessage(i)
  Next i
  FreeMemory(*Translator_MemoryID)
EndProcedure

Procedure.s t(msg.s=#Null$)
  Protected out.s
  If msg = #Null$
    ProcedureReturn #Null$
  EndIf
  out = TranslationTable(msg)
  If out = #Null$
    out = msg
  EndIf
  ProcedureReturn out
EndProcedure

Macro __(msg=#Null$)
  t(msg)
EndMacro

; FormatStr("This %1 is %2", "text", "formatted") ; This text is formatted
Procedure.s FormatStr(Text.s, s1.s=#Null$, s2.s=#Null$, s3.s=#Null$, s4.s=#Null$, s5.s=#Null$, s6.s=#Null$, s7.s=#Null$, s8.s=#Null$, s9.s=#Null$, s10.s=#Null$)
  Text = ReplaceString(Text, "%1",  s1)
  Text = ReplaceString(Text, "%2",  s2)
  Text = ReplaceString(Text, "%3",  s3)
  Text = ReplaceString(Text, "%4",  s4)
  Text = ReplaceString(Text, "%5",  s5)
  Text = ReplaceString(Text, "%6",  s6)
  Text = ReplaceString(Text, "%7",  s7)
  Text = ReplaceString(Text, "%8",  s8)
  Text = ReplaceString(Text, "%9",  s9)
  Text = ReplaceString(Text, "%10", s10)
	ProcedureReturn Text
EndProcedure

; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 127
; FirstLine = 82
; Folding = --
; UseMainFile = ..\..\main.pb