function Get-DiskPartVolume {
    [OutputType('System.Management.Automation.PSObject')]
    [CmdletBinding()]
    param (
    )

    Try {
        $Output = "list disk`n" | diskpart
    } Catch {
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
        } Catch {
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
            } Catch {
                Write-Error $_
                Continue
            }

            $Vol = $null; $Mounts = @()
            ForEach ($Line in $Output) {
                If ($Line -match "^[*] Volume \d") {
                    $Vol = $Line
                    $Mounts = @()
                } elseif ($Line -match '\s{4}(?<path>[a-zA-Z]:\\\S+)' -and $Line -notmatch '\s{4}[a-zA-Z]:\\\$Recycle' -and $Vol) {
                    $Mounts += $Matches["path"]
                } elseif ($Line -match "^\s{2}Volume" -and $Vol) {
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
