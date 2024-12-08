# ARTHIR
ATT&amp;CK Remote Threat Hunting Incident Response

VERSION
-------
Initial release ver 1.0 - Mar 2019

BACKGROUND
----------
WHAT IS ARTHIR?

ATT&CK Remote Threat Hunting Incident Response (ARTHIR) is an update to the popular KANSA framework. ARTHIR works differently than KANSA in that you can create output with your ARTHIR module and then the results are pulled back to the launching host. KANSA only pulled console output back which limited its capabilities. KANSA was unable to execute binary utilities and tools such as LOGMD remotely and pull reports back. ARTHIR can run scripts as KANSA does, but also binary utilities and
tools, making ARTHIR much more flexible than KANSA.

KANSA is a modular incident response framework in Powershell to remotely run various PowerShell commands on a remote system to investigate a suspect system. The KANSA project is no longer maintained by the creator Dave Hull, but is still used and updated by some users. 

ARTHIR was created to provide a solution that can push out, run, and pull back LOG-MD-Pro reports, (or any other tool, script or binary you might like to use) while doing investigations. The ARTHIR project is a free Open Source project on Github and may be found here;
 - https://github.com/MalwareArchaeology/ARTHIR
 
Templates have been provided for scripts, binary utilities and tools, tasks, and Zip archives so that you
may use it and create your own solutions.

WHY ARTHIR?

ARTHIR provides a modular approach that allows users to run existing PowerShell modules included with ARTHIR, create their own, or as in our case push, run, and retrieve LOG-MD-Pro and retrieve the reports.  The modular nature of ARTHIR allows you to run a single module (aka PowerShell script), push and run a binary, execute one or many modules using the modules.conf file. For our purposes modifications to the core KANSA script was required and the changes extensive. We have provided modules that allows
you to run all the features of LOG-MD-Pro and retrieve the results.

Running ARTHIR
--------------

Edit Modules.conf adjust it to what you want to run.  Read each module and what it does should be recorded 
in the beginning of the module.

Keep in mind some modules that take longer than others to run, do them last.  modules are ordered by how 
long they take in modules.conf.

Populate the systems you want to run the modules against in the 'Hosts.txt' file.

Pushing a binary or Zip file, be sure to include the '-Pushbin' parameter or you wil get an error.

The '-Transcribe' and '-Verbose' options are optional, they just provide the console launch details in a log file.

Read the "Configuring WinRM Guide.pdf" for more on enabling WinRM

#############################################################################################

Launch all modules enabled in modules.conf \Modules
---------------------------------------------------

To cache your credentials
-------------------------
$Credential = Get-Credential <your username>

-------------------------------
For Domain attached systems:  |
-------------------------------
The following uses Kerberos to authenticate which is the default for domains.

Run all modules selected in Modules.conf
----------------------------------------

 - With a binary or Zip to push
.\ARTHIR.ps1 -TargetList hosts.txt .\Modules -Pushbin -Verbose -Transcribe -Credential $Credential

 - With just scripts, no binary or zip
.\ARTHIR.ps1 -TargetList Hosts.txt .\Modules -Verbose -Transcribe -Credential <username>

 - Specify one target and a username - with a binary or zip to push
.\ARTHIR.ps1 -Target <computername> .\Modules -Pushbin -Verbose -Transcribe -Credential <username>

Launch one module at a time
---------------------------

 - With a binary or Zip to push
.\ARTHIR.ps1 -Target <computername> -ModulePath ".\Modules\LOG-MD\Get_Log-MD_1_Configs.ps1" -Pushbin -Transcribe -Credential $Credential
.\ARTHIR.ps1 -Target <computername> -ModulePath ".\Modules\LOG-MD\Get-Log-MD_AutoRuns.ps1" -Pushbin -Transcribe -Credential <username>

.\ARTHIR.ps1 -Target DEFENDER -ModulePath ".\Modules\LOG-MD\Get-LOG-MD-1_Configs.ps1" -Pushbin -Transcribe -Credential <username>

#############################################################################################

-----------------------------------
For Non-Domain attached systems:  |
-----------------------------------

Run all modules selected in Modules.conf
----------------------------------------

.\ARTHIR.ps1 -TargetList hosts.txt .\Modules -Verbose -Authentication Negotiate -Transcribe -Credential $Credential
 - With a binary or Zip to push
.\ARTHIR.ps1 -TargetList hosts.txt .\Modules -Pushbin -Authentication Negotiate -Verbose -Transcribe -Credential $Credential

 - With just scripts, no binary or zip
.\ARTHIR.ps1 -TargetList Hosts.txt .\Modules -Authentication Negotiate -Verbose -Transcribe -Credential <username>

 - Specify one target and a username - with a binary or zip to push
.\ARTHIR.ps1 -Target <computername> .\Modules -Pushbin -Authentication Negotiate -Verbose -Transcribe -Credential <username>

Launch one module at a time
---------------------------

 - With a binary or Zip to push
.\ARTHIR.ps1 -Target <computername> -ModulePath ".\Modules\LOG-MD\Get_Log-MD_1_Configs.ps1" -Pushbin -Authentication Negotiate -Transcribe -Credential $Credential
.\ARTHIR.ps1 -Target <computername> -ModulePath ".\Modules\LOG-MD\Get-Log-MD_AutoRuns.ps1" -Pushbin -Authentication Negotiate -Transcribe -Credential <username>

.\ARTHIR.ps1 -Target DEFENDER -ModulePath ".\Modules\LOG-MD\Get-LOG-MD-1_Configs.ps1" -Pushbin -Authentication Negotiate -Transcribe -Credential <username>

#############################################################################################

TROUBLESHOOTING
---------------

----------------------------
To open a PS Remoting shell
----------------------------

This will give you console access to the remote system to do whatever you want, but NOT retrieve files, this requires the next option "PS Remoting Session".

$Credential = Get-Credential <your username>

 - Domain
Enter-PSSession <computername> -Credential $Credential
Enter-PSSession <computername> -Credential <username>

 - Non domain
Enter-PSSession <computername> -Authentication Negotiate -Credential $Credential
Enter-PSSession <computername> -Authentication Negotiate -Credential <username>

Do whatever you want and then when done;
 - Exit-PSSession

--------------------------------------
To open a PS Remoting Session method 2
--------------------------------------

This will give you an interactive session that allows you to run commands and retrieve and send files to the target.

$Credential = Get-Credential <your username>

 - Non domain
$MySession = New-PSSession -ComputerName <computername> -Authentication Negotiate -Credential $Credential
$MySession = New-PSSession -ComputerName <computername> -Authentication Negotiate -Credential <username>
Invoke-Command -Session $MySession {Get-Process}
Invoke-Command -Session $MySession {C:\'Program Files'\LMD\Log-MD-Pro.exe -ar -md -o 'C:\Program Files\LMD\Results'}
Copy-Item -Path "C:\Program Files\LMD\Results\Report_AutoRuns*" -Destination "D:\ARTHIR" -FromSession $MySession

Do whatever you want and then when done;
 - Exit-PSSession
 
#############################################################################################
