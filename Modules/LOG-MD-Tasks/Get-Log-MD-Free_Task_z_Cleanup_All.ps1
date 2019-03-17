<#
.SYNOPSIS
Get-Log-MD-Free_Task_z_Cleanup_All.ps1 deletes all LOG-MD Scheduled Tasks

Use the following to record the modules applicability to the MITRE ATT&CK Framework

MITRE ATT&CK Technique IDs: none

Scheduled Task:
---------------
This module will delete all LOG-MD scheduled tasks.

MITRE ATT&CK Technique IDs: none
 
Adjust the variables to what you want to do with each item:
  $Tool_Name					Name of the tool that you will use
  $ARTHIR_OutputDir 			Set to a directory you want the results of the modules to be stored for harvesting
  $ARTHIR_ReportName			What to name the report.  Match this to DOWNLOAD
  $TaskName						Name of the Task
  $TaskDescr					Description fo the Scheduled Task
  $TaskStartTime				When you want the task to start ("2018-03-03T14:55:00")
  $WriteEventLogEntry			Create an event log entry that this module ran 'Yes' or 'No'
  $EventSource					The name of the source the event will be written to the Application log (default is ARTHIR)
  $Event_ID						What event ID to use in the log entry
  
.NOTES
The following lines are required by ARTHIR.ps1. They are directives that
tell ARTHIR how to treat the output of this script and where to find the
binary that this script depends on.

DOWNLOAD C:\Program Files\LMD\Results\*Report_Task_Deleted.txt
#>
#  You must use the 8.3 directory name for logmdOutputDir for a Schedule Task If you use a folder with a space in it
#
#  Edit the following variables to match what names and locations you want to use to store LOG-MD 
#
# Where LOG-MD resides
$ARTHIR_Dir = "C:\Progra~1\LMD"
# Where the results/reports will be stored
$ARTHIR_OutputDir = "C:\Progra~1\LMD\Results"
# Name of report that contains task created successfully
$ARTHIR_ReportName = "Report_Task_Deleted.txt"
# Name of system to add to the report
$SysName = $env:computername
# Write a log entry to Application log
$WriteEventLogEntry = "Yes"
$EventSource = "ARTHIR"
$Event_ID = "1337"
#
#  Remove any existing $Tool_Name Task
#
	SchTasks.exe /Delete /TN "Test_LOG-MD-AutoRuns" /F | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
	SchTasks.exe /Delete /TN "Test_LOG-MD-Large-Keys" /F | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
	SchTasks.exe /Delete /TN "Test_LOG-MD_1-Day_of_Logs" /F | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
    SchTasks.exe /Delete /TN "Test_LOG-MD-Running-Processes" /F | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
#
#  Write log entry
#
If ($WriteEventLogEntry -eq 'No') {
  Break
  }  
  elseif ([System.Diagnostics.EventLog]::SourceExists($EventSource) -eq $False) {
    New-EventLog -LogName Application -Source $EventSource
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'Added Task WMI Persitence Daily by Arthir'
 }
  else {
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'Added Task WMI Persitence Daily by Arthir'
    }