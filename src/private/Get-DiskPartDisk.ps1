function Get-DiskPartDisk {
    [OutputType('System.Management.Automation.PSObject')]
    [CmdletBinding()]
    param (
    )

    # read disks from disk part
    $Output = "list disk" | diskpart

    ForEach ($Line in $Output -match '  Disk \d+') {
        try {
            # use regex to retrieve data from table
            if ($Line -Match "  Disk (?<disknum>...) +(?<sts>.............) +(?<sz>.......) +(?<fr>.......) +(?<dyn>...) +(?<gpt>...)") {

                # create new disk object
                $Disk = [pscustomobject]@{
                    ComputerName         = $env:COMPUTERNAME
                    DiskNumber           = $Matches['disknum'].Trim()
                    Status               = $Matches['sts'].Trim()
                    Size                 = $Matches['sz'].Trim() | ConvertFrom-SizeString
                    Free                 = $Matches['fr'].Trim() | ConvertFrom-SizeString
                    Dyn                  = $Matches['dyn'].Trim()
                    PartitionStyle       = ""
                    DiskID               = ""
                    DetailType           = ""
                    DetailStatus         = ""
                    Path                 = ""
                    Target               = ""
                    LUNID                = ""
                    LocationPath         = ""
                    CurrentReadOnlyState = ""
                    ReadOnly             = ""
                    BootDisk             = ""
                    PagefileDisk         = ""
                    HibernationFileDisk  = ""
                    CrashdumpDisk        = ""
                    ClusteredDisk        = ""
                }

                # retrieve detailed disk data and loop data
                Foreach ($line in ("select disk $($Disk.DiskNumber)`ndetail disk" | diskpart)) {
                    If ($Line -cmatch "Disk ID" -and $Line -match ":") {
                        $Disk.DiskID = $Line.Split(":")[1].Trim()
                    } ElseIf ($Line.StartsWith("Type") -and $Line -match ":") {
                        $Disk.DetailType = $Line.Split(":")[1].Trim()
                    } ElseIf ($Line.StartsWith("Status") -and $Line -match ":") {
                        $Disk.DetailStatus = $Line.Split(":")[1].Trim()
                    } ElseIf ($Line.StartsWith("Path") -and $Line -match ":") {
                        $Disk.Path = $Line.Split(":")[1].Trim()
                    } ElseIf ($Line.StartsWith("Target") -and $Line -match ":") {
                        $Disk.Target = $Line.Split(":")[1].Trim()
                    } ElseIf ($Line.StartsWith("LUN ID") -and $Line -match ":") {
                        $Disk.LUNID = $Line.Split(":")[1].Trim()
                    } ElseIf ($Line.StartsWith("Location Path") -and $Line -match ":") {
                        $Disk.LocationPath = $Line.Split(":")[1].Trim()
                    } ElseIf ($Line.StartsWith("Current Read-only State") -and $Line -match ":") {
                        $Disk.CurrentReadOnlyState = $Line.Split(":")[1].Trim()
                    } ElseIf ($Line.StartsWith("Read-only") -and $Line -match ":") {
                        $Disk.ReadOnly = $Line.Split(":")[1].Trim()
                    } ElseIf ($Line.StartsWith("Boot Disk") -and $Line -match ":") {
                        $Disk.BootDisk = $Line.Split(":")[1].Trim()
                    } ElseIf ($Line.StartsWith("Pagefile Disk") -and $Line -match ":") {
                        $Disk.PagefileDisk = $Line.Split(":")[1].Trim()
                    } ElseIf ($Line.StartsWith("Hibernation File Disk") -and $Line -match ":") {
                        $Disk.HibernationFileDisk = $Line.Split(":")[1].Trim()
                    } ElseIf ($Line.StartsWith("Crashdump Disk") -and $Line -match ":") {
                        $Disk.CrashdumpDisk = $Line.Split(":")[1].Trim()
                    } ElseIf ($Line.StartsWith("Clustered Disk") -and $Line -match ":") {
                        $Disk.ClusteredDisk = $Line.Split(":")[1].Trim()
                    }
                }

                # retrieve detailed disk data and loop data
                Foreach ($line in ("select disk $($Disk.DiskNumber)`nUniqueID Disk" | diskpart)) {
                    If ($Line -cmatch "Disk ID" -and $Line -match ":") {
                        $DiskID = $Line.replace("Disk ID: ", "").Trim()

                        # if DiskID is a guid then partitionstyle is GPT
                        # otherwises its RAW, MBR or something else
                        if ([guid]::TryParse($DiskID, ([ref]$DiskID))) {
                            $Disk.PartitionStyle = "GPT"
                        } else {
                            if ($DiskID -eq "00000000") {
                                $Disk.PartitionStyle = "RAW"
                            } elseif ($DiskID -match "^[\d\w]{8}$") {
                                $Disk.PartitionStyle = "MBR"
                            } else {
                                $Disk.PartitionStyle = "Unknown"
                            }
                        }
                    }
                }

                # return disk
                $Disk
            }
        } Catch {
            Write-Error $_
            Continue
        }
    }
}
