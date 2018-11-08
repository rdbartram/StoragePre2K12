function Get-Disk {
    [cmdletbinding()]
    param(
        [parameter()]
        [string]
        $FriendlyName,

        [parameter()]
        [string]
        $SerialNumber,

        [parameter(ValueFromPipelineByPropertyName=$true)]
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
            }
            else {
                $false
            })
        $OutPut | Add-Member -MemberType NoteProperty -Name "FirmwareVersion" -Value $Disk.FirmwareVersion
            $OutPut | Add-Member -MemberType NoteProperty -Name "FriendlyName" -Value $Disk.Caption
            $OutPut | Add-Member -MemberType NoteProperty -Name "Guid" -Value ($DiskPart | where {$_.DiskNumber -eq $Disk.Index}).DiskID
            $OutPut | Add-Member -MemberType NoteProperty -Name "IsBoot" -Value $(if (($DiskPart | where {$_.DiskNumber -eq $Disk.Index}).BootDisk -eq "Yes") {
                $true
            }
            else {
                $false
            })
        $OutPut | Add-Member -MemberType NoteProperty -Name "IsClustered" -Value $(if (($DiskPart | where {$_.DiskNumber -eq $Disk.Index}).ClusteredDisk -eq "Yes") {
                $true
            }
            else {
                $false
            })
            $OutPut | Add-Member -MemberType NoteProperty -Name "IsOffline" -Value $(if (($DiskPart | where {$_.DiskNumber -eq $Disk.Index}).Status -eq "Online") {
                $false
            }
            else {
                $true
            })
            $OutPut | Add-Member -MemberType NoteProperty -Name "IsReadOnly" -Value $(if (($DiskPart | where {$_.DiskNumber -eq $Disk.Index}).ReadOnly -eq "Yes") {
                $true
            }
            else {
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
function Get-Partition {
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipelineByPropertyName=$true)]
        [Alias("Number")]
        [int32]
        $DiskNumber,

        [parameter(ValueFromPipelineByPropertyName=$true)]
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
                }
                else {
                    "Basic"
                })
        $OutPut | Add-Member -MemberType NoteProperty -Name "IsSystem" -Value $($p = $Partition; $Vol = ($Vols | where {$_.DiskNumber -eq $p.DiskNumber -and $_.PartitionNumber -eq $p.PartitionNumber }); if ($vol.Type -eq "System" -or !$vol) {
                    $true
                }
                else {
                    $false
                })
        $OutPut | Add-Member -MemberType NoteProperty -Name "Size" -Value $(if($Partition.Size){$($sizeinfo = $Partition.size.split(" "); switch ($sizeinfo[1]) {
                    "GB" {
                        ([int]$SizeInfo[0] * 1073741824)
                    }"MB" {
                        ([int]$SizeInfo[0] * 1048576)
                    }default {
                        $SizeInfo[0]
                    }
                })})
        $OutPut
    }
}
function Get-PartitionSupportedSize {
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipelineByPropertyName=$true)]
        [int32]
        $DiskNumber,

        [parameter(ValueFromPipelineByPropertyName=$true)]
        [int32]
        $PartitionNumber
    )

    $Disks = Get-WmiObject Win32_DiskDrive
    $Parts = Get-WmiObject Win32_DiskPartition

    if ($PSBoundParameters.ContainsKey("DiskNumber")) {
        $Disks = $Disks | where {$_.Index -eq $DiskNumber }
        $Parts = $Parts | where { $_.DiskIndex -eq $DiskNumber }
    }

    if ($PSBoundParameters.ContainsKey("PartitionNumber")) {
        $Parts = $parts | where { if ($_.type -like "*gpt*") {
                $_.index -eq $PartitionNumber - 2
            }
            else {
                $_.index -eq $PartitionNumber - 1
            }}
    }

    foreach ($Part in $Parts) {

        $OutPut = New-Object PSObject
        $OutPut | Add-Member -MemberType NoteProperty -Name "SizeMax" -Value $($PartitionSize = $Part.Size - $Part.StartingOffset
                $DiskSize = ($Disks | where { $_.Index -eq $part.diskIndex }).size
                if (($parts | where {$_.Diskindex -eq $part.diskindex | measure -Maximum index -ErrorAction SilentlyContinue}).maximum -eq $Part.Index) {
                    $DiskSize
                }
                else {
                    $PartitionSize
                })
        $OutPut | Add-Member -MemberType NoteProperty -Name "SizeMin" -Value $(0)
        $OutPut
    }
}
function Get-Volume {
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipelineByPropertyName=$true)]
        [Alias("Number")]
        [int32]
        $DiskNumber,

        [parameter(ValueFromPipelineByPropertyName=$true)]
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
function Format-Volume {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param(
        [ValidateSet("NTFS")]
        [string]
        $FileSystem,

        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
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
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int32]
        $DiskNumber,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int32]
        $PartitionNumber,

        [parameter(Mandatory=$true)]
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

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
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

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int32]
        $DiskNumber,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
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
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int32]
        $DiskNumber,

        [parameter(Mandatory=$true)]
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
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
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
    Get-Partition -DiskNumber $DiskNumber -PartitionNumber $PartNumber
}
function Resize-Partition {
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int]
        $DiskNumber,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
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
        "rescan" | diskpart | Out-Null
    }
}
