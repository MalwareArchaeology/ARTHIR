<#
.SYNOPSIS
Get-Log-MD_Running_Processes_Hourly_Task.ps1 creates an hourly task to run LOG-MD Running Processes feature.
  - Runs LOG-MD -proc -o $ARTHIR_OutputDir

Use the following to record the modules applicability to the MITRE ATT&CK Framework

MITRE ATT&CK Technique IDs:
  
This script does depend on IMF Security's LOG-MD.exe, which is not
packaged with ARTHIR. You will have to purchase and download it from LOG-MD.com and
drop it in the .\Modules\bin\ directory. When you run ARTHIR.ps1, if you
add the -Pushbin switch at the command line, ARTHIR.ps1 will attempt to 
copy the LOG-MD.exe binary to each remote target's ADMIN$ share and then move it
to the folder you specify below.

Scheduled Task:
---------------
This module will create a schedule task at the date and time you want it to begin
and then each hour, every day it will run placing the Report files into the
output folder you specify below.

CLEANUP:
--------
Use the cleanup module "Get-Log-MD-Pro_z_Cleanup_Tasks_All.ps1" to remove all
the LOG-MD scheduled tasks that you specify in that module.

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

BINDEP .\Modules\bin\Log-MD.exe
DOWNLOAD C:\Program Files\LMD\Results\*Report_Task_Created.txt
#>
#  You must use the 8.3 directory name for logmdOutputDir for a Schedule Task If you use a folder with a space in it
#
#  Edit the following variables to match what names and locations you want to use to store LOG-MD 
#
# Tool Name
$Tool_Name = "LOG-MD.exe"
# Where LOG-MD resides
$ARTHIR_Dir = "C:\Progra~1\LMD"
# Where the results/reports will be stored
$ARTHIR_OutputDir = "C:\Progra~1\LMD\Results"
# Name of report that contains task created successfully
$ARTHIR_ReportName = "Report_Task_Created.txt"
# Name of system to add to the report
$SysName = $env:computername
# The name of the scheduled task
$TaskName = "Test_LOG-MD-Running-Processes Hourly"
# Description of the scheduled task
$TaskDescr = "Create a LOG-MD Hourly Check for Running Processes Task"
# The date and time you want the task to start to run each day and hour (e.g 2pm or 14:00:00) 
$TaskStartTime = "2019-03-03T14:15:00"
# Name of Tool used
$TaskCommand = "$Tool_Name"
# The Task Action command argument
$TaskArg = "-proc"
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
$schedule = new-object -com("Schedule.Service") 
$schedule.connect() 
$tasks = $schedule.getfolder("\").gettasks(0)
$tasks | select Name | ? { $_.Name -eq $TaskName }
#
if ($tasks | select Name | ? { $_.Name -eq $TaskName }) {
    SchTasks.exe /Delete /TN $TaskName /F | out-file -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
 } else {
    Write-Output $TaskName "$TaskName does not already exist on the system" | out-file -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
}
#
# Create Schedule Task to run Hourly Running Processes
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
$trigger.repetition.Interval = 'PT60M'
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
  Schtasks /query /FO TABLE /TN $TaskName | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
#
#  Write log entry
#
If ($WriteEventLogEntry -eq 'No') {
  Break
  }  
  elseif ([System.Diagnostics.EventLog]::SourceExists($EventSource) -eq $False) {
    New-EventLog -LogName Application -Source $EventSource
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'Added Task Running Processes Hourly by Arthir'
 }
  else {
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'Added Task Running Processes Hourly by Arthir'
    }