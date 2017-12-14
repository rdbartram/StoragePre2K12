function Get-Disk {
    [cmdletbinding()]
    param(
        [parameter()]
        [string]
        $FriendlyName,

        [parameter()]
        [string]
        $SerialNumber,

        [parameter()]
        [int32]
        $Number
    )

    $Disks = Get-CimInstance -ClassName Win32_DiskDrive
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

        return [pscustomobject] @{
            PartitionStyle     = ($DiskPart | where DiskNumber -eq $Disk.Index).PartitionStyle
            OperationalStatus  = ($DiskPart | where DiskNumber -eq $Disk.Index).DetailStatus;
            BusType            = ($DiskPart | where DiskNumber -eq $Disk.Index).DetailType;
            BootFromDisk       = if (($DiskPart | where DiskNumber -eq $Disk.Index).BootDisk -eq "Yes") {
                $true
            }
            else {
                $false
            }
            FirmwareVersion    = $Disk.FirmwareVersion
            FriendlyName       = $Disk.Caption
            Guid               = ($DiskPart | where DiskNumber -eq $Disk.Index).DiskID
            IsBoot             = if (($DiskPart | where DiskNumber -eq $Disk.Index).BootDisk -eq "Yes") {
                $true
            }
            else {
                $false
            }
            IsClustered        = if (($DiskPart | where DiskNumber -eq $Disk.Index).ClusteredDisk -eq "Yes") {
                $true
            }
            else {
                $false
            }
            IsOffline          = if (($DiskPart | where DiskNumber -eq $Disk.Index).Status -eq "Online") {
                $false
            }
            else {
                $true
            }
            IsReadOnly         = if (($DiskPart | where DiskNumber -eq $Disk.Index).ReadOnly -eq "Yes") {
                $true
            }
            else {
                $false
            }
            Location           = ($DiskPart | where DiskNumber -eq $Disk.Index).LocationPath
            LogicalSectorSize  = $Disk.BytesPerSector
            FreeSpace          = ($DiskPart | where DiskNumber -eq $Disk.Index).Free
            Manufacturer       = $Disk.Manufacturer
            Model              = $Disk.Model
            Number             = $Disk.Index
            NumberOfPartitions = (Get-Partition -DiskNumber $Disk.Index).count
            SerialNumber       = $Disk.SerialNumber
            Free               = ($DiskPart | where DiskNumber -eq $Disk.Index).Free
            Size               = $Disk.Size
        }
    }
}
function Get-Partition {
    [cmdletbinding()]
    param(
        [parameter()]
        [int32]
        $DiskNumber,

        [parameter()]
        [int32]
        $PartitionNumber,

        [parameter()]
        [char]
        $DriveLetter,

        [Parameter(ValueFromPipeline = $True)]
        [int32]
        $Disk
    )

    $Partitions = Get-DiskPartPartition
    $Vols = Get-Volume

    if ($Disk) {
        $DiskNumber = $Disk.Number
    }

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

        return [pscustomobject]@{
            DiskNumber      = $Partition.DiskNumber
            PartitionNumber = $Partition.PartitionNumber
            DriveLetter     = $FoundDriveLetter
            Type            = $($p = $Partition_; $Vol = ($Vols | where { $_.DiskNumber -eq $p.DiskNumber -and $_.PartitionNumber -eq $p.PartitionNumber }); if ($vol.Type -eq "System" -or !$vol) {
                    "Reserved"
                }
                else {
                    "Basic"
                })
            IsSystem        = $($p = $Partition; $Vol = ($Vols | where { $_.DiskNumber -eq $p.DiskNumber -and $_.PartitionNumber -eq $p.PartitionNumber }); if ($vol.Type -eq "System" -or !$vol) {
                    $true
                }
                else {
                    $false
                })
            Size            = $($sizeinfo = $Partition.size.split(" "); switch ($sizeinfo[1]) {
                    "GB" {
                        ([int]$SizeInfo[0] * 1073741824)
                    }"MB" {
                        ([int]$SizeInfo[0] * 1048576)
                    }default {
                        $SizeInfo[0]
                    }
                })
        }
    }
}
function Get-PartitionSupportedSize {
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipelineByPropertyName)]
        [int32]
        $DiskNumber,

        [parameter(ValueFromPipelineByPropertyName)]
        [int32]
        $PartitionNumber
    )

    $Disks = Get-CimInstance -ClassName Win32_DiskDrive

    if ($DiskNumber) {
        $Disks = $Disks | where { $_.Index -eq $DiskNumber }
    }

    $Parts = Get-CimInstance -ClassName Win32_DiskPartition
    if ($DiskNumber) {
        $Parts = $Parts | where { $_.DiskIndex -eq $DiskNumber }
    }

    if ($PartitionNumber) {
        $Parts = $parts | where { if ($_.type -like "*gpt*") {
                $_.index -eq $PartitionNumber - 2
            }
            else {
                $_.index -eq $PartitionNumber - 1
            }}
    }

    foreach ($Part in $Parts) {
        return [pscustomobject]@{
            SizeMax = $($PartitionSize = $_.Size - $_.StartingOffset
                $DiskSize = ($Disks | where { $_.Index -eq $part.diskIndex }).size
                if (($parts | where Diskindex -eq $part.diskindex | measure -Maximum index).maximum -eq $Part.Index) {
                    $DiskSize
                }
                else {
                    $PartitionSize.size
                })
            SizeMin = $(0)
        }
    }
}
function Get-Volume {
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipelineByPropertyName)]
        [Alias("Number")]
        [int32]
        $DiskNumber,

        [parameter(ValueFromPipelineByPropertyName)]
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

            return $_
        }
    }
}
function Format-Volume {
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [ValidateSet("NTFS")]
        [string]
        $FileSystem,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Partition
    )

    if ($PSCmdlet.ShouldProcess($Partition.PartitionNumber)) {
        Try {
            $Output = "select disk $($Partition.DiskNumber)`nselect partition $($Partition.PartitionNumber)`nFORMAT FS=NTFS QUICK" | diskpart
        }
        Catch {
            Write-Error $_
        }
    }
}
function Set-Partition {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32]
        $DiskNumber,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32]
        $PartitionNumber,

        [parameter(Mandatory)]
        [char]
        $NewDriveLetter
    )

    Try {
        $Output = "select disk $DiskNumber`nselect partition $PartitionNumber`nassign letter=$NewDriveLetter`n" | diskpart
    }
    Catch {
        Write-Error $_
    }
}
function Set-Disk {
    [cmdletbinding()]
    param(
        [parameter()]
        [nullable[bool]]
        $IsOffline,

        [parameter()]
        [nullable[bool]]
        $IsReadOnly,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $Number
    )

    $dpscript = "select disk $Number`n"
    if ($IsOffline -eq $true) {
        $dpscript += "offline disk`n"
    }
    if ($IsOffline -eq $false) {
        $dpscript += "online disk`n"
    }
    if ($IsReadOnly -eq $true) {
        $dpscript += "attributes disk set readonly`n"
    }
    if ($IsReadOnly -eq $false) {
        $dpscript += "attributes disk clear readonly`n"
    }
    Try {
        Write-Debug $dpscript
        $Output = $dpscript | diskpart
    }
    Catch {
        Write-Error $_
    }
}
function Set-Volume {
    [cmdletbinding()]
    param(
        [parameter()]
        [string]
        $NewFileSystemLabel,

        [parameter()]
        [char]
        $DriveLetter,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32]
        $DiskNumber,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32]
        $PartitionNumber
    )

    $dpscript = "select disk $DiskNumber`nselect partition $PartitionNumber`n"

    if (!$DriveLetter) {
        $DriveLetter = (get-partition -DiskNumber $PartObject.DiskNumber -PartitionNumber $PartObject.PartitionNumber).DriveLetter
    }
    if ([string]::IsNullOrWhiteSpace($DriveLetter)) {
        $Remove = $true
        $DriveLetter = "B"
    }
    if ($DriveLetter) {
        $dpscript += "assign letter=$DriveLetter`n"
    }
    Try {
        $Output = $dpscript | diskpart
    }
    Catch {
        Write-Error $_
    }
    if ($DriveLetter) {
        $drive = Get-WmiObject win32_volume -Filter "DriveLetter ='$DriveLetter`:'"
        $drive.Label = $NewFileSystemLabel
        $drive.put() | out-null
    }
    if ($Remove) {
        $Output = $Output.replace("assign", "remove")
        Try {
            $Output = $dpscript | diskpart
        }
        Catch {
            Write-Error $_
        }
    }
}
function Initialize-Disk {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32]
        $DiskNumber,

        [parameter(Mandatory)]
        [ValidateSet("GPT", "MBR")]
        [string]
        $PartitionStyle
    )

    Try {
        $Output = "select disk $DiskNumber`nclean`nconvert $PartitionStyle`n" | diskpart
    }
    Catch {
        Write-Error $_
    }
}
function New-Partition {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
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
    }
    else {
        $dpscript = "select disk $DiskNumber`ncreate partition primary`nList Partition`n"
    }

    Try {
        $Output = $dpscript | diskpart
        $Parts = ($Output.split("`n") | where { $_ -match "Partition (\d+)"}).substring(12, 5).trimend()
        $PartNumber = $Parts[$Parts.length - 1]
    }
    Catch {
        Write-Error $_
    }
    return Get-Partition -DiskNumber $DiskNumber -PartitionNumber $PartNumber
}
function Resize-Partition {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [int]
        $DiskNumber,

        [Parameter(Mandatory)]
        [int]
        $PartitionNumber,

        [parameter()]
        [uint64]
        $Size
    )
    [int]$Size = $Size / 1073741824
    $dpscript = "select disk $DiskNumber`nselect partition $PartitionNumber`nextend"
    #if($Size){ $dpscript += "Size=$Size" }
    $dpscript += "`n"
    Try {
        $Output = $dpscript | diskpart
    }
    Catch {
        Write-Error $_
    }
}
function Update-HostStorageCache {
    [cmdletbinding()]
    param()

    process {
        "refresh" | diskpart
    }
}
