<#
.SYNOPSIS
Get-PS_Version_Logging_Details.ps1 returns the following data on PowerShell
  * PowerShell version
  * PowerShell Logging settings
  * .Net Version

Use the following to record the modules applicability to the MITRE ATT&CK Framework

MITRE ATT&CK Technique IDs: T1028 (WinRM,) T1064 (Scripting), T1086 (PowerShell), T1140 (Obfuscation)

Only output will be created for the version lower than specified.  Errors will be throw for systems that are compliant
as it will not generate the report, thus throwing an error.
 
If you want to remove the reports and directories from remote systems after it has run
use the cleanup module Get-Delete_ARTHIR_Folders.ps1.

Adjust the variables to what you want to do with each item:
  $ARTHIR_OutputDir 			Set to a directory you want the results of the modules to be stored for harvesting
  $ARTHIR_ReportName			What to name the report.  Match this to DOWNLOAD
  $SysName						What you want each report to be pre-pended with like "computername"
  $MinPSVersion					What minimum PowerShell veersion do you want to look for
  $WriteEventLogEntry			Create an event log entry that this module ran 'Yes' or 'No'
  $EventSource					The name of the source the event will be written to the Application log (default is ARTHIR)
  $Event_ID						What event ID to use in the log entry
   
  DOWNLOAD						The name of the report you will copy back to the host or launching system, wildcards are acceptable
  
.NOTES
The following DIRECTIVE lines are needed by ARTHIR.ps1 to determine how to handle output
from this script.

DOWNLOAD C:\Program Files\ARTHIR\Results\*Report_PS_Dot_Net_Versions.txt

#>
$ARTHIR_OutputDir = "C:\Program Files\ARTHIR\Results"
$ARTHIR_ReportName = "Report_PS_Dot_Net_Versions.txt"
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
#  Write Header and computername
#
Write-Output "Computer - $SysName" | out-file -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
Write-Output "###############################################################################################" | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
Write-Output "PowerShell Version" | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
Write-Output "-----------------------------------------------------------------------------------------------" | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
#
#  Check PowerShell version if minimum version is met
#
$PSVersionTable.PSVersion | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
#
#  Check PS Logging
#
Write-Output "PS Logging should be - ModuleLogging = 1, EnableScriptBlockLogging = 1" | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
Write-Output "-----------------------------------------------------------------------------------------------" | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
#
Get-ItemProperty "hklm:SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -Name "EnableModuleLogging" | format-table -Autosize -Property @{Name="EnableModuleLogging"; Expression = {$_.EnableModuleLogging}; Alignment="left"} | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
Get-ItemProperty "hklm:SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockLogging" | format-table -Autosize -Property @{Name="EnableScriptBlockLogging"; Expression = {$_.EnableScriptBlockLogging}; Alignment="left"} | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
#
Write-Output "ModuleNames should be - ModuleNames = *" | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
Write-Output "-----------------------------------------------------------------------------------------------" | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
Get-Item -Path "hklm:SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames" | Select-Object -ExpandProperty Property | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
#
#  Check .Net versions
#
Write-Output "" | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
Write-Output ".Net Versions - Lists .Net versions installed" | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
Write-Output "-----------------------------------------------------------------------------------------------" | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
#
Get-ItemProperty "HKLM:Software\Microsoft\NET Framework Setup\NDP\*" | Select-Object PSChildName, PSPath | format-table -AutoSize -Wrap | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
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
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'PS and .Net version executed by Arthir'
 }
  else {
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'PS and .Net version executed by Arthir'
    }