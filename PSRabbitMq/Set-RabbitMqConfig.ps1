Function Set-RabbitMqConfig {
    <#
    .SYNOPSIS
        Set PSRabbitMq module configuration.

    .DESCRIPTION
        Set PSRabbitMq module configuration, and module $RabbitMqConfig variable.

        This data is used as the default for most commands.

    .PARAMETER ComputerName
        Specify a ComputerName to use

    .PARAMETER NoPersist
        Disables the export of the current RabbitMQConfig to $env:APPDATA\PSRabbitMq.xml                

    .Example
        Set-RabbitMqConfig -ComputerName "rabbitmq.contoso.com"

    .Example
        Set-RabbitMqConfig -ComputerName "rabbitmq.contoso.com" -NoPersist

    .FUNCTIONALITY
        RabbitMq
    #>
    [cmdletbinding()]
    param(
        [string]$ComputerName,
        [ValidateSet("CurrentUser","System")]
        [string]$Scope = "CurrentUser",
        [switch]$NoPersist
    )

    If($PSBoundParameters.ContainsKey('ComputerName'))
    {
        $Script:RabbitMqConfig.ComputerName = $ComputerName
    }

    #If Persist was specified and the Variable is not Empty
    if(-not($NoPersist) -and (-not([String]::IsNullOrEmpty($Script:RabbitMqConfig.ComputerName))))
    {
        if($Scope -eq "CurrentUser"){
            Write-Verbose "Writing current RabbitMQConfig to: $env:APPDATA\PSRabbitMq.xml"
            $Script:RabbitMqConfig | Export-Clixml -Path "$env:APPDATA\PSRabbitMq.xml" -Force
        }
        elseif($Scope -eq "System"){
            Write-Verbose "Writing current RabbitMQConfig to: $env:PROGRAMDATA\PSRabbitMq.xml"
            $Script:RabbitMqConfig | Export-Clixml -Path "$env:PROGRAMDATA\PSRabbitMq.xml" -Force
        }
        
    }

}