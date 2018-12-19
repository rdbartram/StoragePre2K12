#requires -Modules Pester

$ScriptName = "Get-DiskPartDisk"

$here = (Split-Path -Parent $MyInvocation.MyCommand.Path)

# Import Functions from script
. (Resolve-Path "$here\..\src\private\$ScriptName.ps1")

$DiskMembers = @("BootDisk",
    "ClusteredDisk",
    "ComputerName",
    "CrashdumpDisk",
    "CurrentReadOnlyState",
    "DetailStatus",
    "DetailType",
    "DiskID",
    "DiskNumber",
    "Dyn",
    "Free",
    "HibernationFileDisk",
    "LocationPath",
    "LUNID",
    "PagefileDisk",
    "PartitionStyle",
    "Path",
    "ReadOnly",
    "Size",
    "Status",
    "Target")

describe $ScriptName {

    BeforeAll {
        $(gci $here\..\src\public) + $(gci $here\..\src\private) | % { . $_.fullname }

        $ObjectMother = Get-Content $here\ObjectMother\DiskPart.json -Raw | ConvertFrom-Json
        function diskpart ([parameter(ValueFromPipeline)][string]$t) {}

        mock DiskPart -ParameterFilter { $t -match "list disk"} {
            $($ObjectMother.Header.foreach{$_}
                $ObjectMother.prompt

                $ObjectMother.headerlist.foreach{$_}
                $ObjectMother.Disks.list.foreach{$_}

                $ObjectMother.prompt)
        }

        mock DiskPart -ParameterFilter { $t -match "select disk (\d)`ndetail disk" } {
            if ($t -match "select disk (\d)`ndetail disk") {
                $($ObjectMother.Header.foreach{$_}
                    $ObjectMother.prompt

                    $ObjectMother.Disks.where{$_.id -eq $matches[1]}.detail.foreach{$_}

                    $ObjectMother.prompt)
            }
        }
        mock DiskPart -ParameterFilter { $t -match "select disk (\d)`nUniqueID disk" } {
            if ($t -match "select disk (\d)`nUniqueID disk") {
                $($ObjectMother.Header.foreach{$_}
                    $ObjectMother.prompt

                    $ObjectMother.Disks.where{$_.id -eq $matches[1]}.UniqueID.foreach{$_}

                    $ObjectMother.prompt)
            }
        }
    }

    it "should return PSCustomObject with correct properties" {
        $Disk = Get-DiskPartDisk

        $Disk | Should -BeOfType [PSCustomObject]

        $Disk.Count | Should -Be $ObjectMother.Disks.Count

        $Disk.PSObject.Members.Where{$_.Type -eq "NoteProperty"}.Name.Foreach{
            $_ | Should -BeIn $DiskMembers -Because "DiskObject should have property $_"
        }
    }

    # it "should pass all the parameters to the Get-AzureStorageTableTable and Add-StorageTableRow commands" -TestCases (
    #     $TestCases.where{ $_.type -in "Information"}
    # ) {
    #     Param (
    #         $TestData
    #     )

    #     mock Get-AzureRMContext { return $ObjectMother.AzureContextTestData }

    #     Write-AzureTableEntry @TestData

    #     Assert-MockCalled -CommandName "Get-AzureStorageTableTable" -Times 1 -Scope It -ParameterFilter {
    #         $storageAccountName -eq $TestData.StorageAccountName
    #         $resourceGroup -eq $TestData.ResourceGroupName
    #     }

    #     Assert-MockCalled -CommandName "Add-StorageTableRow" -Times 1 -Scope It -ParameterFilter {
    #         $Property.Solution -eq $TestData.Solution -and
    #         $Property.Type -eq $TestData.Type.ToLower() -and
    #         $Property.JobId -eq $TestData.JobId -and
    #         $Property.Message -eq $TestData.Message -and
    #         $Property.PowerShellTimeStamp -eq $TestData.TimeStamp -and
    #         $Property.StructuredData -eq ($TestData.StructuredData | ConvertTo-Json -Depth 99 -Compress)
    #     }
    # }
}
