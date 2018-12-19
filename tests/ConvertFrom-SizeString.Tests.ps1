#requires -Modules Pester

$ScriptName = "ConvertFrom-SizeString"

$here = (Split-Path -Parent $MyInvocation.MyCommand.Path)

# Import Functions from script
. (Resolve-Path "$here\..\src\private\$ScriptName.ps1")

describe $ScriptName {

    it "should return <value> when passed <string>" -TestCases @(
        @{ string="2 TB"; Value = 2TB }
        @{ string="20 GB"; Value = 20GB }
        @{ string="40 MB"; Value = 40MB }
        @{ string="200 KB"; Value = 200KB }
        @{ string="300 B"; Value = 300 }
    ) {
        param($string, $value)

        $String | ConvertFrom-SizeString | Should -Be $Value
    }
}
