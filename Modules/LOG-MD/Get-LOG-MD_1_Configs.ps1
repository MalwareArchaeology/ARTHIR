<#
.SYNOPSIS
Get-LOG-MD_1_Configs.ps1 - Pushes out Zip file of config settings.

This module will allow you to send your LOG-MD configuration files to the remote system.
It includes:
  Whitelists
  Settings
  MasterDigest

Use the following to record the modules applicability to the MITRE ATT&CK Framework

MITRE ATT&CK Technique IDs: TBD
  
When used with -PushBin argument, copies LOG-MD-Config.zip from the Modules\bin\ 
path to each remote host and extracts to C:\Windows or ADMIN$ folder. 
You may want to tweak this to target specific needs if you are after specific areas. 

.NOTES
Next line is required by ARTHIR for proper handling of third-party binary.
The BINDEP directive below tells ARTHIR where to find the third-party code.

BINDEP .\Modules\bin\LOG-MD_Configs.zip
DOWNLOAD C:\Program Files\LMD\Results\*Report_Zip_Main_Configs.txt
#>
#
# Set folders where you want LOG-MD and Reports to reside
#
$Zip_File = "LOG-MD_Configs.zip"
$ARTHIR_Dir = "C:\Program Files\LMD"
$ARTHIR_OutputDir = "C:\Program Files\LMD\Results"
$ARTHIR_ReportName = "Report_Zip_Main_Configs.txt"
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
Remove-Item $ARTHIR_Dir\Settings_*.txt -force
Remove-Item $ARTHIR_Dir\Whitelist_*.txt -force
Remove-Item $ARTHIR_Dir\MasterDigest.txt -force
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
