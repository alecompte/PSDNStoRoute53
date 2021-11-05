function Get-ZonesWithWrongDelegationSet {
  [CmdletBinding()]
  param(
      [Parameter(Mandatory)]
      [String] $Expected
  
  )
  $Wrong = @()

  $Zn = Get-R53HostedZoneList


  foreach ($z in $Zn) {

      $rz = Get-R53HostedZone -Id ($z.Id.Replace("/hostedzone/", ""))
      if ($rz.DelegationSet.Id -notlike ("*"+$Expected)) {
          $Wrong = $Wrong + $rz
      }

  }

  return $Wrong
}
