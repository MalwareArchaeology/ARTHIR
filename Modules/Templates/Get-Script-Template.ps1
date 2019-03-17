<#
.SYNOPSIS
Get-Script-Template.ps1 - This is a template for a PowerShell script.
 - Looks for X
 - Looks for Y

Use the following to record the modules applicability to the MITRE ATT&CK Framework

MITRE ATT&CK Technique IDs: TBD
 
Adjust the variables to what you want to do with each item:
  $ARTHIR_Dir					Set to a directory you want the results of the modules to be stored for harvesting
  $ARTHIR_OutputDir 			Set to a directory you want the results of the modules to be stored for harvesting
  $ARTHIR_ReportName			What to name the report used for error checking.  Match this to DOWNLOAD
  $RenameReports 				Yes/No - Rename the reports to include the systemname or what you specify with $SysName variable
  $SysName						What you want each report to be pre-pended with such as "computername"
  $WriteEventLogEntry			Create an event log entry that this module ran 'Yes' or 'No'
  $EventSource					The name of the source the event will be written to the Application log (default is ARTHIR)
  $Event_ID						What event ID to use in the log entry
  
  DOWNLOAD						The name of the report you will copy back to the host or launching system, wildcards are acceptable

.NOTES
The DOWNLOAD directive is needed by ARTHIR.ps1 to determine where how to handle
output from this script.  Use the wildcard * to capture the systemname in the report.
 - Example:  C:\Program Files\LMD\Results\*Report_PS_LOG-MD-API-Settings.txt

DOWNLOAD <path>\*<report name(s) you want to collect>
#>
$ARTHIR_OutputDir = "<Directory you want to Store output>"
$ARTHIR_ReportName = "<Name of the report MATCH DOWNLOAD DIRECTIVE above>"
$SysName = $env:computername
$MinPSVersion = 6
$WriteEventLogEntry = "No"
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
#  Check Key XYZ for ...
#
Get-ItemProperty HKLM:SomeKey* | Select-Object Value1, Value2, Value3 | format-table -AutoSize -Wrap | out-file -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName 

#
#  Write log entry
#
If ($WriteEventLogEntry -eq 'No') {
  Break
  }  
  elseif ([System.Diagnostics.EventLog]::SourceExists($EventSource) -eq $False) {
    New-EventLog -LogName Application -Source $EventSource
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'XXXX Settings queried by Arthir'
 }
  else {
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'XXXX Settings queried by Arthir'
    }
