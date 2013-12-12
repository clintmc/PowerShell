<#
.SYNOPSIS
Reports on Citrix licenses in use for a specific product.

.DESCRIPTION
This script will query your Citrix Licnese server and 

.NOTES
Requires Citrix Licensing Snapin (Citrix.Licensing.Admin.V1)
If your License server has a self-signed cert you may get license
errors when running this.  I've resolved this in my test environments
by installing the cert as a Trusted Root CA Cert.

Source: http://www.clintmcguire.com
Author: Clint McGuire
Version 1.0
Copyrigth 2013

.EXAMPLES
PS> .\Check-XenAppEnterpriseLic.ps1
XenApp Enterprise Licenses in use: 90

#>
#DEFINE THESE VARIABLES FOR YOUR ENVIRONMENT

#Enter the URL for your License server, typically this uses HTTPS and port 8083
$ServerAddress = 

$LicenseTypeOutput = 




#Check for Licensing Snap-in, add if not currently added
if ( (Get-PSSnapin -Name Citrix.Licensing.Admin.V1 -ErrorAction SilentlyContinue) -eq $null )
{
    Add-PsSnapin Citrix.Licensing.Admin.V1
}
#PowerShell Snapin is contained in this file LicensingAdmin_PowerShellSnapIn_x64.msi

#Create Hash tables
$LicAll = @{}
$LicInUse = @{}
$LicAvailable = @{}

#Build License Display hash table 
$LicAll = Get-LicInventory -AdminAddress $ServerAddress
foreach ($LicInfo in $LicAll) 
{
	$Prod = $LicInfo.LocalizedLicenseProductName
	$InUse = $LicInfo.licensesinuse
	$Avail = $LicInfo.LicensesAvailable
	if ($LicInUse.ContainsKey($Prod))
		{
				if ($LicInUse.Get_Item($Prod) -le $InUse) 
				{
					$LicInUse.Set_Item($Prod, $InUse)
				}
		}
	else
		{
			$LicInUse.add($Prod, $InUse)
		}
	if ($LicAvailable.ContainsKey($Prod))
		{
				if ($LicAvailable.Get_Item($Prod) -le $Avail) 
				{
					$LicAvailable.Set_Item($Prod, $Avail)
				}
		}
	else
		{
			$LicAvailable.add($Prod, $Avail)
		}
}

Foreach ($Type in $LicenseTypeOutput)
{
	$OutPutLicInUse = $LicInUse.Get_Item($Type)
	$OutPutAvail = $LicAvailable.Get_Item($Type)
	Write-Host $Type " in use: " $OutPutLicInUse " of " $OutPutAvail
}