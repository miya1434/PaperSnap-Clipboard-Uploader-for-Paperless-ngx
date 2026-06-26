#Requires -Version 5.1
# Must be launched with -STA

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Net.Http

############################################################
# CONFIGURATION
############################################################

$PaperlessUrl = "https://paperless.example.com"
$ApiToken     = "YOUR_TOKEN_HERE"

$Today = Get-Date -Format "yyyy-MM-dd"

############################################################
# Clipboard Check
############################################################

if (-not [System.Windows.Clipboard]::ContainsImage())
{
    [System.Windows.MessageBox]::Show(
        "Clipboard does not contain an image.",
        "Paperless Upload",
        "OK",
        "Information"
    ) | Out-Null

    exit
}

############################################################
# XAML GUI
############################################################

[xml]$xaml = @"
<Window
xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
Title="Paperless Upload"
Height="340"
Width="420"
ResizeMode="NoResize"
WindowStartupLocation="CenterScreen">

<Grid Margin="15">

<Grid.RowDefinitions>
<RowDefinition Height="Auto"/>
<RowDefinition Height="Auto"/>
<RowDefinition Height="*"/>
<RowDefinition Height="Auto"/>
</Grid.RowDefinitions>

<TextBlock
Text="Title"
Margin="0,0,0,5"/>

<TextBox
Name="txtTitle"
Grid.Row="1"
Height="28"/>

<StackPanel
Grid.Row="2"
Margin="0,15,0,0">

<TextBlock Text="Tags (comma separated)"/>

<TextBox
Name="txtTags"
Height="28"/>
<TextBlock
Margin="0,12,0,4"
Text="Notes"/>

<TextBox
Name="txtNotes"
Height="90"
AcceptsReturn="True"
VerticalScrollBarVisibility="Auto"
TextWrapping="Wrap"/>

</StackPanel>

<StackPanel
Grid.Row="3"
Orientation="Horizontal"
HorizontalAlignment="Right"
Margin="0,20,0,0">

<Button
Name="btnCancel"
Width="80"
Margin="0,0,10,0">
Cancel
</Button>

<Button
Name="btnUpload"
Width="80"
IsDefault="True">
Upload
</Button>

</StackPanel>

</Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$Window = [Windows.Markup.XamlReader]::Load($reader)

$txtTitle   = $Window.FindName("txtTitle")
$txtTags    = $Window.FindName("txtTags")
$txtNotes = $Window.FindName("txtNotes")
$btnUpload  = $Window.FindName("btnUpload")
$btnCancel  = $Window.FindName("btnCancel")

$Result = $false

$btnCancel.Add_Click({
    $Window.Close()
})

$btnUpload.Add_Click({

    if([string]::IsNullOrWhiteSpace($txtTitle.Text))
    {
        [System.Windows.MessageBox]::Show(
            "Please enter a title."
        ) | Out-Null
        return
    }

    $script:Result = $true
    $Window.Close()
})

$Window.ShowDialog() | Out-Null

if(-not $Result)
{
    exit
}

############################################################
# Read metadata
############################################################

$Title = $txtTitle.Text.Trim()

$Notes = $txtNotes.Text.Trim()

$TagNames = @()

if($txtTags.Text.Trim() -ne "")
{
    $TagNames = $txtTags.Text.Split(",") |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne "" } |
        Sort-Object -Unique
}

############################################################
# Read clipboard image
############################################################

$image = [System.Windows.Clipboard]::GetImage()

$encoder = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
$encoder.Frames.Add(
    [System.Windows.Media.Imaging.BitmapFrame]::Create($image)
)

$memory = New-Object System.IO.MemoryStream
$encoder.Save($memory)

$memory.Position = 0
$imageBytes = $memory.ToArray()

############################################################
# HTTP Client
############################################################

$client = [System.Net.Http.HttpClient]::new()

$client.DefaultRequestHeaders.Authorization =
    [System.Net.Http.Headers.AuthenticationHeaderValue]::new(
        "Token",
        $ApiToken
    )

$client.DefaultRequestHeaders.Accept.Clear()

$client.DefaultRequestHeaders.Accept.Add(
    [System.Net.Http.Headers.MediaTypeWithQualityHeaderValue]::new(
        "application/json"
    )
)

$client.Timeout = [TimeSpan]::FromMinutes(5)

############################################################
# Helper Functions
############################################################

function Invoke-JsonGet
{
    param($Url)

    $response = $client.GetAsync($Url).Result

    if(!$response.IsSuccessStatusCode)
    {
        throw $response.Content.ReadAsStringAsync().Result
    }

    return (
        $response.Content.ReadAsStringAsync().Result |
        ConvertFrom-Json
    )
}

