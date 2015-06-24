Function Get-RabbitMqConfig {
    <#
    .SYNOPSIS
        Get PSRabbitMq module configuration

    .DESCRIPTION
        Get PSRabbitMq module configuration

    .PARAMETER Source
        Config source:
        RabbitMqConfig to view module variable
        PSRabbitMq.xml to view PSRabbitMq.xml

    .FUNCTIONALITY
        RabbitMq
    #>
    [cmdletbinding()]
    param(
        [ValidateSet('RabbitMqConfig','PSRabbitMq.xml')]
        [string]$Source = "RabbitMqConfig"
    )

    #handle PS2
    if(-not $PSScriptRoot)
    {
        $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
    }

    if($Source -eq "RabbitMqConfig")
    {
        $Script:RabbitMqConfig
    }
    else
    {
        Import-Clixml -Path "$PSScriptRoot\PSRabbitMq.xml"
    }

}