Function New-RabbitMqSslOption {
    
    [cmdletbinding (DefaultParameterSetName = 'SslOption')]
    param(

        [Parameter (ParameterSetName = 'SslOption')]
        [Parameter (ParameterSetName = 'Certificate')]
        [System.Security.Authentication.SslProtocols]$Version = 'Tls12',
        [string]$ServerName,
        
        [Parameter (ParameterSetName = 'Certificate', Mandatory)]
        [string]$CertPath,

        [Parameter (ParameterSetName = 'Certificate', Mandatory)]
        [securestring]$CertPassphrase,
        
        [Parameter (ParameterSetName = 'SslOption')]
        [Parameter (ParameterSetName = 'Certificate')]
        [System.Net.Security.SslPolicyErrors]$AcceptablePolicyErrors,
        
        [Parameter (ParameterSetName = 'SslOption')]
        [Parameter (ParameterSetName = 'Certificate', Mandatory)]
        [RabbitMQ.Client.ConnectionFactory]$Factory
    )

    
    $SslOption = New-Object -TypeName RabbitMQ.Client.SslOption -ArgumentList $ServerName
    $SslOption.Enabled = $True
    $SslOption.Version = $Version

    if($CertPath)
    {

        #Validate PFX/Pkcs12 file
        try
        {

            $certificateObject = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
            $certificateObject.Import($CertPath, $CertPassphrase, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::DefaultKeySet)
            if (! $certificateObject.HasPrivateKey)
            {

                Write-Error "The provided PFX/PKCS12 certificate file does not contain a private key or the private key is invalid." -ErrorAction Stop

            }

        }

        catch
        {

            $PSCmdlet.ThrowTerminatingError($_)

        }

        $FactoryAuthMechanisms = [RabbitMQ.Client.ConnectionFactory].GetField("AuthMechanisms")
        
        [RabbitMQ.Client.ExternalMechanismFactory]$ExternalAuthObject = New-Object RabbitMQ.Client.ExternalMechanismFactory
        [RabbitMQ.Client.AuthMechanismFactory[]]$AuthMechanismArray = @($ExternalAuthObject)
        $FactoryAuthMechanisms.SetValue($Factory, $AuthMechanismArray)
        $SslOption.CertPath = $CertPath
        $SslOption.CertPassphrase = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($CertPassphrase))

    }

    if($AcceptablePolicyErrors)
    {
        $SslOption.AcceptablePolicyErrors = $AcceptablePolicyErrors
    }


    ($SslOption | Out-String) | Write-Verbose

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
