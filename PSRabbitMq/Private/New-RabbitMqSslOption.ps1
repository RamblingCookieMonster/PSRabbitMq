Function New-RabbitMqSslOption {
    
    [cmdletbinding()]
    param(
        [System.Security.Authentication.SslProtocols]$Version = 'Tls12',
        [string]$ServerName,
        [string]$CertPath,
        [string]$CertPassphrase,
        [System.Net.Security.SslPolicyErrors]$AcceptablePolicyErrors,
        [RabbitMQ.Client.ConnectionFactory]$Factory
    )

    
    $SslOption = New-Object -TypeName RabbitMQ.Client.SslOption -ArgumentList $ServerName
    $SslOption.Enabled = $True
    $SslOption.Version = $Version
    if($CertPath)
    {
        $SslOption.CertPath = $CertPath
    }
    if($CertPassphrase)
    {
        $SslOption.CertPassphrase = $CertPassphrase
    }
    if($AcceptablePolicyErrors)
    {
        $SslOption.AcceptablePolicyErrors = $AcceptablePolicyErrors
    }

    #Add to factory, or return SslOption
    if($Factory)
    {
        $SslProp = [RabbitMQ.Client.ConnectionFactory].GetField("Ssl")
        $SslProp.SetValue($Factory, $SslOption)
    }
    else
    {
        $SslOption
    }
    
}