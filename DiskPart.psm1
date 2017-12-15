function Get-DiskPartDisk {
    [OutputType('System.Management.Automation.PSObject')]
    [CmdletBinding()]
    param (
    )

    $Output = "list disk`n" | diskpart

    $Disks = ForEach ($Line in $Output) {
        If ($Line.StartsWith("  Disk")) {
            $Line
        }
    }

    $DiskCount = $Disks.Count

    For ($i = 1; $i -le ($DiskCount - 1); $i++) {
        $currLine = $Disks[$i]
        $currLine -Match "  Disk (?<disknum>...) +(?<sts>.............) +(?<sz>.......) +(?<fr>.......) +(?<dyn>...) +(?<gpt>...)" | Out-Null
        $DiskObj = @{
            "ComputerName" = $Computer
            "DiskNumber"   = $Matches['disknum'].Trim()
            "Status"       = $Matches['sts'].Trim()
            "Size"         = $Matches['sz'].Trim()
            "Free"         = $Matches['fr'].Trim()
            "Dyn"          = $Matches['dyn'].Trim()
            "Gpt"          = $Matches['gpt'].Trim()
        }

        Try {
            $Output = "select disk $($DiskObj.DiskNumber)`ndetail disk`n" | diskpart
        }
        Catch {
            Write-Error $_
            Continue
        }

        ForEach ($Line in $Output) {
            If ($Line -cmatch "Disk ID" -and $Line -match ":") {
                $DiskObj.Add( "DiskID", $Line.Split(":")[1].Trim())
            }
            ElseIf ($Line.StartsWith("Type") -and $Line -match ":") {
                $DiskObj.Add( "DetailType", $Line.Split(":")[1].Trim())
            }
            ElseIf ($Line.StartsWith("Status") -and $Line -match ":") {
                $DiskObj.Add( "DetailStatus", $Line.Split(":")[1].Trim())
            }
            ElseIf ($Line.StartsWith("Path") -and $Line -match ":") {
                $DiskObj.Add( "Path", $Line.Split(":")[1].Trim())
            }
            ElseIf ($Line.StartsWith("Target") -and $Line -match ":") {
                $DiskObj.Add( "Target", $Line.Split(":")[1].Trim())
            }
            ElseIf ($Line.StartsWith("LUN ID") -and $Line -match ":") {
                $DiskObj.Add( "LUNID", $Line.Split(":")[1].Trim())
            }
            ElseIf ($Line.StartsWith("Location Path") -and $Line -match ":") {
                $DiskObj.Add( "LocationPath", $Line.Split(":")[1].Trim())
            }
            ElseIf ($Line.StartsWith("Current Read-only State") -and $Line -match ":") {
                $DiskObj.Add( "CurrentReadOnlyState", $Line.Split(":")[1].Trim())
            }
            ElseIf ($Line.StartsWith("Read-only") -and $Line -match ":") {
                $DiskObj.Add( "ReadOnly", $Line.Split(":")[1].Trim())
            }
            ElseIf ($Line.StartsWith("Boot Disk") -and $Line -match ":") {
                $DiskObj.Add( "BootDisk", $Line.Split(":")[1].Trim())
            }
            ElseIf ($Line.StartsWith("Pagefile Disk") -and $Line -match ":") {
                $DiskObj.Add( "PagefileDisk", $Line.Split(":")[1].Trim())
            }
            ElseIf ($Line.StartsWith("Hibernation File Disk") -and $Line -match ":") {
                $DiskObj.Add(  "HibernationFileDisk", $Line.Split(":")[1].Trim())
            }
            ElseIf ($Line.StartsWith("Crashdump Disk") -and $Line -match ":") {
                $DiskObj.Add( "CrashdumpDisk", $Line.Split(":")[1].Trim())
            }
            ElseIf ($Line.StartsWith("Clustered Disk") -and $Line -match ":") {
                $DiskObj.Add( "ClusteredDisk", $Line.Split(":")[1].Trim())
            }
        }

        Try {
            $Output = "select disk $($DiskObj.DiskNumber)`nUniqueID Disk`n" | diskpart
        }
        Catch {
            Write-Error $_
            Continue
        }

        ForEach ($Line in $Output) {
            If ($Line -cmatch "Disk ID" -and $Line -match ":") {
                $DiskID = $Line.replace("Disk ID: ", "").Trim()

                try {
                    [guid]::Parse($DiskID) | Out-Null ; $DiskObj.Add( "PartitionStyle", "GPT")
                }
                catch {
                    if ($DiskID -eq "00000000") {
                        $DiskObj.Add( "PartitionStyle", "RAW")
                    }
                    else {
                        if ($DiskID -match "^[\d\w]{8}$") {
                            $DiskObj.Add( "PartitionStyle", "MBR") | Out-Null
                        }
                        else {
                            $DiskObj.Add( "PartitionStyle", "Unknown")
                        }
                    }
                }
            }
        }

        foreach ($part in $DiskObj) {
            [pscustomobject]@{
                ComputerName         = $part.ComputerName
                DiskNumber           = $part.DiskNumber
                Status               = $part.Status
                Size                 = $part.Size
                Free                 = $part.Free
                Dyn                  = $part.Dyn
                PartitionStyle       = $part.PartitionStyle
                DiskID               = $part.DiskID
                DetailType           = $part.DetailType
                DetailStatus         = $part.DetailStatus
                Path                 = $part.Path
                Target               = $part.Target
                LUNID                = $part.LUNID
                LocationPath         = $part.LocationPath
                CurrentReadOnlyState = $part.CurrentReadOnlyState
                ReadOnly             = $part.ReadOnly
                BootDisk             = $part.BootDisk
                PagefileDisk         = $part.PagefileDisk
                HibernationFileDisk  = $part.HibernationFileDisk
                CrashdumpDisk        = $part.CrashdumpDisk
                ClusteredDisk        = $part.ClusteredDisk
            }
        }
    }
}

