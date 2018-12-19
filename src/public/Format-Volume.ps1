function Format-Volume {
    [cmdletbinding(SupportsShouldProcess = $true)]
    param(
        [ValidateSet("NTFS")]
        [string]
        $FileSystem,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $Partition
    )

    if ($PSCmdlet.ShouldProcess($Partition.PartitionNumber)) {
        Try {
            $Output = "select disk $($Partition.DiskNumber)`nselect partition $($Partition.PartitionNumber)`nFORMAT FS=NTFS QUICK" | diskpart
        } Catch {
            Write-Error $_
        }
    }
}
