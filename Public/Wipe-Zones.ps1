## This wipes all zones or one zone
function Wipe-Zones {

  [CmdletBinding()]
  param(
      [Parameter()]
      [String]$Zone,
      [Parameter()]
      [Array]$NewZones,
      [Parameter()]
      [Bool]$AutoGetZones = $False
  )

  if (![string]::IsNullOrEmpty($Zone)) {
      if (($NewZones.Count -eq 0) -or ($NewZones -eq $Null)) {
          $NewZones = Get-R53HostedZoneList
      }

      $ZoneObject = ($NewZones | Where {$_.Name -like ($Zone + '*')})
      if ($ZoneObject.GetType().BaseType.Name -eq "Array") {
          Write-Error -Message "Multiple zones returned, not proceeding"
          return $ZoneObject
      } else {
          $ZoneId = $ZoneObject.Id.Replace("/hostedzone/", "")

          $RRs = (Get-R53ResourceRecordSet -HostedZoneId $ZoneId).ResourceRecordSets | Where {($_.Type -ne "NS") -and ($_.Type -ne "SOA")}
          if ($RRS.Count -gt 0) {

              $changes = @()
              foreach ($rr in $RRs) {
                  $delChange = New-Object Amazon.Route53.Model.Change
                  $delChange.Action = "DELETE"
                  $delChange.ResourceRecordSet = $rr
          
                  $changes = $changes + $delChange
              }
    

              Edit-R53ResourceRecordSet -HostedZoneId $ZoneId -Region us-east-1 -ChangeBatch_Comment ("WipeZone at " + (Get-Date).DateTime) -ChangeBatch_Change $changes
          }

      }
      
  
  } else {

      if (($NewZones.Count -eq 0) -or ($NewZones -eq $Null) -or $AutoGetZones) {
          $NewZones = Get-R53HostedZoneList
      }
  
      foreach ($z in $NewZones) {

          $RRs = (Get-R53ResourceRecordSet -HostedZoneId $z.Id).ResourceRecordSets | Where {($_.Type -ne "NS") -and ($_.Type -ne "SOA")}
          if ($RRS.Count -gt 0) {

              $changes = @()
              foreach ($rr in $RRs) {
                  $delChange = New-Object Amazon.Route53.Model.Change
                  $delChange.Action = "DELETE"
                  $delChange.ResourceRecordSet = $rr
          
                  $changes = $changes + $delChange
              }
    

              Edit-R53ResourceRecordSet -HostedZoneId $z.Id -Region us-east-1 -ChangeBatch_Comment ("WipeZones at " + (Get-Date).DateTime) -ChangeBatch_Change $changes
          }
      }
  
  }

}