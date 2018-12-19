function New-Partition {
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [int32]
        $DiskNumber,

        [parameter()]
        [char]
        $DriveLetter,

        [Parameter()]
        [switch]
        $AssignDriveLetter,

        [Parameter()]
        [int32]
        $Size,

        [Parameter()]
        [switch]
        $UseMaximumSize
    )

    if ($Size) {
        $dpscript = "select disk $DiskNumber`ncreate partition primary size=$Size`nList Partition`n"
    } else {
        $dpscript = "select disk $DiskNumber`ncreate partition primary`nList Partition`n"
    }

    Try {
        $Output = $dpscript | diskpart
        $Parts = ($Output.split("`n") | where { $_ -match "Partition (\d+)"}).substring(12, 5).trimend()
        $PartNumber = $Parts[$Parts.length - 1]
    } Catch {
        Write-Error $_
    }
    Get-Partition -DiskNumber $DiskNumber -PartitionNumber $PartNumber
}
