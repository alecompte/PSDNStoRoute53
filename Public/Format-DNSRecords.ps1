using module ..\Class\DNSRecord.ps1
using module ..\Class\DNSZone.ps1
function Format-DNSRecords {
    [Cmdletbinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [Array]$RealZones
    
    )
    $Exportable = @()
    
    $ix = 0
    foreach ($z in $RealZones) {
        $PercentComplete = [math]::Round(($ix/$RealZones.Count*100))
        $name = $z.ZoneName
        Write-Progress -Id 0 -Activity "Untangling records for $name" -Status "$PercentComplete% Complete:"  -PercentComplete ($ix/$RealZones.Count*100)

        $Records = Get-DnsServerResourceRecord -ZoneName $z.ZoneName

        $iz = 0
        foreach ($r in $Records) {

            $PercentCompletex = [math]::Round(($iz/$Records.Count*100))
            $HostName = $r.HostName
            Write-Progress -Id 1 -Activity "Processing record: $HostName" -Status "$PercentCompletex% Complete:"  -PercentComplete ($iz/$Records.Count*100) -ParentId 0
            $RecordObject = [DNSRecord]::New($z.ZoneName, $r.HostName, $r.RecordClass, $r.RecordType, $r.TimeToLive.TotalSeconds)


            if ($r.RecordType -eq "MX") {
                $RecordObject.MXPreference = $r.RecordData.Preference
                $RecordObject.Value = $r.RecordData.MailExchange
            } elseif ($r.RecordType -eq "A") {
                $RecordObject.Value = $r.RecordData.IPv4Address
            } elseif ($r.RecordType -eq "TXT") {
                $RecordObject.Value = $r.RecordData.DescriptiveText
            
            } elseif ($r.RecordType -eq "AAAA") {
                $RecordObject.Value = $r.RecordData.IPv6Address
            } elseif ($r.RecordType -eq "CNAME") {
            
                $RecordObject.Value = $r.RecordData.HostNameAlias
            } elseif ($r.RecordType -eq "SRV") {
                $RecordObject.Value = [string]$r.RecordData.Priority + " " + [string]$r.RecordData.Weight + " " + [string]$r.RecordData.Port + " " + $r.RecordData.DomainName
            } elseif (($r.RecordType -eq "NS") -or ($r.RecordType -eq "SOA")) {
                ## Throwaway records
                $RecordObject = $null
            }

            $Exportable = $Exportable + $RecordObject
            $iz++
        }
        $ix++

    }

    return $Exportable
}