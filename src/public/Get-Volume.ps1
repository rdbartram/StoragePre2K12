function Get-Volume {
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias("Number")]
        [int32]
        $DiskNumber,

        [parameter(ValueFromPipelineByPropertyName = $true)]
        [int32]
        $PartitionNumber
    )
    process {
        Get-DiskPartVolume | % {
            if ($PSBoundParameters.ContainsKey("DiskNumber") -and $_.DiskNumber -ne $DiskNumber) {
                continue
            }

            if ($PSBoundParameters.ContainsKey("PartitionNumber") -and $_.PartitionNumber -ne $PartitionNumber) {
                continue
            }

            if ($PSBoundParameters.ContainsKey("DriveLetter") -and $_.DriveLetter -ne $DriveLetter) {
                continue
            }

            $_
        }
    }
}