function Invoke-JsonPost
{
    param(
        $Url,
        $Body
    )

    $json = $Body | ConvertTo-Json -Depth 20

    $content =
        New-Object System.Net.Http.StringContent(
            $json,
            [System.Text.Encoding]::UTF8,
            "application/json"
        )

    $response = $client.PostAsync(
        $Url,
        $content
    ).Result

    if(!$response.IsSuccessStatusCode)
    {
        throw $response.Content.ReadAsStringAsync().Result
    }

    return (
        $response.Content.ReadAsStringAsync().Result |
        ConvertFrom-Json
    )
    }



############################################################
# Resolve Tags
############################################################

$TagIds = @()

foreach($tagName in $TagNames)
{
    $encoded =
        [System.Uri]::EscapeDataString($tagName)

    try
    {
        # Search for an existing tag
        $existing = Invoke-JsonGet `
            "$PaperlessUrl/api/tags/?name__icontains=$encoded&page_size=200"

        $match = $existing.results |
            Where-Object { $_.name -ieq $tagName } |
            Select-Object -First 1

        if($match)
        {
            $TagIds += $match.id
            continue
        }

        ####################################################
        # Tag not found -> create it
        ####################################################

        $created = Invoke-JsonPost `
            "$PaperlessUrl/api/tags/" `
            @{
                name = $tagName
            }

        $TagIds += $created.id
    }
    catch
    {
        [System.Windows.MessageBox]::Show(
@"
Failed to resolve tag:

$tagName

$($_.Exception.Message)
"@,
            "Paperless Upload",
            "OK",
            "Error"
        ) | Out-Null

        exit
    }
}

############################################################
# Multipart Upload
############################################################

$content = New-Object System.Net.Http.MultipartFormDataContent

$fileContent = [System.Net.Http.ByteArrayContent]::new($imageBytes)

$fileContent.Headers.ContentType =
    [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse(
        "image/png"
    )

$content.Add(
    $fileContent,
    "document",
    "clipboard.png"
)

$content.Add(
    (New-Object System.Net.Http.StringContent($Title)),
    "title"
)

if ($Notes -ne "")
{
    $content.Add(
        (New-Object System.Net.Http.StringContent($Notes)),
        "notes"
    )
}

$content.Add(
    (New-Object System.Net.Http.StringContent($Today)),
    "created_date"
)

foreach($id in $TagIds)
{
    $content.Add(
        (New-Object System.Net.Http.StringContent("$id")),
        "tags"
    )
}

############################################################
# Submit Upload
############################################################

try
{
  $response = $client.PostAsync(
    "$PaperlessUrl/api/documents/post_document/",
    $content
).Result

$body = $response.Content.ReadAsStringAsync().Result

if(!$response.IsSuccessStatusCode)
{
    throw $body
}

############################################################
# Wait for Paperless Processing
############################################################

$taskId = $body.Trim('"')

$task = $null

for($i = 0; $i -lt 40; $i++)
{
    Start-Sleep -Milliseconds 500

    try
    {
        $taskResponse = Invoke-JsonGet `
            "$PaperlessUrl/api/tasks/?task_id=$taskId"

        if($taskResponse.Count -eq 0)
        {
            continue
        }

        $task = $taskResponse[0]
        
		if(
		    $task.related_document -and
			 [int]$task.related_document -gt 0
	    )	 
        {
             break
        }

        switch($task.status)
        {

            "FAILURE"
            {
                throw "Paperless processing failed."
            }

            "CANCELLED"
            {
                throw "Paperless task was cancelled."
            }
        }
    }
    catch
    {
        throw $_
    }
}

if(-not $task)
{
    throw "Timed out waiting for Paperless.`n`nTask ID:`n$taskId"
}

$DocumentId = [int]$task.related_document

############################################################
# Create Document Note
############################################################

if (-not [string]::IsNullOrWhiteSpace($Notes))
{
    Invoke-JsonPost `
        "$PaperlessUrl/api/documents/$DocumentId/notes/" `
        @{
            note = $Notes
        } | Out-Null
}
exit 0
}
   

############################################################
# Upload Error
############################################################

catch
{
    $errorText = $_.Exception.Message

    if([string]::IsNullOrWhiteSpace($errorText))
    {
        $errorText = $_
    }

    [System.Windows.MessageBox]::Show(
@"
Upload failed.

$errorText
"@,
        "Paperless Upload",
        "OK",
        "Error"
    ) | Out-Null
exit 1
}

############################################################
# Cleanup
############################################################

finally
{
    if($content)
    {
        $content.Dispose()
    }

    if($fileContent)
    {
        $fileContent.Dispose()
    }

    if($memory)
    {
        $memory.Dispose()
    }

    if($client)
    {
        $client.Dispose()
    }
}

exit