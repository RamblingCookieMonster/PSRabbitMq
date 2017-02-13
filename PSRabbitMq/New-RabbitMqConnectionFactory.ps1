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

    .PARAMETER CertPath
    Pkcs12/PFX formatted certificate to connect to RabbitMq with.  Prior to connecting, please make sure the system trusts the CA issuer or self-signed SCMB certifiate.

    .PARAMETER CertPassphrase
    The SecureString Pkcs12/PFX Passphrase of the certificate.

    .PARAMETER Ssl
    Optional Ssl version to connect to RabbitMq with

    If specified, we use ComputerName as the SslOption ServerName property.

    .PARAMETER vhost
    create a connection via the specified virtual host, default is /

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

        [System.Security.Authentication.SslProtocols]$Ssl,

        [int]$Port = 5672,

        [string]$CertPath,

        [securestring]$CertPassphrase,

        [parameter(Mandatory = $false)]
        [string]$vhost
    )

    Try
    {

        Write-Progress -id 10 -Activity 'Create SCMB Connection' -Status 'Building connection' -PercentComplete 30

        $Factory = New-Object RabbitMQ.Client.ConnectionFactory
        
        #Add the hostname
        $HostNameProp = [RabbitMQ.Client.ConnectionFactory].GetField("HostName")
        $HostNameProp.SetValue($Factory, $ComputerName)

        $TcpPortProp = [RabbitMQ.Client.ConnectionFactory].GetField("Port")
        if ( $PSBoundParameters.ContainsKey('Ssl') -and 
             $Ssl -ne [Security.Authentication.SslProtocols]::None -and
             !$PSBoundParameters.ContainsKey('Port')
            )
        {
            $TcpPortProp.SetValue($Factory, 5671)
        }
        else {
            $TcpPortProp.SetValue($Factory, $Port)
        }

        $SslOptionsParams = @{}
        Switch($PSBoundParameters.Keys)
        {
            'Ssl'            {
                if ( $Ssl -ne [Security.Authentication.SslProtocols]::None ) {
                    $SslOptionsParams.Add('Version',$Ssl) 
                }
            }
            'CertPath'       { $SslOptionsParams.Add('CertPath',$CertPath)}
            'CertPassphrase' { $SslOptionsParams.Add('CertPassphrase',$CertPassphrase)}
        }
        
        Write-Progress -id 10 -Activity 'Create SCMB Connection' -Status 'Building connection' -PercentComplete 45

        if($vhost) {
            $vhostProp = [RabbitMQ.Client.ConnectionFactory].GetProperty("VirtualHost")
            $vhostProp.SetValue($Factory, $vhost)
        }
    
        #Add cred and SSL info
        if($Credential)
        {
            Add-RabbitMqConnCred -Credential $Credential -Factory $Factory -ErrorAction Stop
        }
        if($SslOptionsParams.count -gt 0)
        {
            New-RabbitMqSslOption @SslOptionsParams -ServerName $ComputerName -Factory $Factory -ErrorAction Stop
        }
    
        $CreateConnectionMethod = [RabbitMQ.Client.ConnectionFactory].GetMethod("CreateConnection", [Type]::EmptyTypes)
        
        Write-Progress -id 10 -Activity 'Create SCMB Connection' -Status 'Attempting to establish connection' -PercentComplete 60

        #We're ready to go! Output is a connection
        $CreateConnectionMethod.Invoke($Factory, "instance,public", $null, $null, $null)
    }
    Catch
    {
        Throw $_
    }

}