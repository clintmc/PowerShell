#Server Health Check

$ServerList = @("PRTCOEXCH02","PRTCODC01","PRTCODC02","PRTCODC03","PRTCOAPP01","PRTCOIIS06","PRTCOFPS01","PRTCOSQL04")

$Ports = @{"PRTCOEXCH02"=25,80,443,445,593}
$Ports = @{"PRTCODC01"=139,389,3286,53,445,135}
$Ports = @{"PRTCODC02"=139,389,3286,53,445,135}
$Ports = @{"PRTCODC03"=139,389,3286,53,445,135}
$Ports = @{"PRTCOAPP01"=}
$Ports = @{"PRTCOIIS06"=80,443}
$Ports = @{"PRTCOFPS01"=135}
$Ports = @{"PRTCOSQL04"=1443}

$Services = @{"PRTCOEXCH02"=}
$Services = @{"PRTCODC01"=}
$Services = @{"PRTCODC02"=}
$Services = @{"PRTCODC03"=}
$Services = @{"PRTCOAPP01"=}
$Services = @{"PRTCOIIS06"=}
Services = @{"PRTCOFPS01"=}
$Services = @{"PRTCOSQL04"=}

# E-mail report details
$emailFrom     = ""
$emailTo       = ""
$emailSubject  = ("XenApp Farm Report - " + (Get-Date -format R))
$smtpServer    = ""


$currentDir = Split-Path $MyInvocation.MyCommand.Path
$logfile    = Join-Path $currentDir (".log")
$resultsHTM = Join-Path $currentDir (".htm")
$errorsHTM  = Join-Path $currentDir (".htm")
 
$headerNames  = "FolderPath", "WorkerGroups", "ActiveSessions", "ServerLoad", "Ping", "Logons", "LoadEvaluator", "ICAPort", "CGPPort", "IMA", "CitrixPrint", "WMI", "XML", "Spooler", "Uptime", "WriteCacheSize", "vDisk"
$headerWidths = "6",          "6",            "4",              "4",          "4",    "6",      "6",             "4",       "6",                  "4",   "4",           "4",   "4",   "4",       "5",      "4",              "4"


#==============================================================================================
function LogMe() {
	Param(
		[parameter(Mandatory = $true, ValueFromPipeline = $true)] $logEntry,
		[switch]$display,
		[switch]$error,
		[switch]$warning,
		[switch]$progress
	)


	if ($error) {
		$logEntry = "[ERROR] $logEntry" ; Write-Host "$logEntry" -Foregroundcolor Red}
	elseif ($warning) {
		Write-Warning "$logEntry" ; $logEntry = "[WARNING] $logEntry"}
	elseif ($progress) {
		Write-Host "$logEntry" -Foregroundcolor Green}
	elseif ($display) {
		Write-Host "$logEntry" }
	 
	#$logEntry = ((Get-Date -uformat "%D %T") + " - " + $logEntry)
	$logEntry | Out-File $logFile -Append
}

