' ----------------------------------------------------------------------------
'  MyLikita Desktop Launcher
'  Opens MyLikita in a standalone, app-style window (no tabs / no address bar)
'  using Edge or Chrome "app mode" - the closest thing to a native desktop app
'  without shipping a second runtime. Falls back to the default browser.
'
'  Reads the app port from ..\backend\.env (PORT=...) so reinstalls that move
'  the port keep working; defaults to 46990.
' ----------------------------------------------------------------------------
Option Explicit

Dim shell, fso, port, url, edge, chrome
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' -- resolve the app port from backend\.env -----------------------------------
port = "46990"
Dim envPath, line, f, m
envPath = fso.BuildPath(fso.GetParentFolderName(fso.GetParentFolderName(WScript.ScriptFullName)), "backend\.env")
If fso.FileExists(envPath) Then
  Set f = fso.OpenTextFile(envPath, 1, False)
  Do Until f.AtEndOfStream
    line = Trim(f.ReadLine)
    m = "PORT="
    If Left(line, Len(m)) = m Then
      Dim v
      v = Trim(Mid(line, Len(m) + 1))
      If Len(v) > 0 And IsNumeric(v) Then port = v
    End If
  Loop
  f.Close
End If

url = "http://localhost:" & port & "/"

' -- prefer Edge (guaranteed on Win10/11), then Chrome ------------------------
edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
If Not fso.FileExists(edge) Then edge = "C:\Program Files\Microsoft\Edge\Application\msedge.exe"

chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
If Not fso.FileExists(chrome) Then chrome = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"

If fso.FileExists(edge) Then
  ' --app= gives a frameless app window; --new-window prevents hijacking an
  ' existing Edge session
  shell.Run """" & edge & """ --app=" & url & " --new-window", 1, False
ElseIf fso.FileExists(chrome) Then
  shell.Run """" & chrome & """ --app=" & url & " --new-window", 1, False
Else
  ' fallback: default browser
  shell.Run url, 1, False
End If
