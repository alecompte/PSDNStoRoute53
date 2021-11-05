class DNSZone {
    [ValidateNotNullOrEmpty()][string]$Name
    [ValidateNotNullOrEmpty()][string]$Id

    Zone($Name, $Id) {
        $this.Name = $Name
        $this.Id = $Id

    }

}