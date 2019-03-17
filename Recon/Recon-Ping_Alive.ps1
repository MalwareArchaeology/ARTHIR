<#
.SYNOPSIS
Get-System_Info.ps1 needs the RSAT tools to be installed on the host running this module to access Active Directory.  
This module returns the following data about the system from a list of computers in "systems.txt".
  * Computername
  * Operating System

  RSAT can be obtained here:
    Win10 - https://www.microsoft.com/en-us/download/details.aspx?id=45520
    Win 7 - https://www.microsoft.com/en-us/download/details.aspx?id=7887
  
Adjust the variables to what you want to do with each item:
  $ARTHIR_OutputDir 			Set to a directory you want the results of the modules to be stored for harvesting
  $ARTHIR_ReportName			What to name the report.  Match this to DOWNLOAD
  $SysName						What you want each report to be pre-pended wiht like "computername"
  $MinPSVersion					What minimum PowerShell veersion do you want to look for
  $WriteEventLogEntry			Create an event log entry that this module ran 'Yes' or 'No'
  $EventSource					The name of the source the event will be written to the Application log (default is ARTHIR)
  $Event_ID						What event ID to use in the log entry
  
  DOWNLOAD						The name of the report you will copy back to the host or launching system, wildcards are acceptable
  
.NOTES
The following DIRECTIVE lines are needed by ARTHIR.ps1 to determine how to handle output
from this script.

DOWNLOAD C:\Program Files\ARTHIR\Results\*Report_System_Info.txt

#>

$ARTHIR_OutputDir = "D:\ARTHIR\Recon"
$ARTHIR_ReportName1 = "Report_Ping_Alive.txt"
$ARTHIR_ReportName2 = "Report_Ping_Offline.txt"
$WriteEventLogEntry = "No"
$EventSource = "ARTHIR"
$Event_ID = "1337"
#
#  Get system ONLINE information
#
$ComputerName = Get-Content "..\hosts.txt"  
  
foreach ($System in $ComputerName) {  
  
        if (test-Connection -ComputerName $System -Count 2 -Quiet ) {   
          
            "$System, is online " | out-file -Append -filepath $ARTHIR_OutputDir\$ARTHIR_ReportName1
          
                    } else  
                      
                    {"$System, not online" | out-file -Append -filepath $ARTHIR_OutputDir\$ARTHIR_ReportName2
              
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
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'System info gathered by Arthir'
 }
  else {
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'System info gathered by Arthir'
    }