Set shell = CreateObject("WScript.Shell")

cmd = "powershell.exe -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File """ _
    & WScript.Arguments(0) _
    & """ -UploadId """ _
    & WScript.Arguments(1) _
    & """"

shell.Run cmd,0,True

WScript.Quit