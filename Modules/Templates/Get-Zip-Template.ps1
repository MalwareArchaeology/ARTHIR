<#
.SYNOPSIS
Get-Zip-Template.ps1 This template is for pushing Zip files to remote system.  This is how you get 
configurations, support files or other data you need.  You may need to break up your data into multiple Zip files
 
 - WARNING:  You are limited to 52MB for this file transfers due to limitations of WinRM.

Use the following to record the modules applicability to the MITRE ATT&CK Framework

MITRE ATT&CK Technique IDs: none
 
When you run ARTHIR.ps1, if you add the -Pushbin switch at the command line, ARTHIR.ps1 
will attempt to copy the filename.zip to each remote target's ADMIN$ share and then move it
to the folder you specify below.

This module will allow you to send configuration files to the remote system.
It includes:
 - Whatever is in your Zip file
 - Whatever else

When used with -PushBin argument, copies Whatever.zip from the Modules\bin\ 
path to each remote host and extracts to C:\Windows or ADMIN$ folder. 
You may want to tweak this to target specific needs if you are after specific areas. 

.NOTES
Next line is required by ARTHIR for proper handling of third-party binary.
The BINDEP directive below tells ARTHIR where to find the third-party code.

BINDEP .\Modules\bin\Whatever.zip
DOWNLOAD C:\Program Files\WhateverDir\Results\*Report_Zip_Status.txt

#>
#
# Set folders where you want LOG-MD and Reports to reside
#
$Zip_File = "Whatever.zip"
$ARTHIR_Dir = "C:\Program Files\Wherever"
$ARTHIR_OutputDir = "C:\Program Files\WhateverDir\Results"
$ARTHIR_ReportName = "Report_Zip_Status.txt"
$SysName = $env:computername
$WriteEventLogEntry = "Yes"
$EventSource = "ARTHIR"
$Event_ID = "1337"
#
#  Check for report folder existing, or create it
#
if (Test-Path $ARTHIR_OutputDir) {
    Write-Output $ARTHIR_OutputDir "already exists"
 } else {
    new-item $ARTHIR_OutputDir -itemtype directory
    }
#
# Move archive to $ARTHIR_Dir
#
Move-Item -Path "$env:SystemRoot\$Zip_File" -Destination $ARTHIR_Dir
#
# Test if Zip was properly copied
#
if (Test-Path $ARTHIR_Dir\$Zip_File) {
    Write-Output "$Zip_File copied successfully" | out-file -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
    } else {
    Write-Error "$Zip_File not found in $ARTHIR_Dir."
    Exit
    }
#
# Remove existing configs
#
Remove-Item $ARTHIR_Dir\<your_files> -force
Start-Sleep -s 10
#
#  Function to extract Zip file for all PS versions
#
Add-Type -AssemblyName System.IO.Compression.FileSystem
  function UnZip_File {
    param( [string]$ziparchive, [string]$extractpath )
    [System.IO.Compression.ZipFile]::ExtractToDirectory( $ziparchive, $extractpath )
  }
    UnZip_File $ARTHIR_Dir\$Zip_File $ARTHIR_Dir
  Start-Sleep -s 10
  Remove-Item $ARTHIR_Dir\$Zip_File -Force 
#
#  Write log entry
#
If ($WriteEventLogEntry -eq 'No') {
  Break
  }  
  elseif ([System.Diagnostics.EventLog]::SourceExists($EventSource) -eq $False) {
    New-EventLog -LogName Application -Source $EventSource
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'Operating System info gathered by Arthir'
 }
  else {
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'Operating System info gathered by Arthir'
    }