function Get-DiskPartPartition {
    [OutputType('System.Management.Automation.PSObject')]
    [CmdletBinding()]
    param (
    )

    Try {
        $Output = "list disk`n" | diskpart
    }
    Catch {
        Write-Error $_
        Continue
    }

    $Disks = ForEach ($Line in $Output) {
        If ($Line -match "^. Disk \d") {
            $Line
        }
    }
    $DiskCount = $Disks.Count

    For ($i = 0; $i -le ($DiskCount - 1); $i++) {
        $DiskNumber = $i
        Try {
            $Output = "Select disk $i`nlist partition`n" | diskpart
        }
        Catch {
            Write-Error $_
            Continue
        }

        $Partitions = @()
        ForEach ($Line in $Output) {
            If ($Line -match "^. Partition \d") {
                $Partitions += $Line
            }
        }

        $PartCount = $Partitions.Count

        For ($p = 0; $p -le ($Partcount - 1); $p++) {
            $Line = $Partitions[$p]
            If ($Line.StartsWith("  Partition")) {
                $Line -Match ". Partition (?<partnum>...) +(?<type>................) +(?<size>\d+ [MBG][ B]) +(?<offset>.......)" | Out-Null
                $PartObj = @{
                    "ComputerName"    = $Computer
                    "PartitionNumber" = $Matches['partnum'].Trim()
                    "DiskNumber"      = $DiskNumber
                    "Size"            = $Matches['size'].Trim()
                    "Offset"          = $Matches['offset'].Trim()
                }

                foreach ($part in $PartObj) {
                      [pscustomobject]@{
                        ComputerName    = $part.ComputerName
                        PartitionNumber = $part.PartitionNumber
                        DiskNumber      = $part.DiskNumber
                        Size            = $part.Size
                        Offset          = $part.Offset
                    }
                }
            }
        }
    }
}

