<#
.SYNOPSIS
Check Windows Server to see if it has Windows Updates required for Nimble Windows Toolkit.

.DESCRIPTION
This script will compare a list of KB numbers to what is installed on the server and tell you what is installed and what is missing.
The script prompts for the version of the server so different lists of required updates can be provided.
The list of updates will need to be created/reviewed with each update to the Nimble Windows Toolkit - refer to the NWT Release notes.

.NOTES
Special thanks to Topaz Paul for writing the Get-MSHotfix function.
The function is available here: https://gallery.technet.microsoft.com/scriptcenter/PowerShell-script-to-list-0955fe87
The Hotfix list should be a text file containing the KB IDs of all the required updates.  Each id should be listed like "KB2957560" on its own line.
I have not added additional OS versions, yet, feel free to add them to the top of the script.

Source: 
Author: Clint McGuire
Version 1.0
Copyrigth 2015
.LINK


.EXAMPLES


#>






#Determin Windows version to establish correct list of udpates to check

$WinVersion = read-host 'For Windows 2008 R2 press 1, for ... '
If ($WinVersion -eq 1)
{
    $WinUpdateFile = "WinUpdates2008R2-NWT215.txt"
}

$WinUpdates = Get-Content .\$Winupdatefile
$UpdatesInstalled = @()
$UpdatesMissing = @()

#Function that reviews installed hotfixes
Function Get-MSHotfix 
{ 
    $outputs = Invoke-Expression "wmic qfe list" 
    $outputs = $outputs[1..($outputs.length)] 
     
     
    foreach ($output in $Outputs) { 
        if ($output) { 
            $output = $output -replace 'y U','y-U' 
            $output = $output -replace 'NT A','NT-A' 
            $output = $output -replace '\s+',' ' 
            $parts = $output -split ' ' 
            if ($parts[5] -like "*/*/*") { 
                $Dateis = [datetime]::ParseExact($parts[5], '%M/%d/yyyy',[Globalization.cultureinfo]::GetCultureInfo("en-US").DateTimeFormat) 
            } else { 
                $Dateis = get-date([DateTime][Convert]::ToInt64("$parts[5]", 16))-Format '%M/%d/yyyy' 
            } 
            New-Object -Type PSObject -Property @{ 
                KBArticle = [string]$parts[0] 
                Computername = [string]$parts[1] 
                Description = [string]$parts[2] 
                FixComments = [string]$parts[6] 
                HotFixID = [string]$parts[3] 
                InstalledOn = Get-Date($Dateis)-format "dddd d MMMM yyyy" 
                InstalledBy = [string]$parts[4] 
                InstallDate = [string]$parts[7] 
                Name = [string]$parts[8] 
                ServicePackInEffect = [string]$parts[9] 
                Status = [string]$parts[10] 
            } 
        } 
    } 
} 

#Get all installed hotfixes, then compare what is required against list
$AllInstalled = Get-MSHotfix
ForEach ($Update in $WinUpdates)
{
    
    $Installed = $AllInstalled | Where-Object {$_.HotfixID -match $Update}
    If ($Installed -ne $null)
    {
        
        $UpdatesInstalled += $update
    }
    Else
    {
        $UpdatesMissing += $update
    }
}

#write the output to the terminal
Write-Host "Updates installed: " $UpdatesInstalled
Write-Host "Updates missing: " $UpdatesMissing