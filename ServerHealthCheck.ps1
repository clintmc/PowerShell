# Server Health Check
# Give this script a list of servers and the ports and services it should check on each of them 
# and it will email you a report about them
# 
# Borrowed heavily from XenAppServerHealthCheck by
# Jason Poyner - techblog.deptive.co.nz
#
# Version 1.0
# Clint McGuire
# January 7, 2014


############################################
# Modify this section
############################################

#List server names that will be checked, these names must resolve, so may need to be FQDNs.
$ServerList = "Server1","Server2","Server3","Server4","Server5","Server6","Server7"

#Create lists of ports to check on the servers, these lists can be reused - for example if you have multiple Exchange servers or multiple DCs.
$EXCHPorts = 25,80,443,445,593
$DCPorts = 139,389,53,445,135
$APPPorts =135,8088,2638
$IISPorts = 80,443,23646
$FPSPorts = 135
$SQLPorts = 1433

$Ports = @{}

#Assign port lists to servers, in this example Server1 and Server2 are both Domain Controllers, so they share 1 port list.
$Ports.add("Server1", $DCPorts)
$Ports.add("Server2", $DCPorts)
$Ports.add("Server3",$EXCHPorts)
$Ports.add("Server4",$APPPorts)
$Ports.add("Server5",$IISPorts)
$Ports.add("Server6",$FPSPorts)
$Ports.add("Server7",$SQLPorts)
#$Ports.add("",$)


#Define services lists using short service name - can be retrieved from Get-Service, or Services console; for services that include a $ in the name use single quotes.
$EXCHServices = "BlackBerry Router","BlackBerry MailStore Service","BlackBerry Controller","MSExchangeTransport","MSExchangeSA","MSExchangeIS"
$ADCAServices = "NTDS","DNS","CertSvc","W3SVC"
$ADDSServices = "NTDS","DNS"
$AppServices = "AppService"
$SPServices = "SPAdminV4","W3SVC"
$FPServices = "Spooler","LanmanServer"
$SQLServices = "MSSQLSERVER",'MSSQL$SHAREPOINT'

$Services = @{}

#Assign service lists to servers.
$Services.add("Server1", $ADCAServices)
$Services.add("Server2", $ADDSServices)
$Services.add("Server3", $EXCHServices)
$Services.add("Server4",$AppServices)
$Services.add("Server5",$SPServices)
$Services.add("PServer6",$FPServices)
$Services.add("Server7",$SQLServices)
#$Services.add("",$)


# E-mail report details
$emailFrom     = ""
$emailTo       = ""
$emailSubject  = ("Server Health Report - " + (Get-Date -format R))
$smtpServer    = ""

############################################
# End of section for modification
############################################

$currentDir = Get-Location
$logfile    = Join-Path $currentDir.path ("ServerHealthCheck.log")
$resultsHTM = Join-Path $currentDir.path ("ServerHealthCheckResults.htm")
$errorsHTM  = Join-Path $currentDir.path ("ServerHealthCheckErrors.htm")
 
$headerNames  = "Ping", "Services", "Ports", "Uptime" 
$headerWidths = "6",          "6",      "6",      "4"


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

$Ping = New-Object System.Net.Networkinformation.ping

$allResults = @{}

ForEach ($Server in $ServerList)
{
	$tests = @{}

	# Ping server 
	$PingResult = $ping.Send($Server)
	$PingStatus = $PingResult.status
	if ($PingStatus -ne "Success") 
	{ 
		$tests.Ping = "ERROR", $PingStatus 
		"$Server Ping failed" | LogMe -display -error
	}
	else 
	{ 
		$tests.Ping = "SUCCESS", $PingStatus 
		"$Server ping success" | LogMe -display
		
		# Test Ports connectivity
		$PortList = $Ports.item($server) | measure
		$PortCount = $PortList.count
		While ($PortCount -ne 0)
		{
			forEach ($Port in $Ports.item($server)) 
				{
					$tcpClient = New-Object System.Net.Sockets.TCPClient
					$tcpClient.Connect($server,$port)
					If ($tcpClient.connected)
					{
						#"$Port open..." | LogMe -display
						$Tests.Ports = "SUCCESS", "Success"
						$PortCount--
					}
					Else
					{
						"$Port not responding" | LogMe -display -error
						$tests.Ports = "ERROR", "Error"
						$PortCount = 0
						Break
					}
				}
		}
		
		# Check services
		$ServiceList = $Services.item($server) | measure
		$ServiceCount = $ServiceList.count
		While ($ServiceCount -ne 0)
		{
			forEach ($service in $Services.item($server))
			{
				if ((Get-Service -Name $Service -ComputerName $server).Status -Match "Running") 
				{
					#"$service running..." | LogMe
					$tests.Services = "SUCCESS", "Success"
					$Servicecount-- 
				} 
				else 
				{
					"$service stopped"  | LogMe -display -error
					$tests.Services = "ERROR", "Error"
					$ServiceCount = 0
					Break
				}
			}
		}
		
		
		# Test WMI
		$tests.WMI = "ERROR","Error"
		try { $wmi=Get-WmiObject -class Win32_OperatingSystem -computer $Server } 
		catch {	$wmi = $null }

		# Perform WMI related checks
		if ($wmi -ne $null) 
		{
			$tests.WMI = "SUCCESS", "Success"
			$LBTime=$wmi.ConvertToDateTime($wmi.Lastbootuptime)
			[TimeSpan]$uptime=New-TimeSpan $LBTime $(get-date)
			$tests.Uptime = "SUCCESS", $uptime.days		
		}
		else 
		{ 
			"WMI connection failed - check WMI for corruption" | LogMe -display -error	
		}
	}
$allResults.$server = $tests
	
}

# Write all results to an html file
Write-Host ("Saving results to html report: " + $resultsHTM)
writeHtmlHeader "Server Health Report" $resultsHTM
writeTableHeader $resultsHTM
$allResults | % { writeData $allResults $resultsHTM }
#writeHtmlFooter $resultsHTM

$mailMessageParameters = @{
	From       = $emailFrom
	To         = $emailTo
	Subject    = $emailSubject
	SmtpServer = $smtpServer
	Body       = (gc $resultsHTM) | Out-String
	Attachment = $resultsHTM
}

Send-MailMessage @mailMessageParameters -BodyAsHtml