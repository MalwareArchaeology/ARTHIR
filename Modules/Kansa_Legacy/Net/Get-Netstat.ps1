<#
.SYNOPSIS
#
# Initially obtained from Kansa, modified for error handling and formatting
#
#  Updated for ARTHIR
#
Get-Netstat.ps1 acquires netstat -naob output and reformats on the 
target as tsv output.
 
MITRE ATT&CK Technique IDs: T1043 (Commonly used ports), T1133 (External Remote Services), T1057 (Process Discovery), 
                            T1219 (Remote Acess Tools), T1018 (Remote System Discovery), T1016 (System Network Configuration Discovery),
							T1049 (System Network Connections Discovery)
 
CLEANUP:  If you want to remove the reports and directories from remote systems after it has run
use the cleanup module Get-Delete_ARTHIR_Folders.ps1. 

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

DOWNLOAD C:\Program Files\ARTHIR\Results\*Report_Netstat_Info.txt
#>
$ARTHIR_Dir = "C:\Program Files\ARTHIR"
$ARTHIR_OutputDir = "C:\Program Files\ARTHIR\Results"
$ARTHIR_ReportName = "Report_NetStat_Info.txt"
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
#  Netstat functions
#
function Get-AddrPort {
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$AddrPort
)
    Write-Verbose "Entering $($MyInvocation.MyCommand)"
    Write-Verbose "Processing $AddrPort"
    if ($AddrPort -match '[0-9a-f]*:[0-9a-f]*:[0-9a-f%]*\]:[0-9]+') {
        $Addr, $Port = $AddrPort -split "]:"
        $Addr += "]"
    } else {
        $Addr, $Port = $AddrPort -split ":"
    }
    $Addr, $Port
    Write-Verbose "Exiting $($MyInvocation.MyCommand)"
}

$netstat = if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # If run as admin, collect Component and Process names in addition to other data.
        $netstatScriptBlock = { & $env:windir\system32\netstat.exe -naob }
        foreach($line in $(& $netstatScriptBlock)) {
            if ($line.length -gt 1 -and $line -notmatch "Active |Proto ") {
                $line = $line.trim()
                if ($line.StartsWith("TCP")) {
                    $Protocol, $LocalAddress, $ForeignAddress, $State, $ConPId = ($line -split '\s{2,}')
                    $Component = $Process = $False
                } elseif ($line.StartsWith("UDP")) { 
                    $State = "STATELESS"
                    $Protocol, $LocalAddress, $ForeignAddress, $ConPid = ($line -split '\s{2,}')
                    $Component = $Process = $False
                } elseif ($line -match "^\[[-_a-zA-Z0-9.]+\.(exe|com|ps1)\]$") {
                    $Process = $line
                    if ($Component -eq $False) {
                        # No Component given
                        $Component = $Process
                    }
                } elseif ($line -match "Ownership unavailable") {
                    $Process = $Component = $line
                } else {
                    # We have the $Component
                    $Component = $line
                }
                if ($State -match "TIME_WAIT") {
                    $Component = "Not provided"
                    $Process = "Not provided"
                }
                if ($Component -and $Process) {
                    $LocalAddress, $LocalPort = Get-AddrPort($LocalAddress)
                    $ForeignAddress, $ForeignPort = Get-AddrPort($ForeignAddress)

                    $o = "" | Select-Object Protocol, LocalAddress, LocalPort, ForeignAddress, ForeignPort, State, ConPId, Component, Process
                    $o.Protocol, $o.LocalAddress, $o.LocalPort, $o.ForeignAddress, $o.ForeignPort, $o.State, $o.ConPId, $o.Component, $o.Process = `
                        $Protocol, $LocalAddress, $LocalPort, $ForeignAddress, $ForeignPort, $State, $ConPid, $Component, $Process
                    $o
                }
            }
        }
    } else {
    # If run as non-admin, we can't grab Component and Process name.
        $netstatScriptBlock = { & $env:windir\system32\netstat.exe -nao }
        ("Protocol","LocalAddress","LocalPort","ForeignAddress","ForeignPort","State","PId") -join "`t"
        foreach($line in $(& $netstatScriptBlock)) {
            if ($line.length -gt 1 -and $line -notmatch "Active |Proto ") {
                $line = $line.trim()
                if ($line.StartsWith("TCP")) {
                    $Protocol, $LocalAddress, $ForeignAddress, $State, $ConPId = ($line -split '\s{2,}')
                } elseif ($line.StartsWith("UDP")) {
                    $State = "STATELESS"
                    $Protocol, $LocalAddress, $ForeignAddress, $ConPId = ($line -split '\s{2,}')
                }
                $LocalAddress, $LocalPort = Get-AddrPort($LocalAddress)
                $ForeignAddress, $ForeignPort = Get-AddrPort($ForeignAddress)
                $o = "" | Select-Object Protocol, LocalAddress, LocalPort, ForeignAddress, ForeignPort, State, PId
                $o.Protocol, $o.LocalAddress, $o.LocalPort, $o.ForeignAddress, $o.ForeignPort, $o.State, $o.PId = `
                    $Protocol, $LocalAddress, $LocalPort, $ForeignAddress, $ForeignPort, $State, $Pid
                $o
            }
        }
    }
#
#  Get Netstat info 
#
$netstat | Format-Table -Wrap -AutoSize | out-file -filepath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
#
#  Write log entry
#
If ($WriteEventLogEntry -eq 'No') {
  Break
  }  
  elseif ([System.Diagnostics.EventLog]::SourceExists($EventSource) -eq $False) {
    New-EventLog -LogName Application -Source $EventSource
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'Netstat info gathered by Arthir'
 }
  else {
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'Netstat info gathered by Arthir'
    }