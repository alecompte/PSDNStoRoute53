## Import records to AWS
## This is a painful function
## Return Errors if there is some
function Import-DNSRecords {

  [CmdletBinding()]
  param(
      [Parameter(Mandatory)]
      [Array]$NewZones,
      [Parameter(Mandatory, ValueFromPipeline)]
      [Array]$Records,
      [Parameter()]
      [Bool]$DryRun = $False,
      [Parameter()]
      ## Verbosity is 0 least verbose, 2 most verbose
      [ValidateSet(0, 1, 2)]
      [Int32]$Verbosity = 0,
      [Parameter()]
      [String]$OnlyZone ## If this is set, only one zone will be done

  )

  $Errors = @()

  #Global Change is our Array of change we'll submit
  $GlobalChanges = @()

  if (![string]::IsNullOrEmpty($OnlyZone)) {
      Write-Log -DV 0 -V $Verbosity -Message "OnlyZone is defined, will only process records for $OnlyZone"
      
      $OnlyZ = $NewZones | Where {$_.Name -like $OnlyZone}
      
      if ($OnlyZ -eq $Null) {
          Write-Error -Message "Could not find zone $OnlyZone in list of zones, aborting"
          return
      }

      $NewZones = @($OnlyZ)
  }


  $i = 0
  foreach ($z in $NewZones) {
      $PercentComplete = [math]::Round(($i/$NewZones.Count*100))
      $Name = $z.Name

      Write-Progress -Id 0 -Activity "Adding Records, now at $Name" -Status "$PercentComplete% Complete:"  -PercentComplete ($i/$NewZones.Count*100)
  
      
      $ZoneRecords = $Records | Where {$_.ZoneName -eq $z.Name} ##Get all corresponding DNS Records


      $changes = @() ##Changes for this specific zone



      $ix = 0


      ### Here we process MXRecords
      ### They have a particularity, they need to be all bundled in one request
      ### That's what we'll do here
      ### Keep in mind this doesn't support subdomain MXRecords Parsing
      if ($ZoneRecords.RecordType -contains "MX") {
          Write-Log -DV 2 -V $Verbosity -Message ("Processing MX Records for $Name")

          $PercentCompletex = [math]::Round(($ix/$ZoneRecords.Count*100))
          Write-Progress -Id 1 -Activity "Processing MX records for $Name" -Status "$PercentCompletex% Complete:"  -PercentComplete ($ix/$ZoneRecords.Count*100) -ParentId 0
      
          ## Create the new change object
          $change = New-Object Amazon.Route53.Model.Change
          $change.Action = "CREATE"
          $change.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
          $change.ResourceRecordSet.Name = $z.Name
          $change.ResourceRecordSet.Type = "MX"
          $change.ResourceRecordSet.TTL = 3600
      
          foreach ($r in ($ZoneRecords | Where {($_.RecordType -eq "MX") -and (($_.HostName -eq "@") -or ($_.HostName -eq $_.ZoneName))})) {
          
              ## Here we parse the name
              if ($r.HostName -eq "@") {
                  $r.HostName = $r.ZoneName
              } else {
          
                  $r.HostName = $r.HostName + "." + $r.ZoneName
      
              }

              $MXValue = [string]$r.MXPreference + " " + $r.Value

              if ($change.ResourceRecordSet.ResourceRecords.Value -Contains $MXValue) { # We check if the record is already here, if it is we do nada

                  Write-Log -DV 1 -V $Verbosity -Message ("Already contains $MXValue for $Name")
              } else {
                  
                  # Otherwise we go ahead and add it

                  $change.ResourceRecordSet.ResourceRecords.Add(@{Value=$MXValue})
                  Write-Log -DV 2 -V $Verbosity -Message ("Added $MXValue for $Name")
              }
      
          }

      
          $changes = $changes + $change
          $ix++
      } else {
      
          Write-Log -DV 1 -V $Verbosity -Message "$Name has no MX Records"
      
      }


      Write-Log -DV 2 -V $Verbosity -Message ("Done with MX for $Name")


      ## This marks the end of MX Records



      ## Not MX Records

      $Processed = @()


      #Pre parse hostnames
      #We have to do this out of the main block otherwise duplicate finding fucks up, I scracthed my head for hours on this one
      foreach ($r in ($ZoneRecords | Where {($_.RecordType -ne "MX") -and ($Processed -notcontains $_.GUID)})) {
          
         

          if (($r.HostName -eq "@") -or ($r.HostName -eq $Null) -or ($r.HostName -eq "")) {
              $r.HostName = $r.ZoneName
          } else {
              if ($r.RecordType -eq "CNAME" -and (($r.HostName -like ("*"+$r.ZoneName)))) {
              
                  #This handles weirdly pre-parsed cnames...
              
              } else {
              
                  $r.HostName = $r.HostName + "." + $r.ZoneName
              }
      
          }

      
      }

      foreach ($r in ($ZoneRecords | Where {($_.RecordType -ne "MX") -and ($Processed -notcontains $_.GUID)})) {

          if ($Processed -contains $r.GUID) {
          #donothing
          
          } else {


              Write-Log -DV 2 -V $Verbosity -Message ("Processing " + $r.HostName + " of type " + $r.RecordType + " for $Name")
      
              $PercentCompletex = [math]::Round(($ix/$ZoneRecords.Count*100))
              Write-Progress -Id 1 -Activity "Processing records for $Name" -Status "$PercentCompletex% Complete:"  -PercentComplete ($ix/$ZoneRecords.Count*100) -ParentId 0
              $change = New-Object Amazon.Route53.Model.Change
              $change.Action = "CREATE"
              $change.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
      

              ## Here we parse the records and manipulate them so they fit in amazon


              ##Write-Host $r.HostName

              if (($r.RecordType -eq "A") -or ($r.RecordType -eq "AAAA") -or ($r.RecordType -eq "TXT") -or ($r.RecordType -eq "CNAME")) {
                  $change.ResourceRecordSet.Name = $r.HostName
                  $change.ResourceRecordSet.Type = $r.RecordType
                  $change.ResourceRecordSet.TTL = $r.RecordTTL


                  Write-Log -DV 2 -V $Verbosity -Message ("Value is " + $r.Value + " for $Name")
              

                  if (($ZoneRecords | Where {($_.HostName -eq $r.HostName) -and ($_.RecordType -eq $r.RecordType) -and (($_.RecordType -ne "MX") -and ($_.RecordType -ne "SRV")) -and ($_.GUID -ne $r.GUID)}) -ne $Null) {
                      $Duplicate = ($ZoneRecords | Where {($_.HostName -eq $r.HostName) -and ($_.RecordType -eq $r.RecordType) -and (($_.RecordType -ne "MX") -and ($_.RecordType -ne "SRV")) -and ($_.GUID -ne $r.GUID)})


                      foreach ($d in $Duplicate) {
                          #Write-Host $d.Value
                          if ($d.RecordType -eq "TXT") {
                              
                              $change.ResourceRecordSet.ResourceRecords.Add(@{Value='"'+($d.Value)+'"'})
                          } elseif ($d.RecordType -eq "CNAME") {
                              ##Throwaway the weirdly duplicated CNAME
                              ##Not sure why this happens but oh well
                          } else {
                          
                              $change.ResourceRecordSet.ResourceRecords.Add(@{Value=($d.Value)})
                          }
                          $Processed = $Processed + $d.GUID
                          #Write-Host $d.GUID
                  
                      }
                      $Processed = $Processed + $r.GUID


                      if ($r.RecordType -eq "TXT") {
                              
                          $change.ResourceRecordSet.ResourceRecords.Add(@{Value='"'+($r.Value)+'"'})
                      } else {
                          
                          $change.ResourceRecordSet.ResourceRecords.Add(@{Value=($r.Value)})
                      }

                      Write-Log -DV 1 -V $Verbosity -Message "Duplicate found on $name"


                  } else {
                  
                      if ($r.RecordType -eq "TXT") {
                              
                          $change.ResourceRecordSet.ResourceRecords.Add(@{Value='"'+($r.Value)+'"'})
                      } else {
                          
                          $change.ResourceRecordSet.ResourceRecords.Add(@{Value=($r.Value)})
                      }

                  }

              } elseif ($r.RecordType -eq "SRV") {
                  $Processed = $Processed + $r.GUID 
                  $change.ResourceRecordSet.Name = $r.HostName
                  $change.ResourceRecordSet.Type = $r.RecordType
                  $change.ResourceRecordSet.TTL = $r.RecordTTL
          
                  $change.ResourceRecordSet.ResourceRecords.Add(@{Value=($r.Value)})
              
                  Write-Log -DV 2 -V $Verbosity -Message ("Value is " + $r.Value + " for $Name")
          
              }

              $changes = $changes + $change

              $ix ++
          }
      }

      ### EXECUTION BLOCK
      ### This is where we send changes to Route53 if it's not a dry run
      ### We also collect Errors
      if (!$DryRun) {

          Write-Log -DV 0 -V $Verbosity -Message "Pushing changes for $Name"

          
          if ($changes.Count -gt 0) {
              
              #Only run if there are actually changes

              try {
                  Edit-R53ResourceRecordSet -HostedZoneId $z.Id -Region us-east-1 -ChangeBatch_Comment ("AutoChanges for $Name at " + (Get-Date).DateTime) -ChangeBatch_Change $changes
              } catch {
                  
                  #We can catch exceptions here
                  
                  [pscustomobject]$ErrorObject = @{
                      Zone = $Name
                      Changes = $Changes
                      Exception = $_.Exception 
                  }
                  $Errors = $Errors + $ErrorObject
              }
          } else {

              #Just throw an error that it's empty

              [pscustomobject]$ErrorObject = @{
                  Zone = $Name
                  Changes = $Changes
                  Exception = "No changes, ZONE IS EMPTY"
              }
              $Errors = $Errors + $ErrorObject

          }

      } else {
          
          Write-Log -DV 1 -V $Verbosity -Message "Did not push changes for $Name, DRY RUN"
      
      }


      $GlobalChanges = $GlobalChanges + $changes

  


      $i++
  }

  
  return $Errors



}