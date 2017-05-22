Function Set-RabbitMqConfig {
    <#
    .SYNOPSIS
        Set PSRabbitMq module configuration.

    .DESCRIPTION
        Set PSRabbitMq module configuration, and module $RabbitMqConfig variable.

        This data is used as the default for most commands.

    .PARAMETER ComputerName
        Specify a ComputerName to use

    .PARAMETER Persist
        Exports the current RabbitMQConfig to $PSScriptRoot\PSRabbitMq.xml
        
        (Default: $PSScriptRoot = ModulePath)

    .Example
        Set-RabbitMqConfig -ComputerName "rabbitmq.contoso.com"

    .Example
        Set-RabbitMqConfig -ComputerName "rabbitmq.contoso.com" -Persist

    .FUNCTIONALITY
        RabbitMq
    #>
    [cmdletbinding()]
    param(
        [string]$ComputerName,
        [switch]$Persist
    )

    #handle PS2
    if(-not $PSScriptRoot)
    {
        $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
    }

    If($PSBoundParameters.ContainsKey('ComputerName'))
    {
        $Script:RabbitMqConfig.ComputerName = $ComputerName
    }

    #If Persist was specified and the Variable is not Empty
    if($Persist -and (-not([String]::IsNullOrEmpty($Script:RabbitMqConfig.ComputerName))))
    {
        try
        {
            Write-Verbose "Writing current RabbitMQConfig to: $PSScriptRoot\PSRabbitMq.xml"
            $Script:RabbitMqConfig | Export-Clixml -Path "$PSScriptRoot\PSRabbitMq.xml" -Force
        }
        catch
        {
            Write-Warning "Your configuration was saved for the current session, but you need to run Powershell with Administrator permissions to persist this Configuration to $PSScriptRoot\PSRabbitMq.xml!"
        }
    }

}