#==============================================================================================
function Ping([string]$hostname, [int]$timeout = 200) {
	$ping = new-object System.Net.NetworkInformation.Ping #creates a ping object
	try {
		$result = $ping.send($hostname, $timeout).Status.ToString()
	} catch {
		$result = "Failure"
	}
	return $result
}


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
<!--<img src="http://servername/administration/icons/xenapp.png" height='42'/>-->
<strong>$title - $date</strong></font>
</td>
</tr>
</table>
<table width='1200'>
<tr bgcolor='#CCCCCC'>
<td width=50% height='48' align='center' valign="middle">
<font face='tahoma' color='#003399' size='4'>
<!--<img src="http://servername/administration/icons/active.png" height='32'/>-->
Active Sessions:  $TotalActiveSessions</font>
<td width=50% height='48' align='center' valign="middle">
<font face='tahoma' color='#003399' size='4'>
<!--<img src="http://servername/administration/icons/disconnected.png" height='32'/>-->
Disconnected Sessions:  $TotalDisconnectedSessions</font>
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
<td width='6%' align='center'><strong>ServerName</strong></td>
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
Function writeData
{
	param($data, $fileName)
	
	$data.Keys | sort | foreach {
		$tableEntry += "<tr>"
		$computerName = $_
		$tableEntry += ("<td bgcolor='#CCCCCC' align=center><font color='#003399'>$computerName</font></td>")
		#$data.$_.Keys | foreach {
		$headerNames | foreach {
			#"$computerName : $_" | LogMe -display
			try {
				if ($data.$computerName.$_[0] -eq "SUCCESS") { $bgcolor = "#387C44"; $fontColor = "#FFFFFF" }
				elseif ($data.$computerName.$_[0] -eq "WARNING") { $bgcolor = "#FF7700"; $fontColor = "#FFFFFF" }
				elseif ($data.$computerName.$_[0] -eq "ERROR") { $bgcolor = "#FF0000"; $fontColor = "#FFFFFF" }
				else { $bgcolor = "#CCCCCC"; $fontColor = "#003399" }
				$testResult = $data.$computerName.$_[1]
			}
			catch {
				$bgcolor = "#CCCCCC"; $fontColor = "#003399"
				$testResult = ""
			}
			
			$tableEntry += ("<td bgcolor='" + $bgcolor + "' align=center><font color='" + $fontColor + "'>$testResult</font></td>")
		}
		
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
<table width='1200'>
<tr bgcolor='#CCCCCC'>
<td colspan='7' height='25' align='left'>
<font face='courier' color='#003399' size='2'><strong>Default Load Evaluator  = $DefaultLE</strong></font>
<tr bgcolor='#CCCCCC'>
<td colspan='7' height='25' align='left'>
<font face='courier' color='#003399' size='2'><strong>Default VDISK Image         = $DefaultVDISK</strong></font>
<tr bgcolor='#CCCCCC'>
<td colspan='7' height='25' align='left'>
<font face='courier' color='#003399' size='2'><strong>XenApp EnterpriseLicense Usage         = $OutPutLicInUse of $OutPutAvail</strong></font>
</td>
</tr>
</table>
</body>
</html>
"@ | Out-File $FileName -append
}



$allResults = @{}

ForEach ($Server in $ServerList)
{
	$tests = @{}

	# Ping server 
	$result = Ping $server 100
	if ($result -ne "SUCCESS") { $tests.Ping = "ERROR", $result }
	else { $tests.Ping = "SUCCESS", $result 
	
		# Test Ports connectivity
		$Test.Port = "SUCCESS", $true
		forEach ($port in $Ports.item($server)) 
		{
			$t = New-Object Net.Sockets.TcpClient $Server, $Port 
			if($t.Connected)
			{
				$Test.Port = "SUCCESS", $true
			}
			else
			{
				$Test.Port = "ERROR", $false
			}
		}
		
		# Check services
		forEach {$service in $Services.item($server))
		{
			if ((Get-Service -Name "IMAService" -ComputerName $server).Status -Match "Running") {
				"$service running..." | LogMe
				$tests.IMA = "SUCCESS", "Success"
			} else {
				"IMA service stopped"  | LogMe -display -error
				$tests.IMA = "ERROR", "Error"
			}
		}
		
		
		# Test WMI
		$tests.WMI = "ERROR","Error"
		try { $wmi=Get-WmiObject -class Win32_OperatingSystem -computer $_.ServerName } 
		catch {	$wmi = $null }

		# Perform WMI related checks
		if ($wmi -ne $null) {
			$tests.WMI = "SUCCESS", "Success"
			$LBTime=$wmi.ConvertToDateTime($wmi.Lastbootuptime)
			[TimeSpan]$uptime=New-TimeSpan $LBTime $(get-date)

			if ($uptime.days -gt 0)
			{
				 $tests.Uptime = "SUCCESS", $uptime.days
			} 
			else 
			{
				 "Server reboot warning, last reboot: {0:D}" -f $LBTime | LogMe -display -warning
				 $tests.Uptime = "WARNING", $uptime.days
			}
			
		} else { "WMI connection failed - check WMI for corruption" | LogMe -display -error	}
	}
$allResults.$server = $tests
	
}

# Write all results to an html file
Write-Host ("Saving results to html report: " + $resultsHTM)
writeHtmlHeader "Server Health Report" $resultsHTM
writeTableHeader $resultsHTM
$allResults | sort-object -property FolderPath | % { writeData $allResults $resultsHTM }
writeHtmlFooter $resultsHTM

$mailMessageParameters = @{
	From       = $emailFrom
	To         = $emailTo
	Subject    = $emailSubject
	SmtpServer = $smtpServer
	Body       = (gc $resultsHTM) | Out-String
	Attachment = $resultsHTM
}

Send-MailMessage @mailMessageParameters -BodyAsHtml