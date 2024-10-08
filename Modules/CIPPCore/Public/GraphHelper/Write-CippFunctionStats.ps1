function Write-CippFunctionStats {
    <#
    .FUNCTIONALITY
    Internal
    #>
    Param(
        [string]$FunctionType,
        $Entity,
        [datetime]$Start,
        [datetime]$End,
        [string]$ErrorMsg = ''
    )
    try {
        $Table = Get-CIPPTable -tablename CippFunctionStats
        $RowKey = [string](New-Guid).Guid
        $TimeSpan = New-TimeSpan -Start $Start -End $End
        $Duration = [int]$TimeSpan.TotalSeconds
        $DurationMS = [int]$TimeSpan.TotalMilliseconds

        $StatEntity = @{}
        # Flatten data to json string
        $StatEntity.PartitionKey = $FunctionType
        $StatEntity.RowKey = $RowKey
        $StatEntity.Start = $Start.ToUniversalTime()
        $StatEntity.End = $End.ToUniversalTime()
        $StatEntity.Duration = $Duration
        $StatEntity.DurationMS = $DurationMS
        $StatEntity.ErrorMsg = $ErrorMsg
        $Entity = [PSCustomObject]$Entity
        foreach ($Property in $Entity.PSObject.Properties.Name) {
            if ($Entity.$Property) {
                if ($Entity.$Property.GetType().Name -in ('Hashtable', 'PSCustomObject', 'OrderedHashtable')) {
                    $StatEntity.$Property = [string]($Entity.$Property | ConvertTo-Json -Compress)
                } elseif ($Entity.$Property.GetType().Name -eq 'DateTime' -and $Entity.$Property.Kind -eq 'Local') {
                    $StatEntity.$Property = $Entity.$Property.ToUniversalTime()
                } elseif ($Property -notin ('ETag', 'RowKey', 'PartitionKey', 'Timestamp', 'LastRefresh')) {
                    $StatEntity.$Property = $Entity.$Property
                }
            }
        }
        $StatEntity = [PSCustomObject]$StatEntity

        Add-CIPPAzDataTableEntity @Table -Entity $StatEntity -Force
    } catch {
        Write-Host "Exception logging stats $($_.Exception.Message)"
    }
}
