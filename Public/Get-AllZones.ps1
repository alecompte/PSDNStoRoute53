using module ..\Class\DNSZone.ps1
function Get-AllZones {
  $Zones = Get-R53HostedZoneList
  $NewZones = @()
  
  foreach ($z in $Zones) {
      $Name = $z.Name.Substring(0,($z.Name.Length)-1) ##Remove trailing dot
      $ZoneObject = [DNSZone]::New($Name, ($z.Id.Replace("/hostedzone/", "")))


      $NewZones = $NewZones + $ZoneObject

  }

  return $NewZones
}

