using module ..\Class\DNSZone.ps1

function Create-MissingZones {
    [CmdletBinding()]
    param(
        [Parameter()]
        [Array]$Zones, ##The one exported from the server
        [String]$DelegationSet,
        [Bool]$AutoCompare = $True,
        [Bool]$DryRun = $False
    )

    $ExistingZones = Get-R53HostedZoneList

    $NewZones = @()

    foreach ($z in $Zones) {
        
        if ($ExistingZones.Name -notcontains ($z.ZoneName+".")) {

            $Name = $z.ZoneName
            if (!$DryRun) {
                $zone = New-R53HostedZone -DelegationSetId $DelegationSet -Name $z.ZoneName -CallerReference ("CreateAllZones: $Name at " + (Get-Date).DateTime) -Region us-east-1
                
                
                $ZoneObject = [DNSZone]::New($Name, ($z.Id.Replace("/hostedzone/", "")))
                $NewZones = $NewZones + $ZoneObject
            } else {
                Write-Host "Would Create $Name"
            }

        } else {
            
        
        
        }

    }


    return $NewZones


}