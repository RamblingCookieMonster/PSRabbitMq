Function Set-RabbitMqConfig {
    <#
    .SYNOPSIS
        Set PSRabbitMq module configuration.

    .DESCRIPTION
        Set PSRabbitMq module configuration, and module $RabbitMqConfig variable.

        This data is used as the default for most commands.

    .PARAMETER ComputerName
        Specify a ComputerName to use

    .Example
        Set-RabbitMqConfig -ComputerName "rabbitmq.contoso.com"

    .FUNCTIONALITY
        RabbitMq
    #>
    [cmdletbinding()]
    param(
        [string]$ComputerName
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

    $Script:RabbitMqConfig | Export-Clixml -Path "$PSScriptRoot\PSRabbitMq.xml" -force

}