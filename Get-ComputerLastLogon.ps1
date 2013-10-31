<#
.SYNOPSIS
Gets the last logon time for computers and exports to a CSV file.

.DESCRIPTION
This script will query Domain Controllers to find the last logon time for the selected computers in the domain.

.PARAMETER Search
The Search parameter tells the script which OU of computers to get the last logon time for.  The search is recursive so if there are sub-OUs with computers they will also be checked.
This parameter is optional, if it is omited the script will return logon times for all computers in the domain.
The OU name needs to be passed as a DN, GUID or canonical name and should be enclosed in quotes. See Examples for further details.

.PARAMETER Source
This mandatory parameter must be one of the following: List, Name or All.
This allows you to narrow your query to increase speed. This is especially helpful when you have multiple sites across slow WAN links.
If you select List you must also include -DCList parameter and provide the path to a file containing the names of the DCs you want to be queried.
If you select Name you must also include -DCName parameter and provide the name of the DC you want to be queried.
If you select All you don't need to include any other parameters and all DCs in the domain will be queried. See Examples for further details.

.PARAMETER DCList
Provide the path to a file containing the names of all the DCs you want to be queried. Each DCs name should be on its own line.

.PARAMETER DCName
Provide the name of the DC you want to be queried. FQDN is best as it will prevent the script from accidentally running against two DCs with similar names.

.NOTES
Requires Quest AD Cmdlets

Source: http://clintmcguire.com
Author: Clint McGuire
Version 1.3
Copyright 2011,2013

.LINK
http://www.clintmcguire.com/get-computerlastlogon/

.EXAMPLES
PS> Get-ComputerLastLogon -Source All -Search "OU=Computers,OU=Vancouver,DC=Domain,DC=com"
.EXAMPLES
PS> Get-ComputerLastLogon -Source All
.EXAMPLES
PS> Get-ComputerLastLogon -Source List -DCList C:\temp\DCsinSite1.txt
.EXAMPLES
PS> Get-ComputerLastLogon -Source Name -DCName vancouver.contoso.com

#>
Param(
	[Parameter(Mandatory=$false)]
	[ValidateNotNullOrEmpty()]
	[string]
	$Search = "All",
	[Parameter(Mandatory=$true)]
	[ValidateSet("List","Name","All")]
	[string]
	$Source,
	[string]
	$DCList,
	[ValidateScript({Get-QADComputer -id $_ })]
	[string]
	$DCName
	
	
)

$LastLogon = @{}
Add-PSSnapin Quest.ActiveRoles.ADManagement
If ($Source -eq "List")
{
	$DCs = Get-Content -Path $Source
}
ElseIf ($Source -eq "Name")
{
	$DCs = Get-QADComputer -id $DCName -ComputerRole DomainController 
}
Else
{
	$DCs = Get-QADComputer -ComputerRole DomainController
}

ForEach ($DC in $DCs) 
{
	If ($Search -eq "All")
	{
		$Computers = Get-QADcomputer -Service $dc.dnshostname -ip lastlogontimestamp
	}
	Else
	{
		$Computers = Get-QADcomputer -Service $dc.dnshostname -ip lastlogontimestamp -Searchroot $Search
	}
	ForEach ($Computer in $Computers) 
	{
		If ($Computer.lastlogontimestamp -ne $null)
		{
			$Time = $Computer.lastlogontimestamp | Get-Date -format u
		}
		Else
		{
			$Time = $Computer.lastlogontimestamp
		}	
		$ComputerName = $Computer.ComputerName
		If ($LastLogon.ContainsKey($ComputerName))
		{
				If ($LastLogon.Get_Item($ComputerName) -le $Time) 
				{
					$LastLogon.Set_Item($ComputerName, $Time)
				}
		}
		Else
		{
			$LastLogon.Add($ComputerName, $Time)
		}
	}
}
$LastLogon.GetEnumerator() | Sort-Object Name |export-csv $home\ComputerLastLogon.csv -NoTypeInformation