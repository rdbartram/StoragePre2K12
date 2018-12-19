function Update-HostStorageCache {
    [cmdletbinding()]
    param()

    process {
        "rescan" | diskpart | Out-Null
    }
}
