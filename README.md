# 📋 PaperSnap – Clipboard Uploader for Paperless-ngx

> Upload images directly from the Windows clipboard to Paperless-ngx with automatic metadata, automatic tag creation, notes support, and a global AutoHotkey launcher.

---

# Features

## 🖼 Direct Clipboard Upload

* Uploads images directly from the Windows clipboard
* No temporary image files
* No manual save required
* Image is uploaded directly from memory

---

## 📝 Metadata Prompt

Before uploading, a Windows dialog prompts for:

* **Title**
* **Tags** (comma-separated)
* **Notes**

The document date is automatically set to today's date.

---

## 🏷 Automatic Tag Creation

The uploader automatically:

* Retrieves existing tags from Paperless
* Creates missing tags
* Assigns all selected tags to the uploaded document

No manual tag management is required.

---

## 📒 Notes Support

After Paperless finishes processing the uploaded image, the uploader automatically creates a document note using the Paperless Notes API.

---

## ⚡ Intelligent Processing Detection

Instead of waiting a fixed amount of time, the uploader:

* Monitors Paperless processing tasks
* Detects when the document is available
* Immediately attaches notes

This keeps uploads as fast as your server allows.

---

## 🔐 API Authentication

Authentication is handled using a Paperless API token.

No username or password is stored inside the script.

---

## 🚫 No Temporary Files

Everything happens in memory.

```text
Clipboard
      ↓
Memory Stream
      ↓
Multipart Upload
      ↓
Paperless-ngx
```

---

## ⌨ Global Hotkey

Powered by AutoHotkey v2.

Default hotkey:

```text
Ctrl + Shift + P
```

Works globally from anywhere in Windows.

---

## 🔔 Success Notification

After a successful upload, AutoHotkey displays a Windows notification.

PowerShell only displays dialogs when an error occurs.

---

## 🚀 Multiple Concurrent Uploads

The AutoHotkey launcher supports multiple simultaneous uploads.

Each upload:

* Runs independently
* Finishes independently
* Generates its own success notification

---

# Requirements

* Windows 10 / Windows 11
* Windows PowerShell **5.1**
* Paperless-ngx
* AutoHotkey **v2**

Download AutoHotkey:

https://www.autohotkey.com/

---

# Repository

```text
PaperSnap/

├── UploadClipboard.ps1
├── PaperlessClipboard.ahk
├── RunHidden.vbs
└── README.md
```

---

# Installation

## 1. Download the Repository

Download or clone the repository.

---

## 2. Install AutoHotkey

Install the latest AutoHotkey **v2** release.

---

## 3. Place the Files

By default the launcher expects:

```text
%USERPROFILE%\Downloads\
```

Example:

```text
Downloads/

UploadClipboard.ps1
PaperlessClipboard.ahk
RunHidden.vbs
```

If you wish to store the files elsewhere, edit:

```ahk
scriptPath := EnvGet("USERPROFILE") "\Downloads\UploadClipboard.ps1"

vbsPath := EnvGet("USERPROFILE") "\Downloads\RunHidden.vbs"
```

inside **PaperlessClipboard.ahk**.

---

# Paperless Configuration

Open:

```text
UploadClipboard.ps1
```

and edit the following values.

---

## Paperless URL

Replace:

```powershell
$PaperlessUrl = "https://your-server"
```

with your own Paperless URL.

Example:

```powershell
$PaperlessUrl = "https://paperless.example.com"
```

---

## API Token

Replace:

```powershell
$ApiToken = "YOUR_API_TOKEN"
```

with your own API token.

### Where do I find my API Token?

Inside Paperless-ngx:

**Settings** → **My Profile** → **API Authentication Token**

Copy the generated token and paste it into:

```powershell
$ApiToken = "YOUR_TOKEN_HERE"
```

Do **not** share this token publicly. It grants access to your Paperless instance using your account permissions.

---

# Hidden PowerShell Launcher

The included

```text
RunHidden.vbs
```

launches PowerShell without displaying a console window.

Without it, Windows briefly opens a PowerShell console every time an upload starts.

---

# Changing the Hotkey

Default:

```text
Ctrl + Shift + P
```

Inside:

```text
PaperlessClipboard.ahk
```

change:

```ahk
^+p::RunClipboardUpload()
```

Examples:

| Hotkey           | Code   |
| ---------------- | ------ |
| Ctrl + Alt + P   | `^!p`  |
| Win + P          | `#p`   |
| F8               | `F8::` |
| Ctrl + Shift + U | `^+u`  |

---

# Changing the Polling Speed

Paperless processing is monitored using:

```powershell
Start-Sleep -Milliseconds 500
```

and

```powershell
for($i = 0; $i -lt 40; $i++)
```

Increasing the loop count increases the maximum wait time.

Reducing the sleep interval makes the uploader check Paperless more frequently.

These values may need adjustment depending on your server speed.

---

# Upload Workflow

```text
Copy Image

↓

Ctrl + Shift + P

↓

Enter Title

↓

Enter Tags

↓

Enter Notes

↓

Upload

↓

Paperless Processes Document

↓

Missing Tags Created Automatically

↓

Document Note Added

↓

Windows Notification
```

---

# Supported Paperless Features

* Clipboard Image Upload
* Automatic Date
* Automatic Tag Lookup
* Automatic Tag Creation
* Automatic Notes
* API Authentication
* Processing Monitoring
* Hidden Background Upload

---

# Limitations

This project currently supports only **clipboard image uploads**.

It does **not** support:

* PDF uploads
* Drag & Drop
* Folder monitoring
* Clipboard text
* Batch uploads
* Multi-file uploads

---

# Why PowerShell 5.1?

Windows PowerShell 5.1 is included with Windows and requires no additional installation, making the uploader portable across most Windows systems.

---

# Vibe-Coded Disclaimer

This project was largely **vibe-coded** and iteratively refined for my personal workflow.

It is being shared because others may find it useful.

However, this repository is **not intended to become a maintained application**.

## Please do **not** open Issues requesting:

* New features
* UI changes
* Workflow modifications
* Support for additional document types
* Feature enhancements

Those requests will be declined.

Feel free to fork the repository and customize it however you like.

---

# License

MIT License

Use, modify, fork, and redistribute freely.

---

# Acknowledgements

* Paperless-ngx
* AutoHotkey
* Windows PowerShell 5.1
* The open-source community for building the tools that made this project possible.
