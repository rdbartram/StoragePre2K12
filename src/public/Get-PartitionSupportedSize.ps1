function Get-PartitionSupportedSize {
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [int32]
        $DiskNumber,

        [parameter(ValueFromPipelineByPropertyName = $true)]
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
            } else {
                $_.index -eq $PartitionNumber - 1
            }}
    }

    foreach ($Part in $Parts) {

        $OutPut = New-Object PSObject
        $OutPut | Add-Member -MemberType NoteProperty -Name "SizeMax" -Value $($PartitionSize = $Part.Size - $Part.StartingOffset
            $DiskSize = ($Disks | where { $_.Index -eq $part.diskIndex }).size
            if (($parts | where {$_.Diskindex -eq $part.diskindex | measure -Maximum index -ErrorAction SilentlyContinue}).maximum -eq $Part.Index) {
                $DiskSize
            } else {
                $PartitionSize
            })
        $OutPut | Add-Member -MemberType NoteProperty -Name "SizeMin" -Value $(0)
        $OutPut
    }
}
