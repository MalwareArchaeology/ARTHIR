<#
.SYNOPSIS
Get-LOG-MD_Settings_Audit.ps1 returns output from the Windows Advanced Audit Policy check.
It checks for a PASS or FAIL condition,

This will help you assess the Advanced Audit Policy settngs on the system you 
run this module on.

Use the following to record the modules applicability to the MITRE ATT&CK Framework

MITRE ATT&CK Technique IDs: TBD

This script does depend on IMF Security's LOG-MD.exe, which is not
packaged with ARTHIR. You will have to purchase and download it from LOG-MD.com and
drop it in the .\Modules\bin\ directory. When you run ARTHIR.ps1, if you
add the -Pushbin switch at the command line, ARTHIR.ps1 will attempt to 
copy the LOG-MD.exe binary to each remote target's ADMIN$ share (C:\Windows)
and then move it to the directory specified with $ARTHIR_Dir.

If you want to remove the binary and/or reports from remote systems after it has run
use the cleanup module(s) or specify with the $DeleteReports and $DeleteAll variables.

Adjust the variables to what you want to do with each item:
  $ARTHIR_Dir					Set to a directory you want the tool to be stored
  $ARTHIR_OutputDir 			Set to a directory you want the results of the modules to be stored for harvesting
  $ARTHIR_ReportName			What to name the report.  Match this to DOWNLOAD
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
 - Example:  C:\Program Files\LMD\Results\*Report_AutoRuns*

BINDEP .\Modules\bin\Log-MD.exe
DOWNLOAD C:\Program Files\LMD\Results\*Report_Audit_Score*
#>
$Tool_Name = "LOG-MD.exe"
$ARTHIR_Dir = "C:\Program Files\LMD"
$ARTHIR_OutputDir = "C:\Program Files\LMD\Results"
$ARTHIR_ReportName = "Report_Audit_Score.txt"
$RenameReports = "Yes"
$TextString = "Score = PASS"
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
#  Move uploaded tool to the destination directory from \Windows
#
Move-Item -Path "$env:SystemRoot\$Tool_Name" -Destination $ARTHIR_Dir -Force
#
#  Run LOG-MD
#
if (Test-Path $ARTHIR_Dir\$Tool_Name) {
    Set-Location -Path $ARTHIR_Dir
    & $ARTHIR_Dir\$Tool_Name -a > $ARTHIR_OutputDir\$ARTHIR_ReportName 
} else {
    Write-Error "$Tool_Name not found in $ARTHIR_Dir."
  }
#
#  Delete report if system passed 
#
if (Select-String -Path $ARTHIR_OutputDir\$ARTHIR_ReportName -Pattern $TextString) {
    Remove-Item -Path $ARTHIR_OutputDir\$ARTHIR_ReportName -force
} else {
    Write-Output "You Lose Fix Yur Shit"
  }
#
# Check for output to exist
#  
if (Test-Path $ARTHIR_OutputDir\$ARTHIR_ReportName) {
    & Write-Output "$Tool_Name Created $ARTHIR_ReportName" } 
    else {
    Write-Output "System must have passed the audit settings" }
#
#  Rename files with $SysName
#
If ($RenameReports -eq 'No') {
  Write-Output "Reports not being renamed"
  }  
  else {
    Remove-Item -path $ARTHIR_OutputDir\$SysName-Report_Configuration* -force
    Move-Item -Path Report_Configuration* -Destination $ARTHIR_OutputDir
    Get-ChildItem $ARTHIR_OutputDir\Report_Configuration* | Rename-Item -NewName { $_.name -Replace 'Report_Configuration*',"$SysName-Report_Configuration*" }  
}

#
#  Write log entry
#
If ($WriteEventLogEntry -eq 'No') {
  Break
  }  
  elseif ([System.Diagnostics.EventLog]::SourceExists($EventSource) -eq $False) {
    New-EventLog -LogName Application -Source $EventSource
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'LOG-MD AutoRuns executed by Arthir'
 }
  else {
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'LOG-MD AutoRuns executed by Arthir'
    }
