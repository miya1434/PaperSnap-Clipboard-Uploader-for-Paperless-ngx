#Requires AutoHotkey v2.0
#SingleInstance Force

; ==========================================================
; Configuration
; ==========================================================

downloadDir := EnvGet("USERPROFILE") "\Downloads"

scriptPath := downloadDir "\UploadClipboard.ps1"
vbsPath    := downloadDir "\RunHidden.vbs"

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
; ==========================================================

^+p::RunClipboardUpload()

; ==========================================================
; Start background watcher
; ==========================================================

SetTimer(CheckSuccessFlags, 250)

; ==========================================================
; Launch Upload
; ==========================================================

RunClipboardUpload()
{
    global scriptPath
    global vbsPath

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

    guid := ComObject("Scriptlet.TypeLib").GUID
    guid := StrReplace(guid, "{", "")
    guid := StrReplace(guid, "}", "")

    successFlag := EnvGet("TEMP") "\PaperSnap_" guid ".success"

    if FileExist(successFlag)
        FileDelete(successFlag)

    Run(
        'wscript.exe "' vbsPath '" "' scriptPath '" "' guid '"',
        ,
        "Hide"
    )
}

; ==========================================================
; Success Flag Monitor
; ==========================================================

CheckSuccessFlags()
{
    temp := EnvGet("TEMP")

    Loop Files, temp "\PaperSnap_*.success"
    {
        try
        {
            FileDelete(A_LoopFileFullPath)

            TrayTip(
                "PaperSnap",
                "Clipboard uploaded successfully."
            )
        }
    }
}
