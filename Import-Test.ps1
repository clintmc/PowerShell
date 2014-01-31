$currentDir = Get-Location
$ResultFile	= "C:\Users\clint_000\Documents\GitHub\PowerShell\Results.csv"
$AllResults = @()
$Data = Import-Csv $ResultFile
$i = 0
$bgcolor = "#CCCCCC"
$fontColor = "#003399"


for($i=0;$i-le $Data.length-1;$i++){
    $tableEntry += "<tr>"
    $tableEntry += ("<td bgcolor='" + $bgcolor + "' align=center><font color='" + $fontColor + "'> $($Data[$i].Shutdown) </font></td>")
    $tableEntry += ("<td bgcolor='" + $bgcolor + "' align=center><font color='" + $fontColor + "'> $($Data[$i].Boot) </font></td>")
    $tableEntry += ("<td bgcolor='" + $bgcolor + "' align=center><font color='" + $fontColor + "'> $($Data[$i].Outage) </font></td>")
    $tableEntry += ("<td bgcolor='" + $bgcolor + "' align=center><font color='" + $fontColor + "'> $($Data[$i].ShutdownType) </font></td>")
    #$i++
    $tableEntry += "</tr>"
}



$tableEntry | Out-File "C:\Users\clint_000\Documents\GitHub\PowerShell\outtest98.htm"



