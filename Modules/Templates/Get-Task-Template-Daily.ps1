<#
.SYNOPSIS
Get-Task-Template-Daily.ps1 This template creates an Daily task.
  - Runs Whatever.exe and places output in $ARTHIR_OutputDir

Use the following to record the modules applicability to the MITRE ATT&CK Framework

MITRE ATT&CK Technique IDs: TBD  
  
Scheduled Task:
---------------
This module will create a schedule task at the date and time you want it to begin
and then each hour, every day it will run placing the Report files into the
output folder you specify below.

CLEANUP:
--------
Use a cleanup module "Get-Whatever_Cleanup_Tasks_All.ps1" to remove all
the scheduled tasks that you specify in that module.
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

BINDEP .\Modules\bin\Whatever.exe
DOWNLOAD C:\Program Files\Wherever\Results\*Report_Task_Created.txt
#>
#  You must use the 8.3 directory name for logmdOutputDir for a Schedule Task If you use a folder with a space in it
#
#  Edit the following variables to match what names and locations you want to use to store LOG-MD 
#
# Tool Name
$Tool_Name = "Whatever.exe"
# Where LOG-MD resides
$ARTHIR_Dir = "C:\Progra~1\Wherever"
# Where the results/reports will be stored
$ARTHIR_OutputDir = "C:\Progra~1\Wherever\Results"
# Name of report that contains task created successfully
$ARTHIR_ReportName = "Report_Task_Created.txt"
# Name of system to add to the report
$SysName = $env:computername
# The name of the scheduled task
$TaskName = "My Kewl Daily Task"
# Description of the scheduled task
$TaskDescr = "Create a Daily Check for Something Task"
# The date and time you want the task to start to run each day and hour (e.g 2pm or 14:00:00) 
$TaskStartTime = "2019-03-03T14:15:00"
# Name of Tool used
$TaskCommand = "$Tool_Name"
# The Task Action command argument
$TaskArg = "Tools arguments -o $ARTHIR_OutputDir"
# Write a log entry to Application log
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
#  Remove any existing $Tool_Name Task
#
    SchTasks.exe /Delete /TN \$TaskName /F 
#
# Create Schedule Task to run Something
#
# attach the Task Scheduler com object
$service = new-object -ComObject("Schedule.Service")
$service.Connect()
$rootFolder = $service.GetFolder("\")
 
$TaskDefinition = $service.NewTask(0) 
$TaskDefinition.RegistrationInfo.Description = "$TaskDescr"
$TaskDefinition.Settings.Enabled = $true
$TaskDefinition.Settings.AllowDemandStart = $true
$TaskDefinition.Principal.RunLevel = 1
$TaskDefinition.Settings.ExecutionTimeLimit = 'PT1H'
 
$triggers = $TaskDefinition.Triggers

$trigger = $triggers.Create(2) 
#$trigger.repetition.Interval = 'PT60M'
$trigger.StartBoundary = $TaskStartTime
$trigger.Enabled = $true
$trigger.ExecutionTimeLimit = 'PT1H'
 
$Action = $TaskDefinition.Actions.Create(0)
$action.Path = "$TaskCommand"
$action.Arguments = "$TaskArg"
$action.WorkingDirectory = $ARTHIR_Dir
 
$rootFolder.RegisterTaskDefinition("$TaskName",$TaskDefinition,6,"System",$null,5)
#
# Move $Tool_Name to directory 
#
  Move-Item -Path "$env:SystemRoot\$Tool_Name" -Destination $ARTHIR_Dir -Force
#
# Printout Task completed
#
  Schtasks /query /FO TABLE /TN $TaskName | out-file -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
#
#  Write log entry
#
If ($WriteEventLogEntry -eq 'No') {
  Break
  }  
  elseif ([System.Diagnostics.EventLog]::SourceExists($EventSource) -eq $False) {
    New-EventLog -LogName Application -Source $EventSource
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'Added Task Large Reg Keys Daily by Arthir'
 }
  else {
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'Added Task Large Reg Keys Daily by Arthir'
    }