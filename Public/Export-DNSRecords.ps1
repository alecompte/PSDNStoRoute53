function Export-DNSRecords {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]$ExpectedNS1,
        [String]$ExpectedNS2
    )

    return (Verify-Zones -ExpectedNS1 $ExpectedNS1 -ExpectedNS2 $ExpectedNS2 | Format-DNSRecords)

}