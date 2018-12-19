function Initialize-Disk {
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [int32]
        $DiskNumber,

        [parameter(Mandatory = $true)]
        [ValidateSet("GPT", "MBR")]
        [string]
        $PartitionStyle
    )

    Try {
        $Output = "select disk $DiskNumber`nclean`nconvert $PartitionStyle`n" | diskpart
    } Catch {
        Write-Error $_
    }
}