function Add-ObjectDetail {
    [CmdletBinding()]
    param(
        [Parameter( Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true )]
        [ValidateNotNullOrEmpty()]
        [psobject[]]$InputObject,

        [Parameter( Mandatory = $false,
            Position = 1)]
        [string]$TypeName,

        [Parameter( Mandatory = $false,
            Position = 2)]
        [System.Collections.Hashtable]$PropertyToAdd,

        [Parameter( Mandatory = $false,
            Position = 3)]
        [ValidateNotNullOrEmpty()]
        [Alias('dp')]
        [System.String[]]$DefaultProperties,

        [boolean]$Passthru = $True
    )

    Begin {
        if ($PSBoundParameters.ContainsKey('DefaultProperties')) {
            # define a subset of properties
            $ddps = New-Object System.Management.Automation.PSPropertySet DefaultDisplayPropertySet, $DefaultProperties
            $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]$ddps
        }
    }
    Process {
        foreach ($Object in $InputObject) {
            switch ($PSBoundParameters.Keys) {
                'PropertyToAdd' {
                    foreach ($Key in $PropertyToAdd.Keys) {
                        #Add some noteproperties. Slightly faster than Add-Member.
                        $Object.PSObject.Properties.Add( ( New-Object System.Management.Automation.PSNoteProperty($Key, $PropertyToAdd[$Key]) ) )
                    }
                }
                'TypeName' {
                    #Add specified type
                    [void]$Object.PSObject.TypeNames.Insert(0, $TypeName)
                }
                'DefaultProperties' {
                    # Attach default display property set
                    Add-Member -InputObject $Object -MemberType MemberSet -Name PSStandardMembers -Value $PSStandardMembers
                }
            }
            if ($Passthru) {
                $Object
            }
        }
    }
}

function Get-DiskPartVolume {
    [OutputType('System.Management.Automation.PSObject')]
    [CmdletBinding()]
    param (
    )

    Try {
        $Output = "list disk`n" | diskpart
    }
    Catch {
        Write-Error $_
        Continue
    }

    $Disks = ForEach ($Line in $Output) {
        If ($Line -match "^. Disk \d") {
            $Line
        }
    }
    $DiskCount = $Disks.Count

    For ($i = 0; $i -le ($DiskCount - 1); $i++) {
        $DiskNumber = $i
        Try {
            $Output = "Select disk $i`nlist partition`n" | diskpart
        }
        Catch {
            Write-Error $_
            Continue
        }

        $Partitions = @()
        ForEach ($Line in $Output) {
            If ($Line -match "^. Partition \d") {
                $Partitions += $Line
            }
        }

        $PartCount = $Partitions.Count

        For ($p = 1; $p -le ($Partcount); $p++) {
            $PartNumber = $p
            Try {
                $Output = "Select disk $i`nSelect partition $p`nlist Volume`n" | diskpart
            }
            Catch {
                Write-Error $_
                Continue
            }

            $Vol = $null; $Mounts = @()
            ForEach ($Line in $Output.Split([environment]::NewLine)) {
                If ($Line -match "^[*] Volume \d") {
                    $Vol = $Line
                    $Mounts = @()
                }
                elseif ($Line -match '\s{4}(?<path>[a-zA-Z]:\\\S+)' -and $Line -notmatch '\s{4}[a-zA-Z]:\\\$Recycle' -and $Vol) {
                    $Mounts += $Matches["path"]
                }
                elseif ($Line -match "^\s{2}Volume" -and $Vol) {
                    break
                }
            }
            if ($Vol -Match "[*] Volume (?<volnum>...) +(?<drltr>...) +(?<lbl>...........) +(?<fs>.....) +(?<typ>..........) +(?<sz>.......) +(?<sts>.........) +(?<nfo>........)" -eq $true) {
                $VolObj = @{
                    "ComputerName"    = $Computer
                    "VolumeNumber"    = $Matches['volnum'].Trim()
                    "DiskNumber"      = $DiskNumber
                    "PartitionNumber" = $PartNumber
                    "DriveLetter"     = $Matches['drltr'].Trim()
                    "FileSystemLabel" = $Matches['lbl'].Trim()
                    "FileSystem"      = $Matches['fs'].Trim()
                    "DriveType"       = $Matches['typ'].Trim()
                    "Size"            = $Matches['sz'].Trim()
                    "HealthStatus"    = $Matches['sts'].Trim()
                    "Type"            = $Matches['nfo'].trim()
                    "Mountpoint"      = $Mounts
                }

                foreach ($part in $VolObj) {

                    [pscustomobject]@{
                        ComputerName    = $part.ComputerName
                        VolumeNumber    = $part.VolumeNumber
                        DiskNumber      = $part.DiskNumber
                        PartitionNumber = $part.PartitionNumber
                        DriveLetter     = $part.DriveLetter
                        FileSystemLabel = $part.FileSystemLabel
                        FileSystem      = $part.FileSystem
                        DriveType       = $part.DriveType
                        Size            = $part.Size
                        HealthStatus    = $part.HealthStatus
                        Type            = $part.Type
                        MountPoint      = $part.Mountpoint
                    }
                }
            }
        }
    }
}
