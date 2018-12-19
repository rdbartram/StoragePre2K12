function Get-Disk {
    [cmdletbinding()]
    param(
        [parameter()]
        [string]
        $FriendlyName,

        [parameter()]
        [string]
        $SerialNumber,

        [parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias("DiskNumber")]
        [int32]
        $Number
    )

    $Disks = Get-WmiObject Win32_DiskDrive
    $DiskPart = Get-DiskPartDisk

    foreach ($Disk in $Disks) {
        if ($PSBoundParameters.ContainsKey("Number") -and $Number -ne $Disk.Index) {
            continue
        }

        if ($PSBoundParameters.ContainsKey("SerialNumber") -and $SerialNumber -ne $Disk.SerialNumber) {
            continue
        }

        if ($PSBoundParameters.ContainsKey("FriendlyName") -and $FriendlyName -ne $Disk.Caption) {
            continue
        }

        $loc = ($DiskPart | where {$_.DiskNumber -eq $Disk.Index}).LocationPath
        if ($loc -imatch '^pciroot\((?<adapter>\d+)\).+p(?<port>\d+)t(?<target>\d+)L(?<lun>\d+)' ) {
            $Location = "PCI Slot : Adapter $([int]$matches["adapter"]) : Port $([int]$matches["port"]) : Target $([int]$matches["target"]) : LUN $([int]$matches["lun"])"
        }

        $OutPut = New-Object PSObject
        $OutPut | Add-Member -MemberType NoteProperty -Name "PartitionStyle" -Value ($DiskPart | where {$_.DiskNumber -eq $Disk.Index}).PartitionStyle
        $OutPut | Add-Member -MemberType NoteProperty -Name "OperationalStatus" -Value ($DiskPart | where {$_.DiskNumber -eq $Disk.Index}).DetailStatus
        $OutPut | Add-Member -MemberType NoteProperty -Name "BusType" -Value ($DiskPart | where {$_.DiskNumber -eq $Disk.Index}).DetailType
        $OutPut | Add-Member -MemberType NoteProperty -Name "BootFromDisk" -Value $(if (($DiskPart | where {$_.DiskNumber -eq $Disk.Index}).BootDisk -eq "Yes") {
                $true
            } else {
                $false
            })
        $OutPut | Add-Member -MemberType NoteProperty -Name "FirmwareVersion" -Value $Disk.FirmwareVersion
        $OutPut | Add-Member -MemberType NoteProperty -Name "FriendlyName" -Value $Disk.Caption
        $OutPut | Add-Member -MemberType NoteProperty -Name "Guid" -Value ($DiskPart | where {$_.DiskNumber -eq $Disk.Index}).DiskID
        $OutPut | Add-Member -MemberType NoteProperty -Name "IsBoot" -Value $(if (($DiskPart | where {$_.DiskNumber -eq $Disk.Index}).BootDisk -eq "Yes") {
                $true
            } else {
                $false
            })
        $OutPut | Add-Member -MemberType NoteProperty -Name "IsClustered" -Value $(if (($DiskPart | where {$_.DiskNumber -eq $Disk.Index}).ClusteredDisk -eq "Yes") {
                $true
            } else {
                $false
            })
        $OutPut | Add-Member -MemberType NoteProperty -Name "IsOffline" -Value $(if (($DiskPart | where {$_.DiskNumber -eq $Disk.Index}).Status -eq "Online") {
                $false
            } else {
                $true
            })
        $OutPut | Add-Member -MemberType NoteProperty -Name "IsReadOnly" -Value $(if (($DiskPart | where {$_.DiskNumber -eq $Disk.Index}).ReadOnly -eq "Yes") {
                $true
            } else {
                $false
            })
        $OutPut | Add-Member -MemberType NoteProperty -Name "Location" -Value $Location
        $OutPut | Add-Member -MemberType NoteProperty -Name "LogicalSectorSize" -Value $Disk.BytesPerSector
        $OutPut | Add-Member -MemberType NoteProperty -Name "FreeSpace" -Value ($DiskPart | where {$_.DiskNumber -eq $Disk.Index}).Free
        $OutPut | Add-Member -MemberType NoteProperty -Name "Manufacturer" -Value $Disk.Manufacturer
        $OutPut | Add-Member -MemberType NoteProperty -Name "Model" -Value $Disk.Model
        $OutPut | Add-Member -MemberType NoteProperty -Name "Number" -Value $Disk.Index
        $OutPut | Add-Member -MemberType NoteProperty -Name "NumberOfPartitions" -Value (Get-Partition -DiskNumber $Disk.Index | Measure).count
        $OutPut | Add-Member -MemberType NoteProperty -Name "SerialNumber" -Value $Disk.SerialNumber
        $OutPut | Add-Member -MemberType NoteProperty -Name "Free" -Value ($DiskPart | where {$_.DiskNumber -eq $Disk.Index}).Free
        $OutPut | Add-Member -MemberType NoteProperty -Name "Size" -Value $Disk.Size

        $OutPut
    }
}
