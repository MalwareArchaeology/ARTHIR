Get-ADComputer -Filter { OperatingSystem -Like '*MAC*' } -Properties OperatingSystem, LastLogonTimestamp | Select Name, OperatingSystem, LastLogonTimestamp | Export-Csv -Path "MAC_Systems.csv"
