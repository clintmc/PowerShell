<#
.SYNOPSIS

.DESCRIPTION

.NOTES

.LINK
https://social.technet.microsoft.com/wiki/contents/articles/17889.powershell-script-for-shutdownreboot-events-tracker.aspx
https://blogs.technet.com/b/heyscriptingguy/archive/2013/03/27/powertip-get-the-last-boot-time-with-powershell.aspx
http://blogs.warwick.ac.uk/markglover/entry/how_to_export/
.EXAMPLES

#>
#==============================================================================================
### Variables
#==============================================================================================

# E-mail report details
$emailFrom     = ""
$emailTo       = ""
$emailSubject  = ("$ServerName Reboot - " + (Get-Date -format R))
$smtpServer    = ""

$currentDir = Get-Location
$ResultFile	= Join-Path $CurrentDir.path ("Results.csv")


#==============================================================================================
### Main Script
#==============================================================================================
$Expected = New-Object PSObject | Select-Object Date, User, Action, Process, Reason, ReasonCode, Comment
$Unexpected = New-Object PSObject | Select-Object Date, User, Action, Process, Reason, ReasonCode, Comment
$ServerName = (Get-CimInstance -ClassName win32_operatingsystem).csname
$StartTime = (Get-Date).AddDays(-14)

#Check Event log for last clean shutdown/reboot
Get-WinEvent -FilterHashtable @{logname='System'; id=1074; StartTime=$StartTime} -MaxEvents 1 |
ForEach-Object {
    $Expected.Date = $_.TimeCreated
    $Expected.User = $_.Properties[6].Value
    $Expected.Process = $_.Properties[0].Value
    $Expected.Action = $_.Properties[4].Value
    $Expected.Reason = $_.Properties[2].Value
    $Expected.ReasonCode = $_.Properties[3].Value
    $Expected.Comment = $_.Properties[5].Value
} 

#Check Event log for last unexpected shutdown
$Unexpected.Date = (Get-Date).AddDays(-365)
Get-WinEvent -FilterHashtable @{logname='System'; id=6008; StartTime=$StartTime} -MaxEvents 1 -erroraction silentlycontinue|
ForEach-Object {
	$Unexpected.Date = $_.TimeCreated
	$Unexpected.User = $_.Properties[6].Value
	$Unexpected.Process = $_.Properties[0].Value
	$Unexpected.Action = $_.Properties[4].Value
	$Unexpected.Reason = $_.Properties[2].Value
	$Unexpected.ReasonCode = $_.Properties[3].Value
	$Unexpected.Comment = $_.Properties[5].Value
}

#Determine if last shutdown was clean or unexpected and use most recent
If ($Expected.Date -gt $Unexpected.Date)
{
	$LastDown = $Expected.Date
	$Action = $Expected.Action
}
Else
{
	$LastDown = $Unexpected.Date
	$Action = $Unexpected.Action
}

#Determine last boot time
$CIM = Get-CimInstance -ClassName win32_operatingsystem  
$LastUp = $CIM.lastbootuptime 

#Write details to CSV file 
$Outage = $LastUp - $LastDown
$Results = New-Object PSObject
$Results | add-member -membertype NoteProperty -name "Shutdown" -Value $LastDown
$Results | add-member -membertype NoteProperty -name "Boot" -Value $LastUp
$Results | add-member -membertype NoteProperty -name "Outage" -Value $Outage.TotalMinutes
$Results | add-member -membertype NoteProperty -name "Shutdown Type" -Value $Action
$Results | Export-CSV $ResultFile -notype -append

#Import CSV for comparison and reporting
$Tests = import-csv $ResultFile

$tests