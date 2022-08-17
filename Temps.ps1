param(
    [parameter()]$PS3IP = "10.0.0.32",
    [parameter()]$ps3URL = "http://$($PS3IP)/cpursx.html",
    [parameter()]$Pool = $true,
    [parameter()][switch]$pretty
)

process {
    [string]$rsxtemp = ""
    [string]$cputemp = ""
    $Times = "" #we'll format as date later on
    [string]$fantemp = ""

    [string]$rsx
    [string]$cpu
    [string]$fan


    #create our base object
    $array = @([PSCustomObject]@{ID = 0; CPU = '0'; RSX = '0'; FAN = '0'; Time = '' })

    #copy of the main array, but without duplicates
    $finalTemp = @()


    write-host "RSX,CPU,RunTime,Fan"
    write-host "-------------------"

    while ($Pool) {
        #first we need to get the page from WMM
        $response = Invoke-WebRequest -Uri $ps3URL #-Method Get

        $pattern = "<div class='cpu' style='width:..."
        $RawCPU = ($response | select-string $pattern -AllMatches).Matches

        $pattern = "<div class='rsx' style='width:..."
        $RawRSX = ($response | select-string $pattern -AllMatches).Matches

        $pattern = "<div class='fan' style='width:..."
        $RawFAN = ($response | select-string $pattern -AllMatches).Matches

        $pattern = "..:..:.."
        $Times = ($response | select-string $pattern -AllMatches).Matches

        $total = $RawRSX.Count


        #powershell returns string matches as arrays -- now we need to loop through those arrays and extract the values
        #we also remove the xml tags. I'm sure there's cleaner ways to do this
        for ($i = 1; $i -lt $total; $i++) {
            $rsxtemp = $RawRSX[$i]
            $cputemp = $RawCPU[$i]
            $time = $Times[$i]
            $fantemp = $RawFAN[$i]

            $rsx = $rsxtemp.Replace("<div class='rsx' style='width:", '').Replace("%", "F")
            $cpu = $cputemp.Replace("<div class='cpu' style='width:", '').Replace("%", "F")
            $fan = $fantemp.Replace("<div class='fan' style='width:", '')
            
            #now we throw everything into an array-like object
            $array += @([PSCustomObject]@{ID = $i; CPU = $cpu; RSX = $rsx; FAN = $fan; Time = [datetime]::ParseExact($time, 'HH:mm:ss', $null) })
        }
        $finalTemp += $array
        
        
        
        for ($y = 10; $y -ge 0; $y-- ) {
            Write-Progress -Activity "Seconds until next poll" -Status "$y" -PercentComplete $($y * 10)
            #write-host $($y*10)
            Start-Sleep -Milliseconds 900
        }
        Clear-Host
        if ($pretty) {
            $finalTemp
        } #we need to sort before we can remove duplicates
        else { $finalTemp | Sort-Object -Property time | Get-Unique -AsString  | format-table }

    }
}