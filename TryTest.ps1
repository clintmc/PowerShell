#-after (Get-date).AddDays(-14)
$Expected =(Get-date).AddDays(-365)
$Unexpected =(Get-date).AddDays(-365)
$Expected = get-eventlog -logname system -after (Get-date).AddDays(-1) | Where-Object {$_.EventID -eq 1074}
$Unexpected = get-eventlog -logname system -after (Get-date).AddDays(-1) | Where-Object {$_.EventID -eq 6008}












Write-Host "Expected"
$Expected
Write-Host "Unexpected"
$Unexpected


