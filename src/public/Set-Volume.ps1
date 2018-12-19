function Set-Volume {
    [cmdletbinding()]
    param(
        [parameter()]
        [string]
        $NewFileSystemLabel,

        [parameter()]
        [char]
        $DriveLetter,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [int32]
        $DiskNumber,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
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
    } Catch {
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
        } Catch {
            Write-Error $_
        }
    }
}
