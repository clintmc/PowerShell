<#
.SYNOPSIS
This script will send out an email when run.

.DESCRIPTION
Use this script to monitor system reboots and server downtime.  Create a schedule task that runs at system start and
have it execute this script.

.NOTES
Requires PowerShell 4
HTML Functions borrowed from:
XenAppServerHealthCheck
Jason Poyner, jason.poyner@deptive.co.nz, techblog.deptive.co.nz

.LINK
Here are some links that I found useful when writing this script.
https://social.technet.microsoft.com/wiki/contents/articles/17889.powershell-script-for-shutdownreboot-events-tracker.aspx
https://blogs.technet.com/b/heyscriptingguy/archive/2013/03/27/powertip-get-the-last-boot-time-with-powershell.aspx
http://blogs.warwick.ac.uk/markglover/entry/how_to_export/
https://blogs.technet.com/b/heyscriptingguy/archive/2011/12/08/read-a-csv-file-and-build-distinguished-names-on-the-fly-by-using-powershell.aspx
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
$smptPort      = ""
$smtpUser      = 
$smtpPassword

$currentDir = Get-Location
$ResultFile	= Join-Path $CurrentDir.path ("Results.csv")
$ResultsHTM = Join-Path $currentDir.Path ("Reboots.htm")


$headerNames  = "Boot", "Outage", "ShutdownType"
$headerWidths = "6",    "6",      "6"

#==============================================================================================
### Functions
#==============================================================================================

Function writeHtmlHeader
{
param($title, $fileName)
$date = ( Get-Date -format R)
$head = @"
<html>
<head>
<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>
<title>$title</title>
<STYLE TYPE="text/css">
<!--
td {
font-family: Tahoma;
font-size: 11px;
border-top: 1px solid #999999;
border-right: 1px solid #999999;
border-bottom: 1px solid #999999;
border-left: 1px solid #999999;
padding-top: 0px;
padding-right: 0px;
padding-bottom: 0px;
padding-left: 0px;
overflow: hidden;
}
body {
margin-left: 5px;
margin-top: 5px;
margin-right: 0px;
margin-bottom: 10px;
table {
table-layout:fixed; 
border: thin solid #000000;
}
-->
</style>
</head>
<body>
<table width='1200'>
<tr bgcolor='#CCCCCC'>
<td colspan='7' height='48' align='center' valign="middle">
<font face='tahoma' color='#003399' size='4'>
<strong>$title - $date</strong></font>
</td>
</tr>
</table>
"@
$head | Out-File $fileName
}

# ==============================================================================================
Function writeTableHeader
{
param($fileName)
$tableHeader = @"
<table width='1200'><tbody>
<tr bgcolor=#CCCCCC>
<td width='6%' align='center'><strong>Shutdown</strong></td>
"@

$i = 0
while ($i -lt $headerNames.count) {
	$headerName = $headerNames[$i]
	$headerWidth = $headerWidths[$i]
	$tableHeader += "<td width='" + $headerWidth + "%' align='center'><strong>$headerName</strong></td>"
	$i++
}

$tableHeader += "</tr>"

$tableHeader | Out-File $fileName -append
}

# ==============================================================================================
Function writeData #This function is not used because it doesn't handle the variable passed to it correctly for this implementation
{
	param($data, $fileName)
	
	$bgcolor = "#CCCCCC"
    $fontColor = "#003399"
   
    for($i=0;$i-le $Data.length-1;$i++){
        $tableEntry += "<tr>"
        $tableEntry += ("<td bgcolor='" + $bgcolor + "' align=center><font color='" + $fontColor + "'> $($Data[$i].Shutdown) </font></td>")
        $tableEntry += ("<td bgcolor='" + $bgcolor + "' align=center><font color='" + $fontColor + "'> $($Data[$i].Boot) </font></td>")
        $tableEntry += ("<td bgcolor='" + $bgcolor + "' align=center><font color='" + $fontColor + "'> $($Data[$i].Outage) </font></td>")
        $tableEntry += ("<td bgcolor='" + $bgcolor + "' align=center><font color='" + $fontColor + "'> $($Data[$i].ShutdownType) </font></td>")
        #$i++
        $tableEntry += "</tr>"
    }
    	
	$tableEntry | Out-File $fileName -append
}

 
# ==============================================================================================
Function writeHtmlFooter
{
param($fileName)
@"
</table>
</body>
</html>
"@ | Out-File $FileName -append
}



#==============================================================================================
### Main Script
#==============================================================================================
$Expected = New-Object PSObject | Select-Object Date, User, Action, Process, Reason, ReasonCode, Comment
$Unexpected = New-Object PSObject | Select-Object Date, User, Action, Process, Reason, ReasonCode, Comment
$ServerName = (Get-CimInstance -ClassName win32_operatingsystem).csname
$StartTime = (Get-Date).AddDays(-14)
$AllResults = @()

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
If ($Expected.date -gt $Unexpected.date)
{
	$LastDown = $Expected.Date 
    $Action = $Expected.Action
}
Else
{
	$LastDown = $Unexpected.date
    $Action = $Unexpected.Action
}

#Determine last boot time
$CIM = Get-CimInstance -ClassName win32_operatingsystem  
$LastUp = $CIM.lastbootuptime 

#Write details to CSV file 
$Outage = $LastUp - $LastDown
$OutageTime = "{0:N2}" -f $Outage.TotalMinutes
$Results = New-Object PSObject
$Results | add-member -membertype NoteProperty -name "Shutdown" -Value $LastDown
$Results | add-member -membertype NoteProperty -name "Boot" -Value $LastUp
$Results | add-member -membertype NoteProperty -name "Outage" -Value $OutageTime
$Results | add-member -membertype NoteProperty -name "ShutdownType" -Value $Action
$Results | Export-CSV $ResultFile -notype -append

#Import CSV for comparison and reporting
$Data = Import-Csv $ResultFile

#Create HTML Report
writeHtmlHeader "Server Reboot Report" $resultsHTM
writeTableHeader $resultsHTM
#Write Data
$bgcolor = "#CCCCCC"
$fontColor = "#003399"
   
for($i=0;$i-le $Data.length-1;$i++){
    $tableEntry += "<tr>"
    $tableEntry += ("<td bgcolor='" + $bgcolor + "' align=center><font color='" + $fontColor + "'> $($Data[$i].Shutdown) </font></td>")
    $tableEntry += ("<td bgcolor='" + $bgcolor + "' align=center><font color='" + $fontColor + "'> $($Data[$i].Boot) </font></td>")
    $tableEntry += ("<td bgcolor='" + $bgcolor + "' align=center><font color='" + $fontColor + "'> $($Data[$i].Outage) </font></td>")
    $tableEntry += ("<td bgcolor='" + $bgcolor + "' align=center><font color='" + $fontColor + "'> $($Data[$i].ShutdownType) </font></td>")
    $tableEntry += "</tr>"
}
 	
$tableEntry | Out-File $resultsHTM -append
writeHtmlFooter $resultsHTM


$mailMessageParameters = @{
	From       = $emailFrom
	To         = $emailTo
	Subject    = $emailSubject
	SmtpServer = $smtpServer
    Port       = $smtpPort
	Body       = (Get-Content $resultsHTM) | Out-String
}

Send-MailMessage @mailMessageParameters -BodyAsHtml



