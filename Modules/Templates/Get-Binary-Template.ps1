<#
.SYNOPSIS
Get-Binary-Template.ps1 - This is a template for a Binary utility or tool.
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
  
  BINDEP						The name of the binary/file you want to push to the remote systems
  DOWNLOAD						The name of the report you will copy back to the host or launching system, wildcards are acceptable

.NOTES
The BINDEP and DOWNLOAD directives are needed by ARTHIR.ps1 to determine where to find 
the binary to be used and how to handle output from this script.  
Use the wildcard * to capture the systemname in the report.
 - Example:  .\Modules\bin\<your binary>.exe
 - Example:  C:\Program Files\LMD\Results\*Report_PS_LOG-MD-API-Settings.txt

BINDEP .\Modules\bin\<your binary>.exe
DOWNLOAD <Name of the report to download MATCH ARTHIR ReportName below>
#>
$Tool_Name = "<your tool name>"
$ARTHIR_Dir = "<folder where you want your tool to live>"
$ARTHIR_OutputDir = "<folder where you want your tool reports to be>"
$ARTHIR_ReportName = "<name of report to look for when completed error checking>"
$RenameReports = "Yes"
$SysName = $env:computername
$MinPSVersion = 6
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
#  Move uploaded tool to the destination directory from \Windows
#
Move-Item -Path "$env:SystemRoot\$Tool_Name" -Destination $ARTHIR_Dir -Force
#
#  Run Tool XYZ
#
if (Test-Path $ARTHIR_Dir\$Tool_Name) {
    Set-Location -Path $ARTHIR_Dir
    & $ARTHIR_Dir\$Tool_Name <your parameters> $ARTHIR_OutputDir 
 } else {
    Write-Error "$Tool_Name not found in $env:SystemRoot."
  Exit
  }
#
# Check for output to exist
#  
if (Test-Path $ARTHIR_OutputDir\$ARTHIR_ReportName) {
    & Write-Output "$Tool_Name Created $ARTHIR_ReportName" } 
	else {
    Write-Error "$Tool_Name failed to create $ARTHIR_ReportName" }
#
#  Rename files with $SysName
#
If ($RenameReports -eq 'No') {
  Write-Output "Reports not being renamed"
  }  
  else {
    Remove-Item -path $ARTHIR_OutputDir\$SysName-Report_AutoRuns* -force
    Get-ChildItem $ARTHIR_OutputDir\Report_AutoRuns* | Rename-Item -NewName { $_.name -Replace '<Beginning of your report name>',"$SysName-<Beginning of your report name>" }  
}
#
#  Write log entry
#
If ($WriteEventLogEntry -eq 'No') {
  Break
  }  
  elseif ([System.Diagnostics.EventLog]::SourceExists($EventSource) -eq $False) {
    New-EventLog -LogName Application -Source $EventSource
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message '<your message> by Arthir'
 }
  else {
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message '<your message> by Arthir'
    }
