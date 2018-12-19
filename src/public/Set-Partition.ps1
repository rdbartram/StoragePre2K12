function Set-Partition {
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [int32]
        $DiskNumber,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [int32]
        $PartitionNumber,

        [parameter(Mandatory = $true)]
        [char]
        $NewDriveLetter
    )

    Try {
        $Output = "select disk $DiskNumber`nselect partition $PartitionNumber`nassign letter=$NewDriveLetter`n" | diskpart
    } Catch {
        Write-Error $_
    }
}
