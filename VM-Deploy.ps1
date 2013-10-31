Param(
    [string]$VMName,
    [int64]$RAMMin,
    [int64]$RAMMax,
    [int64]$RAMStart
)
$vSwitch = 'Internal'
#New-VM -Name $VMName -NewVHDPath "C:\Users\Public\Documents\Hyper-V\Virtual hard disks\$VMName.vhdx" -NewVHDSize 37580963840 -SwitchName LAN
#Add-VMNetworkAdapter -VMName $VMName -IsLegacy $true -SwitchName $vSwitch 
Set-VM -Name $VMName -DynamicMemory 
Get-VM $VMName | Set-VM -MemoryMinimumBytes $RAMMin -MemoryMaximumBytes $RAMMax -MemoryStartupBytes $RAMStart
#Get-VM $VMName | Set-VMBios -StartupOrder @("LegacyNetworkAdapter", "CD", "IDE", "floppy")
#Get-VM $VMName | Start-VM 
