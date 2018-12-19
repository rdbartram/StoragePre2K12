function Add-ObjectDetail {
    [CmdletBinding()]
    param(
        [Parameter( Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true )]
        [ValidateNotNullOrEmpty()]
        [psobject[]]$InputObject,

        [Parameter( Mandatory = $false,
            Position = 1)]
        [string]$TypeName,

        [Parameter( Mandatory = $false,
            Position = 2)]
        [System.Collections.Hashtable]$PropertyToAdd,

        [Parameter( Mandatory = $false,
            Position = 3)]
        [ValidateNotNullOrEmpty()]
        [Alias('dp')]
        [System.String[]]$DefaultProperties,

        [boolean]$Passthru = $True
    )

    Begin {
        if ($PSBoundParameters.ContainsKey('DefaultProperties')) {
            # define a subset of properties
            $ddps = New-Object System.Management.Automation.PSPropertySet DefaultDisplayPropertySet, $DefaultProperties
            $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]$ddps
        }
    }
    Process {
        foreach ($Object in $InputObject) {
            switch ($PSBoundParameters.Keys) {
                'PropertyToAdd' {
                    foreach ($Key in $PropertyToAdd.Keys) {
                        #Add some noteproperties. Slightly faster than Add-Member.
                        $Object.PSObject.Properties.Add( ( New-Object System.Management.Automation.PSNoteProperty($Key, $PropertyToAdd[$Key]) ) )
                    }
                }
                'TypeName' {
                    #Add specified type
                    [void]$Object.PSObject.TypeNames.Insert(0, $TypeName)
                }
                'DefaultProperties' {
                    # Attach default display property set
                    Add-Member -InputObject $Object -MemberType MemberSet -Name PSStandardMembers -Value $PSStandardMembers
                }
            }
            if ($Passthru) {
                $Object
            }
        }
    }
}
