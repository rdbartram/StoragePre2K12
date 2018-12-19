function Resize-Partition {
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [int]
        $DiskNumber,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
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
    } Catch {
        Write-Error $_
    }
}
