#Requires AutoHotkey v2.0
#SingleInstance Force

; ==========================================================
; Configuration
; ==========================================================

downloadDir := EnvGet("USERPROFILE") "\Downloads"

scriptPath := downloadDir "\UploadClipboard.ps1"
vbsPath := downloadDir "\RunHidden.vbs"

global ActiveUploads := Map()
global UploadCounter := 0

; ==========================================================
; Tray Menu
; ==========================================================

A_TrayMenu.Delete()

A_TrayMenu.Add("Upload Clipboard", (*) => RunClipboardUpload())
A_TrayMenu.Default := "Upload Clipboard"

A_TrayMenu.Add()

A_TrayMenu.Add("Reload Script", (*) => Reload())

A_TrayMenu.Add()

A_TrayMenu.Add("Exit", (*) => ExitApp())

; ==========================================================
; Hotkey
; Ctrl + Shift + P
; ==========================================================

^+p::RunClipboardUpload()

; ==========================================================
; Upload Function
; ==========================================================

RunClipboardUpload()
{
    global scriptPath
    global vbsPath
    global ActiveUploads
    global UploadCounter

    if !FileExist(scriptPath)
    {
        MsgBox(
            "UploadClipboard.ps1 was not found.`n`n" scriptPath,
            "Paperless Upload",
            "Iconx"
        )
        return
    }

    if !FileExist(vbsPath)
    {
        MsgBox(
            "RunHidden.vbs was not found.`n`n" vbsPath,
            "Paperless Upload",
            "Iconx"
        )
        return
    }

    shell := ComObject("WScript.Shell")

    command :=
        'wscript.exe "' vbsPath '" "' scriptPath '"'

    exec := shell.Exec(command)

    UploadCounter++

    ActiveUploads[UploadCounter] := exec

    SetTimer(CheckUploads, 250)
}

; ==========================================================
; Monitor Running Uploads
; ==========================================================

CheckUploads()
{
    global ActiveUploads

    finished := []

    for id, exec in ActiveUploads
    {
        if (exec.Status != 0)
        {
            if (exec.ExitCode = 0)
            {
                TrayTip(
                    "Paperless Upload",
                    "Clipboard uploaded successfully."
                )
            }

            finished.Push(id)
        }
    }

    for id in finished
        ActiveUploads.Delete(id)

    if (ActiveUploads.Count = 0)
        SetTimer(CheckUploads, 0)
}