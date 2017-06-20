Function Get-RabbitMqConfig {
    <#
    .SYNOPSIS
        Get PSRabbitMq module configuration

    .DESCRIPTION
        Get PSRabbitMq module configuration

    .PARAMETER Source
        Config source:
        RabbitMqConfig to view module variable
        PSRabbitMq.xml to view PSRabbitMq.xml from "$env:APPDATA\PSRabbitMq.xml"

    .FUNCTIONALITY
        RabbitMq
    #>
    [cmdletbinding()]
    param(
        [ValidateSet('RabbitMqConfig','PSRabbitMq.xml')]
        [string]$Source = "RabbitMqConfig"
    )
    
    if($Source -eq "RabbitMqConfig")
    {
        $Script:RabbitMqConfig
    }
    else
    {
        Import-Clixml -Path "$env:APPDATA\PSRabbitMq.xml"
    }

}