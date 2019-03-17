<#
.SYNOPSIS
Get-Anti-MW-InfectionStatus.ps1 - This returns any Windows Defender infections (Win 10, WIn 2016 and later).
Originally Contributed by Mike Fanning for Kansa
 - Shows configuration information for the Windows Defender 

Use the following to record the modules applicability to the MITRE ATT&CK Framework

MITRE ATT&CK Technique IDs: TBD
 
Adjust the variables to what you want to do with each item:
  $ARTHIR_OutputDir 			Set to a directory you want the results of the modules to be stored for harvesting
  $ARTHIR_ReportName			What to name the report used for error checking.  Match this to DOWNLOAD
  $SysName						What you want each report to be pre-pended with such as "computername"
  $WriteEventLogEntry			Create an event log entry that this module ran 'Yes' or 'No'
  $EventSource					The name of the source the event will be written to the Application log (default is ARTHIR)
  $Event_ID						What event ID to use in the log entry
  
  DOWNLOAD						The name of the report you will copy back to the host or launching system, wildcards are acceptable

.NOTES
The DOWNLOAD directive is needed by ARTHIR.ps1 to determine where how to handle
output from this script.  Use the wildcard * to capture the systemname in the report.
 - Example:  C:\Program Files\LMD\Results\*Report_PS_LOG-MD-API-Settings.txt

DOWNLOAD C:\Program Files\ARTHIR\*Report_Anti-MW-Infection-Status.txt
#>
$ARTHIR_OutputDir = "C:\Program Files\ARTHIR"
$ARTHIR_ReportName = "Report_Anti-MW-Infection-Status.txt"
$SysName = $env:computername
$WriteEventLogEntry = "Yes"
$EventSource = "ARTHIR"
$Event_ID = "1337"
#
#  Check if system is a supported OS (Win10, Server 2016, Server 2019)
#
#  Get OS details
#
$OS_Version = Get-CimInstance Win32_Operatingsystem | select -expand Caption
#
If (($OS_Version -like "* Windows 10 *") -or ($OS_Version -like "* Server 2016 *") -or ($OS_Version -like "* Server 2019 *")) {
       Write-Output "Yup correct Windows"
   } else {
        Write-Error "Incorrect version of Windows, no Defender WMI Class" 
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
#  Check Windows Anti-Malware Infection Status
#
Write-Output "Windows Anti-Malware Infection Status" | out-file -Filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName 
Write-Output "-------------------------------------------------------------------------" | out-file -Append -Filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName 
Get-WmiObject -Namespace root\Microsoft\SecurityClient -Class AntimalwareInfectionStatus | format-list | out-file -Append -Filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName 
#
#  Write log entry
#
If ($WriteEventLogEntry -eq 'No') {
  Break
  }  
  elseif ([System.Diagnostics.EventLog]::SourceExists($EventSource) -eq $False) {
    New-EventLog -LogName Application -Source $EventSource
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'Windows Anti-Malware Infection Statuss queried by Arthir'
 }
  else {
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'Windows Anti-Malware Infection Status queried by Arthir'
    }
