<#
.SYNOPSIS
Get-Handle64.ps1 - Get handles of files.  Run Handle64 /? for all
features.  Using -i cannot create a CSV.

Use the following to record the modules applicability to the MITRE ATT&CK Framework

MITRE ATT&CK Technique IDs: TBD

Adjust the variables to what you want to do with each item:
  $Tool_Name					Name of the binary utility used
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

BINDEP .\Modules\bin\Handle64.exe
DOWNLOAD C:\Program Files\ARTHIR\*Report_Handle*
#>
$Tool_Name = "Handle64.exe"
$Check_Folder = "c:\users\*.*"
$ARTHIR_Dir = "C:\Program Files\ARTHIR"
$ARTHIR_OutputDir = "C:\Program Files\ARTHIR"
$ARTHIR_ReportName = "Report_Handle.txt"
$RenameReports = "Yes"
$SysName = $env:computername
$WriteEventLogEntry = "Yes"
$EventSource = "ARTHIR"
$Event_ID = "1337"
#
# Remove existing report
#
Remove-Item -path $ARTHIR_OutputDir\$SysName-Report_Handle* -force | Out-Null
Write-Output "Running Handle" | out-file -filepath $ARTHIR_OutputDir\$SysName-Report_Handle_Status.txt
#
#  Check for report folder existing, or create it
#
if (Test-Path $ARTHIR_OutputDir) {
    Write-Output "$ARTHIR_OutputDir already exists" | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-Report_Handle_Status.txt
 } else {
    new-item $ARTHIR_OutputDir -itemtype directory | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-Report_Handle_Status.txt
    }
#
#  Move uploaded tool to the destination directory from \Windows
#
Move-Item -Path "$env:SystemRoot\$Tool_Name" -Destination $ARTHIR_Dir -Force 
#
#  Check and run Handle
#
if (Test-Path $ARTHIR_Dir\$Tool_Name) {
    Set-Location -Path $ARTHIR_Dir 
    Write-Output "Process,   PID,   Owner,    Type,                      Perms,     Name" | Out-File -FilePath $ARTHIR_OutputDir\Report_Handle.txt
	Write-Output "------------------------------------------------------------------------------" | Out-File -Append -FilePath $ARTHIR_OutputDir\Report_Handle.txt
	$data = (& .\$Tool_Name /accepteula -a)
    #("Process","PId","Owner","Type","Perms","Name") -join $Delimiter
    foreach($line in $data) {
        $line = $line.Trim()
        if ($line -match " pid: ") {
            $HandleId = $Type = $Perms = $Name = $null
            $pattern = "(?<ProcessName>^[-a-zA-Z0-9_.]+) pid: (?<PId>\d+) (?<Owner>.+$)"
            if ($line -match $pattern) {
                $ProcessName,$ProcId,$Owner = ($matches['ProcessName'],$matches['PId'],$matches['Owner'])
            }
        } else {
            $pattern = "(?<HandleId>^[a-f0-9]+): (?<Type>\w+)"
            if ($line -match $pattern) {
                $HandleId,$Type = ($matches['HandleId'],$matches['Type'])
                $Perms = $Name = $null
                switch ($Type) {
                    "File" {
                        $pattern = "(?<HandleId>^[a-f0-9]+):\s+(?<Type>\w+)\s+(?<Perms>\([-RWD]+\))\s+(?<Name>.*)"
                        if ($line -match $pattern) {
                            $Perms,$Name = ($matches['Perms'],$matches['Name'])
                        }
                    }
                    default {
                        $pattern = "(?<HandleId>^[a-f0-9]+):\s+(?<Type>\w+)\s+(?<Name>.*)"
                        if ($line -match $pattern) {
                            $Name = ($matches['Name'])
                        }
                    }
                }
                if ($Name -ne $null) {
                    $o = "" | Select-Object ProcessName, ProcId, HandleId, Owner, Type, Perms, Name
                    $o.ProcessName, $o.ProcId, $o.HandleId, $o.Owner, $o.Type, $o.Perms, $o.name = `
                        $ProcessName,$ProcId,("0x" + $HandleId),$Owner,$Type,$Perms,$Name
                    ($o | Format-Table -Wrap -Autosize -HideTableHeaders | Out-String).Trim() | Out-File -Append -FilePath $ARTHIR_OutputDir\Report_Handle.txt

                }
            }
        }
    }

  } else {
    Write-Error "$Tool_Name not found in $env:SystemRoot." 
    Exit
  }
#
# Check for output to exist
#  
Write-Output "Waiting for Handle report to be created..." | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-Report_Handle_Status.txt
  while (!(Test-Path $ARTHIR_OutputDir\$ARTHIR_ReportName)) { Start-Sleep 10 | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-Report_Handle_Status.txt }
#
#  Wait 5 seconds to allow closing of files
#
   Start-Sleep -s 5
#
#  Rename files with $SysName
#
If ($RenameReports -eq 'No') {
  Write-Output "Reports not being renamed" | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-Report_Handle_Status.txt
  }  
  else {
    Rename-Item $ARTHIR_ReportName -NewName $SysName-$ARTHIR_ReportName | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-Report_Handle_Status.txt
}
#
#  Write log entry
#
If ($WriteEventLogEntry -eq 'No') {
  Break
  }  
  elseif ([System.Diagnostics.EventLog]::SourceExists($EventSource) -eq $False) {
    New-EventLog -LogName Application -Source $EventSource
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'Handle executed by Arthir'
 }
  else {
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'Handle executed by Arthir'
    }
Write-Output "Running Handle complete" | out-file -Append -filepath $ARTHIR_OutputDir\$SysName-Report_Handle_Status.txt
