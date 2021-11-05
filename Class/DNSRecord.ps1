class DNSRecord {
    [string]$ZoneName
    [string]$HostName
    [string]$RecordClass
    [string]$RecordType
    [string]$GUID
    [Int32]$MXPreference
    [Int32]$RecordTTL
    [String]$Value 

    Record($ZoneName, $HostName, $RecordClass, $RecordType) {
        $this.ZoneName = $ZoneName
        $this.HostName = $HostName
        $this.RecordClass = $RecordClass
        $this.RecordType = $RecordType
        $this.MXPreference = 0
        $this.GUID = [guid]::NewGuid().Guid

    }

    Record($ZoneName, $HostName, $RecordClass, $RecordType, $TTL) {
        $this.ZoneName = $ZoneName
        $this.HostName = $HostName
        $this.RecordClass = $RecordClass
        $this.RecordType = $RecordType
        $this.RecordTTL = $TTL
        $this.MXPreference = 0
        $this.GUID = [guid]::NewGuid().Guid

    }


}