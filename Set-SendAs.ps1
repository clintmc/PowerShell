<#
.SYNOPSIS
Set SendAs Permission on mailboxes hosted in Exchange Online/Office 365.
 
.DESCRIPTION
Use this script to assign Send As permission for an account to all Exchange Online/Office 365 mailboxes 
 
.NOTES
Source: http://www.clintmcguire.com/
Author: Clint McGuire
Version 1.1
Copyrigth 2012,2013
Thanks to Evan Zhang for the Add-RecipientPermission syntax - http://community.office365.com/en-us/f/150/p/57642/210047.aspx
 
.LINK
 
http://www.clintmcguire.com/set-sendas/
 
.EXAMPLES
PS> Set-SendAs.ps1
 
#>
 
$MBXS = Get-Recipient -RecipientType usermailbox 
ForEach ($MBX in $MBXS)
{
    Add-RecipientPermission $MBX.name -AccessRights SendAs -Trustee CWAdmin@domain.com
}
Get-RecipientPermission | where {($_.Trustee -ne 'nt authority\self') -and ($_.Trustee -ne 'null sid')}