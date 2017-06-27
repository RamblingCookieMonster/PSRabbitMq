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
        CurrentUser to view PSRabbitMq.xml from "$env:APPDATA\PSRabbitMq.xml"
        System to view PSRabbitMq.xml from "$env:PROGRAMDATA\PSRabbitMq.xml"

    .FUNCTIONALITY
        RabbitMq
    #>
    [cmdletbinding()]
    param(
        [ValidateSet('RabbitMqConfig','PSRabbitMq.xml','CurrentUser','System')]
        [string]$Source = "RabbitMqConfig"
    )
    
    if($Source -eq "RabbitMqConfig"){
        $Script:RabbitMqConfig
    }
    elseif($Source -eq "PSRabbitMq.xml" -or $Source -eq "CurrentUser"){
        Import-Clixml -Path "$env:APPDATA\PSRabbitMq.xml"
    }
    elseif($Source -eq "System"){
        Import-Clixml -Path "$env:PROGRAMDATA\PSRabbitMq.xml"
    }

}