<#
.SYNOPSIS
Get-Delete_ARTHIR_Folders.ps1 deletes the folder created by your scripts.  Just add the folder(s)
you want to delete below to cleanup after your modules.  Add multiple folders if you use them.
The DOWNLOAD directive is not used in this module unless you want to create a status report.

Adjust the variables to what you want to do with each item:
  $ARTHIR_OutputDir 			Set to a directory you want the results of the modules to be removed
  $WriteEventLogEntry			Create an event log entry that this module ran 'Yes' or 'No'
  $EventSource					The name of the source the event will be written to the Application log (default is ARTHIR)
  $Event_ID						What event ID to use in the log entry
  
  
.NOTES
The following DIRECTIVE lines are needed by ARTHIR.ps1 to determine how to handle output
from this script.
#>
$ARTHIR_OutputDir = "C:\Program Files\ARTHIR"
$WriteEventLogEntry = "Yes"
$EventSource = "ARTHIR"
$Event_ID = "1337"
#
#  Check and delete the folder specified above.  Add more entries if you are using multiple folders
#
if (Test-Path $ARTHIR_OutputDir) {
    Remove-Item -path $ARTHIR_OutputDir -recurse
} else {
    Write-Error "ARTHIR folder not found at" $ARTHIR_OutputDir
}
#
#  Write log entry
#
If ($WriteEventLogEntry -eq 'No') {
  Break
  }  
  elseif ([System.Diagnostics.EventLog]::SourceExists($EventSource) -eq $False) {
    New-EventLog -LogName Application -Source $EventSource
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'ARTHIR folder deleted'
 }
  else {
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'ARTHIR folder deleted'
    }