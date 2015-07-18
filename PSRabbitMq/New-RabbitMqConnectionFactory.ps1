Function New-RabbitMqConnectionFactory {
<#
.SYNOPSIS
    Create a RabbitMQ client connection

.DESCRIPTION
    Create a RabbitMQ client connection

    Builds a RabbitMQ.Client.ConnectionFactory based on parameters, invokes CreateConnection method.

.PARAMETER ComputerName
    RabbitMq host

    If SSL is specified, we use this as the SslOption server name as well.

.PARAMETER Credential
    Optional PSCredential to connect to RabbitMq with

.PARAMETER Ssl
    Optional Ssl version to connect to RabbitMq with

    If specified, we use ComputerName as the SslOption ServerName property.

.EXAMPLE
    $Connection = New-RabbitMqConnectionFactory -ComputerName RabbitMq.Contoso.com -Ssl Tls12 -Credential $Credential

    # Connect to RabbitMq.contoso.com over SSL (use tls 1.2), with credentials in $Credential

.EXAMPLE
    $Connection = New-RabbitMqConnectionFactory -ComputerName RabbitMq.Contoso.com

    # Connect to RabbitMq.contoso.com
#>

    [cmdletbinding()]
    param(
        [string]$ComputerName,
        [PSCredential]$Credential,
        [System.Security.Authentication.SslProtocols]$Ssl
    )
    Try
    {
        $Factory = New-Object RabbitMQ.Client.ConnectionFactory
        
        #Add the hostname
        $HostNameProp = [RabbitMQ.Client.ConnectionFactory].GetField("HostName")
        $HostNameProp.SetValue($Factory, $ComputerName)
    
        #Add cred and SSL info
        if($Credential)
        {
            Add-RabbitMqConnCred -Credential $Credential -Factory $Factory -ErrorAction Stop
        }
        if($Ssl)
        {
            New-RabbitMqSslOption -Version $Ssl -ServerName $ComputerName -Factory $Factory -ErrorAction Stop
        }
    
        $CreateConnectionMethod = [RabbitMQ.Client.ConnectionFactory].GetMethod("CreateConnection", [Type]::EmptyTypes)
        
        #We're ready to go! Output is a connection
        $CreateConnectionMethod.Invoke($Factory, "instance,public", $null, $null, $null)
    }
    Catch
    {
        Throw $_
    }

}