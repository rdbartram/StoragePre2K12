function ConvertFrom-SizeString {
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        [string]
        $String
    )

    process {
        switch -Regex ($String) {
            '^\d+ ?TB$' {
                [int64]$String.Replace('TB', '') * 1TB
            }

            '^\d+ ?GB$' {
                [int64]$String.Replace('GB', '') * 1GB
            }

            '^\d+ ?MB$' {
                [int64]$String.Replace('MB', '') * 1MB
            }

            '^\d+ ?KB$' {
                [int64]$String.Replace('KB', '') * 1KB
            }


            '^\d+ ?B$' {
                [int64]$String.Replace('B', '') * 1
            }
        }
    }
}
