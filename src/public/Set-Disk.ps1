function Set-Disk {
    [cmdletbinding()]
    param(
        [parameter()]
        [nullable[bool]]
        $IsOffline,

        [parameter()]
        [nullable[bool]]
        $IsReadOnly,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
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
    } Catch {
        Write-Error $_
    }
}
