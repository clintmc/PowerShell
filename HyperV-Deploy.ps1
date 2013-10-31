#New-VM -Name WS2012MDTTest -MemoryStartupBytes 2GB -NewVHDPath 'C:\Users\Public\Documents\Hyper-V\Virtual hard disks\WS2012MDTTest.vhdx'-NewVHDSize 37580963840 -SwitchName LAN 
#Add-VMNetworkAdapter -VMName WS2012MDTTest -IsLegacy $true -SwitchName LAN 
#Set-VM -Name WS2012MDTTest -DynamicMemory -MemoryMinimumBytes 512MB -MemoryMaximumBytes 2048MB -MemoryStartupBytes 2048MB 
#Get-VM WS2012MDTTest | Set-VMBios -StartupOrder @("LegacyNetworkAdapter", "CD", "IDE", "floppy")
Get-VM WS2012MDTTest | Start-VM 