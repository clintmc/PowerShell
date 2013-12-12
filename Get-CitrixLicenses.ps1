<#
.SYNOPSIS
Reports on Citrix licenses in use for selected products.

.DESCRIPTION
This script will query your Citrix License server and output the in use and total licenses for individual products.

.NOTES
Requires Citrix Licensing Snapin (Citrix.Licensing.Admin.V1)
If your License server has a self-signed cert you may get license
errors when running this.  I've resolved this in my test environments
by installing the cert as a Trusted Root CA Cert.

Source: http://www.clintmcguire.com/scripts/get-citrixlicenses/
Author: Clint McGuire
Version 1.0
Copyrigth 2013

.EXAMPLES
PS> .\Get-CitrixLicenses.ps1
Using 71 Citrix XenApp Enterprise of 132 available.

#>
############################################################################################
#DEFINE THESE VARIABLES FOR YOUR ENVIRONMENT

#Enter the URL for your License server, typically this uses HTTPS and port 8083
#E.G. "https://licensingservername:8083"
$ServerAddress = 

#Enter the license type you would like to output, this can be a comma separated list, include each option in single quotes
#E.G. 'Citrix XenApp Enterprise','Citrix XenDesktop Enterprise','Citrix EdgeSight for XenApp'
$LicenseTypeOutput = 

############################################################################################

#Check for Licensing Snap-in, add if not currently added
#PowerShell Snap-in is contained in: LicensingAdmin_PowerShellSnapIn_x64.msi
if ( (Get-PSSnapin -Name Citrix.Licensing.Admin.V1 -ErrorAction SilentlyContinue) -eq $null )
{
    Add-PsSnapin Citrix.Licensing.Admin.V1
}


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

#Output license usage for each requested type.
Foreach ($Type in $LicenseTypeOutput)
{
	$OutPutLicInUse = $LicInUse.Get_Item($Type)
	$OutPutAvail = $LicAvailable.Get_Item($Type)
	Write-Host "Using" $OutPutLicInUse  $Type  "of" $OutPutAvail "available."
}