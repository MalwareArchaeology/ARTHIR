<#
.SYNOPSIS
Get-OS_Version_Details.ps1 queries the local system for its operating system.  
  * Computername
  * Operating System
  * OS Architecture
 
MITRE ATT&CK Technique IDs: none
 
If you want to remove the reports and directories from remote systems after it has run
use the cleanup module Get-Delete_ARTHIR_Folders.ps1. 
 
Adjust the variables to what you want to do with each item:
  $ARTHIR_OutputDir 			Set to a directory you want the results of the modules to be stored for harvesting
  $ARTHIR_ReportName			What to name the report.  Match this to DOWNLOAD
  $SysName						What you want each report to be pre-pended wiht like "computername"
  $WriteEventLogEntry			Create an event log entry that this module ran 'Yes' or 'No'
  $EventSource					The name of the source the event will be written to the Application log (default is ARTHIR)
  $Event_ID						What event ID to use in the log entry
  
  DOWNLOAD						The name of the report you will copy back to the host or launching system, wildcards are acceptable
  
.NOTES
The following DIRECTIVE lines are needed by ARTHIR.ps1 to determine how to handle output
from this script.

DOWNLOAD C:\Program Files\ARTHIR\Results\*Report_System_Info.txt

#>
$ARTHIR_Dir = "C:\Program Files\ARTHIR"
$ARTHIR_OutputDir = "C:\Program Files\ARTHIR\Results"
$ARTHIR_ReportName = "Report_System_Info.txt"
$SysName = $env:computername
$MinPSVersion = 6
$WriteEventLogEntry = "Yes"
$EventSource = "ARTHIR"
$Event_ID = "1337"
#
#  Check for minimal PowerShell version
#
If ($PSVersionTable.PSVersion.Major -ge $MinPSVersion) {
  Write-Output "System has PS $MinPSVersion or greater"
  Break
  }  
#
#  Check for report folder existing, or create it
#
if (Test-Path $ARTHIR_OutputDir) {
    Write-Output $ARTHIR_OutputDir "already exists"
 } else {
    new-item $ARTHIR_OutputDir -itemtype directory
    }
#
#  Get OS details
#
Write-Output $SysName | out-file -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
$wmiOS = Get-WmiObject -ComputerName $env:computername -Class Win32_OperatingSystem;
$OS = $wmiOS.caption;
$OS | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
(Get-WmiObject win32_operatingsystem).osarchitecture | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
#
Write-Output "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
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