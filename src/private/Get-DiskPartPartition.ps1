function Get-DiskPartPartition {
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
