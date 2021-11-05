using module ..\Class\DNSZone.ps1
function Create-AllZones {
    [CmdletBinding()]
    param(
        [Parameter()]
        [Array]$Zones, ##The one exported from the server
        [String]$DelegationSet
    )

    $NewZones = @()

    foreach ($z in $Zones) {
        $Name = $z.ZoneName
        $zone = New-R53HostedZone -DelegationSetId $DelegationSet -Name $z.ZoneName -CallerReference ("CreateAllZones: $Name at " + (Get-Date).DateTime) -Region us-east-1

        $ZoneObject = [DNSZone]::New($Name, ($z.Id.Replace("/hostedzone/", "")))


        $NewZones = $NewZones + $ZoneObject

    }


    return $NewZones
}