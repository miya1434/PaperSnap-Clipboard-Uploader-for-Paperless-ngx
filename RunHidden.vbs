Set shell = CreateObject("WScript.Shell")

cmd = "powershell.exe -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File """ & WScript.Arguments(0) & """"

shell.Run cmd, 0, True

WScript.Quit