function Verify-Zones {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String]$ExpectedNS1,
        [String]$ExpectedNS2
    )

    $RealZones = @()

    foreach ($z in $Zones) {
        $Name = $z.ZoneName
        $PercentComplete = [math]::Round(($i/$Zones.Count*100))
        Write-Progress -Activity "Untangling domains.. Resolving domain $name" -Status "$PercentComplete% Complete:"  -PercentComplete ($i/$Zones.Count*100)
        $Results = Resolve-DNSName -Name $Name -Type NS -Server 1.1.1.1 -ErrorAction SilentlyContinue
    
        if ((($Results).NameHost -contains $ExpectedNS1) -or (($Results).NameHost -contains $ExpectedNS2)) {
            $RealZones = $RealZones + $z
        } else {
            ##Write-Host $Results.NameHost
        
        }
        $i++
    }

    return $RealZones
}