<#
.SYNOPSIS
Gets the last logon time for User accounts and exports to a CSV file.

.DESCRIPTION
This script will query Domain Controllers to find the last logon time for User accounts in the domain.

.NOTES
Requires Quest AD Cmdlets

Source: http://clintmcguire.com
Author: Clint McGuire
Version 1.1
Copyrigth 2011,2013

.LINK
http://www.clintmcguire.com/get-alluserlastlogon/

.EXAMPLES
PS> Get-AllUserLastLogon

#>
$DCs = get-qadcomputer -ComputerRole DomainController
$LastLogon = @{}
ForEach ($DC in $DCs) {
	$Users = Get-QADUser -Service $dc.dnshostname -Enabled
	ForEach ($User in $Users) 
	{
		If ($User.LastLogon -ne $null)
		{	
			$Time = $User.LastLogon | Get-Date -Format u
		}
		Else
		{
			$Time = $User.LastLogon
		}
		$UserName = $User.DisplayName
		if ($LastLogon.ContainsKey($UserName))
		{
				if ($LastLogon.Get_Item($UserName) -le $Time) {
				$LastLogon.Set_Item($UserName, $Time)
			}
		}
		else{
			$LastLogon.Add($UserName, $Time)
		}
	}
}
$LastLogon.GetEnumerator() | Sort-Object Name |export-csv $home\AllADUserLastLogon.csv -NoTypeInformation