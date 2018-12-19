function Get-Partition {
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias("Number")]
        [int32]
        $DiskNumber,

        [parameter(ValueFromPipelineByPropertyName = $true)]
        [int32]
        $PartitionNumber,

        [parameter()]
        [char]
        $DriveLetter
    )

    $Partitions = Get-DiskPartPartition
    $Vols = Get-Volume

    if ($PSBoundParameters.ContainsKey("DiskNumber")) {
        $Partitions = $Partitions | where { $_.DiskNumber -eq $DiskNumber }
    }
    if ($PSBoundParameters.ContainsKey("PartitionNumber")) {
        $Partitions = $Partitions | where { $_.PartitionNumber -eq $PartitionNumber }
    }

    foreach ($Partition in $Partitions) {
        $FoundDriveLetter = $($p = $Partition; ($Vols | where { $_.DiskNumber -eq $p.DiskNumber -and $_.PartitionNumber -eq $p.PartitionNumber }).Driveletter)
        if ($PSBoundParameters.ContainsKey("DriveLetter") -and $DriveLetter -ne $FoundDriveLetter) {
            continue
        }

        $OutPut = New-Object PSObject
        $OutPut | Add-Member -MemberType NoteProperty -Name "DiskNumber" -Value $Partition.DiskNumber
        $OutPut | Add-Member -MemberType NoteProperty -Name "PartitionNumber" -Value $Partition.PartitionNumber
        $OutPut | Add-Member -MemberType NoteProperty -Name "DriveLetter" -Value $FoundDriveLetter
        $OutPut | Add-Member -MemberType NoteProperty -Name "Type" -Value $($p = $Partition_; $Vol = ($Vols | where {$_.DiskNumber -eq $p.DiskNumber -and $_.PartitionNumber -eq $p.PartitionNumber }); if ($vol.Type -eq "System" -or !$vol) {
                "Reserved"
            } else {
                "Basic"
            })
        $OutPut | Add-Member -MemberType NoteProperty -Name "IsSystem" -Value $($p = $Partition; $Vol = ($Vols | where {$_.DiskNumber -eq $p.DiskNumber -and $_.PartitionNumber -eq $p.PartitionNumber }); if ($vol.Type -eq "System" -or !$vol) {
                $true
            } else {
                $false
            })
        $OutPut | Add-Member -MemberType NoteProperty -Name "Size" -Value $(if ($Partition.Size) {
                $($sizeinfo = $Partition.size.split(" "); switch ($sizeinfo[1]) {
                        "GB" {
                            ([int]$SizeInfo[0] * 1073741824)
                        }"MB" {
                            ([int]$SizeInfo[0] * 1048576)
                        }default {
                            $SizeInfo[0]
                        }
                    })
            })
        $OutPut
    }
}
