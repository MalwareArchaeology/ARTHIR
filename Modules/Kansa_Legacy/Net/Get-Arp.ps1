<#
.SYNOPSIS
Get-Arp.ps1 - This will list the Arp table.
 - Looks for 

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

DOWNLOAD C:\Program Files\ARTHIR\*Report_ARP.txt
#>
$ARTHIR_OutputDir = "C:\Program Files\ARTHIR"
$ARTHIR_ReportName = "Report_ARP.txt"
$SysName = $env:computername
# Create event in Application log
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
#  List the ARP table
#
Write-Output "List ARP table on - $SysName" | Out-File -FilePath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
Write-Output "-------------------------------------------------------" | Out-File -Append -FilePath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
if (Get-Command Get-NetNeighbor -ErrorAction SilentlyContinue) {
    Get-NetNeighbor | Out-File -Append -FilePath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
} else {
Invoke-Command {
 Arp -av | where {$_ -AND $_ -notmatch "command completed successfully"} |
  Select -Skip 0 | Out-File -Append -FilePath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
 }
}
#
#  Write log entry
#
If ($WriteEventLogEntry -eq 'No') {
  Break
  }  
  elseif ([System.Diagnostics.EventLog]::SourceExists($EventSource) -eq $False) {
    New-EventLog -LogName Application -Source $EventSource
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'Local Admin Accounts queried by Arthir'
 }
  else {
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'Local Admin Accounts queried by Arthir'
    }
