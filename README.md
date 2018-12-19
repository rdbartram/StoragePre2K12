# StoragePre2K12

> ☠👼 StoragePre2K12 is hopefully a dead project. I say that because I sincerely hope nobody is running servers
> running OSs older than 2012. However, I know this is the case and so thi module exists.

StoragePre2K12 is the only (as far as I'm aware) module that provides support to running "modern" storage commands
on pre 2012 servers. I've used it in conjunction with [StorageDSC](https://github.com/powershell/storagedsc) as well
as part of inplace upgrades going from pre 2012 to post 2012....🚀

🐱‍💻 StoragePre2K12 is built and tested in Azure DevOps and is distributed via the PowerShell gallery.

[![pester](https://img.shields.io/azure-devops/tests/rdbartram/GitHubPipelines/3.svg?label=pester&logo=azuredevops&style=for-the-badge)](https://dev.azure.com/rdbartram/GithubPipelines/_build/latest?definitionId=3?branchName=master)
[![latest version](https://img.shields.io/powershellgallery/v/StoragePre2K12.svg?label=latest+version&style=for-the-badge)](https://www.powershellgallery.com/packages/StoragePre2K12)
[![downloads](https://img.shields.io/powershellgallery/dt/StoragePre2K12.svg?label=downloads&style=for-the-badge)](https://www.powershellgallery.com/packages/StoragePre2K12)



## Installation

Begrudgingly StoragePre2K12 is compatible with Windows PowerShell 2.x - 5.x on Windows 10, 8, 7, Vista and even 2003.
Obviously it is also compatible with PowerShell Core 6.x on Windows.

Pester comes pre-installed with Windows 10, but we recommend updating, by running this PowerShell command _as administrator_:

```powershell
Install-Module -Name StoragePre2K12 -Force
```

## Features

### WMI Class Data

Since the newer versions of Windows have nice classes which return all of the storage data as you need it, StoragePre2K12
tries to emulate that functionatlity by build custom PowerShell Objects which contain all the necessary properties and
methods you would need.

### Disk Part Proxy

Many of the CIM Methods used in new versions of Windows aren't available in Pre2K12 world, hence the module uses DiskPart
to bother gather data as well as execute commands such as create, delete, format & mount disks, partitions and volumes.


## Further reading

If you're looking to upgrade to the latest version of Windows, you'll get all the benefits of the latest [Storage module](https://docs.microsoft.com/en-us/powershell/module/storage).

## Got questions?

Got questions or you just want to get in touch? Use our issues page or one of these channels:

[![Pester Twitter](https://img.icons8.com/color/96/000000/twitter.png)](https://twitter.com/rd_bartram)
