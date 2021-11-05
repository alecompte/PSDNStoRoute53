function Switch-NameServers {
  [CmdletBinding()]
  param(
      [Parameter(Mandatory=$True)]
      [Array] $NewZones,
      [String] $NS1,
      [String] $NS2,
      [String] $NS3,
      [String] $NS4
  )

  foreach ($z in $NewZones) {

      $RR = (Get-R53ResourceRecordSet -HostedZoneId $z.Id).ResourceRecordSets | Where {$_.Type -eq "NS"}

      $delChange = New-Object Amazon.Route53.Model.Change
      $delChange.Action = "DELETE"
      $delChange.ResourceRecordSet = $RR

      $change = New-Object Amazon.Route53.Model.Change
      $change.Action = "CREATE"
      $change.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
      $change.ResourceRecordSet.Name = $z.Name
      $change.ResourceRecordSet.Type = "NS"
      $change.ResourceRecordSet.TTL = 3600
      $change.ResourceRecordSet.ResourceRecords.Add(@{Value=$NS1})
      $change.ResourceRecordSet.ResourceRecords.Add(@{Value=$NS2})
      $change.ResourceRecordSet.ResourceRecords.Add(@{Value=$NS3})
      $change.ResourceRecordSet.ResourceRecords.Add(@{Value=$NS4})

      Edit-R53ResourceRecordSet -HostedZoneId $z.Id -Region us-east-1 -ChangeBatch_Comment ("AutoSwitchNS at " + (Get-Date).DateTime) -ChangeBatch_Change $delChange,$change
  }   
  


}