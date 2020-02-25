function Send-RabbitMqMessage {
    <#
    .SYNOPSIS
        Send a RabbitMq message

    .DESCRIPTION
        Send a RabbitMq message

    .PARAMETER ComputerName
        RabbitMq host

        If SSL is specified, we use this as the SslOption server name as well.

    .PARAMETER Exchange
        RabbitMq Exchange to send message to

    .PARAMETER Key
        Routing Key to send message with

    .PARAMETER InputObject
        Object to serialize and include as the message body

        We use ContentType "application/clixml+xml"

    .PARAMETER Depth
        Depth of the InputObject to serialize. Defaults to 2.

    .PARAMETER Persistent
        If specified, send message with persitent delivery method.

        Defaults to non-persistent

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

    .PARAMETER ContentType
        Specify the ContentType for the message de/serialization: 'application/clixml+xml','application/json','text/xml', 'text/plain'
        
    .PARAMETER ReplyTo
        destination to reply to
        
    .PARAMETER ReplyToAddress
        Convenience property; parses ReplyTo property using PublicationAddress.Parse, and serializes it using PublicationAddress.ToString. Returns null if ReplyTo property cannot be parsed by PublicationAddress.Parse.
        
    .PARAMETER CorrelationID
        application correlation identifier

    .PARAMETER Anonymous
        Do not send UserID information in the properties of the message. Will send The credentials' Username by default.
        
    .PARAMETER Priority
        message priority, 0 to 9
        
    .PARAMETER DeliveryMode
        non-persistent (1) or persistent (2)
        
    .PARAMETER ContentType
        Set the MIME content type set in the BasicProperty of the RabbitMq .Net client Channel object.
        Setting this overrides the ContentType regardless of the SerializeAs parameter.
        Default to application/clixml+xml

    .PARAMETER SerializeAs
        Auto-serialize the content, and set the ContentType accordingly if not specified.
        Default to application/clixml+xml
        
    .PARAMETER Type
        Message type name that can be used by the application.
        
    .PARAMETER MessageID
        application message identifier
        
    .PARAMETER TimeStamp
        message timestamp

    .PARAMETER TTL
        Set the Message Expiration time in milliseconds
        
    .PARAMETER Headers
        message header field table
    
    .PARAMETER Port
        Port number used by the RabbitMq (AMQP) Server

    .EXAMPLE
        Send-RabbitMqMessage -ComputerName RabbitMq.Contoso.com -Exchange MyExchange -Key "wat" -InputObject $Object

        # Connects to RabbitMq.Contoso.com
        # Sends a message to the MyExchange exchange with the routing key 'wat', and the $Object object in the body

    .EXAMPLE
        Send-RabbitMqMessage -ComputerName RabbitMq.Contoso.com -Exchange MyExchange -Key "wat" -InputObject @{one=1} -Ssl Tls12 -Credential $Credential

        # Connects to RabbitMq.Contoso.com over tls 1.2 with credential in $Credential
        # Sends a message to the MyExchange exchange with the routing key 'wat', and a hash table in the message body
    #>
    [CmdletBinding(DefaultParameterSetName="SerializeAs")] 
    param(
        [string]$ComputerName = $Script:RabbitMqConfig.ComputerName,

        [parameter(Mandatory = $false)]
        [string]$Exchange = '',

        [parameter(Mandatory = $True)]
        [string]$Key,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Alias('Payload')]
        $InputObject,

        [switch]$Persistent,

        [Int32]$Depth = 2,

        [PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [string]$CertPath,

        [securestring]$CertPassphrase,

        [System.Security.Authentication.SslProtocols]$Ssl,

        [string]$vhost = '/',

        [ValidateSet('application/clixml+xml','application/json','text/xml', 'text/plain', 'NONE')]
        [string]$SerializeAs = 'application/clixml+xml',

        [string]$ContentType = 'application/clixml+xml',

        [string]$ReplyTo,

        [RabbitMQ.Client.PublicationAddress]$ReplyToAddress,

        [string]$CorrelationID,

        [switch]$Anonymous, 

        [ValidateRange(0,9)]
        [byte]$Priority,

        [validateSet(1,2)]
        [byte]$DeliveryMode,

        [string]$Type,

        [string]$MessageID,

        [datetime]$timestamp,

        [Int64]$TTL,

        [hashtable]$headers,
        
        [int16] $Port = 5672
    )
    begin
    {

        Write-Progress -id 10 -Activity 'Create SCMB Connection' -Status 'Building connection' -PercentComplete 0
       
        #Build the connection. Filter bound parameters, splat them.
        $ConnParams = @{ ComputerName = $ComputerName }
        Switch($PSBoundParameters.Keys)
        {
            'Ssl'            { $ConnParams.Add('Ssl',$Ssl) }
            'CertPath'       { $ConnParams.Add('CertPath',$CertPath)}
            'CertPassphrase' { $ConnParams.Add('CertPassphrase',$CertPassphrase)}
            'Credential'     { $ConnParams.Add('Credential',$Credential) }
            'vhost'          { $ConnParams.Add('vhost',$vhost) }
            'Port'           { $ConnParams.Add('Port',$Port) }
        }
        Write-Verbose "Connection parameters: $($ConnParams | Out-String)"

        #Create the connection and channel
        $Connection = New-RabbitMqConnectionFactory @ConnParams
        Write-Progress -id 10 -Activity 'Create SCMB Connection' -Status 'Connection Established' -PercentComplete 75
        Write-Progress -id 10 -Activity 'Create SCMB Connection' -Status 'Connected' -Completed
        
        $Channel = $Connection.CreateModel()
        $BodyProps = $Channel.CreateBasicProperties()
        if($Persistent)
        {
            $BodyProps.SetPersistent($true)
        }

        if ($PSBoundParameters.keys -notcontains 'ContentType' -and
            $SerializeAs -ne 'NONE'
           ) 
        { 
            $BodyProps.ContentType = $SerializeAs 
        }
        elseif($SerializeAs -ne 'NONE' -and
                $PSBoundParameters.Keys -contains 'ContentType'
              ) {
            $BodyProps.ContentType = $ContentType 
        }

        switch ($PSBoundParameters.Keys)
        {
            'timestamp' {
                $BodyProps.Timestamp = [RabbitMQ.Client.AmqpTimestamp][int][double]::Parse(
                                            (Get-date $timestamp -UFormat %s)
                                       )
            }
            'ReplyTo'        { $BodyProps.ReplyTo = $ReplyTo} 
            'ReplyToAddress' { $BodyProps.ReplyToAddress = $ReplyToAddress }
            'CorrelationID'  { $BodyProps.CorrelationId = $CorrelationID }
            'MessageID'      { $BodyProps.MessageID = $MessageID}
            'priority'       { $BodyProps.Priority = $priority }
            'DeliveryMode'   { $BodyProps.DeliveryMode = $DeliveryMode }
            'headers'        { 
                $HeadersFormatted = New-Object 'System.Collections.Generic.Dictionary[String,Object]'
                foreach ($headerKey in $headers.Keys)
                {
                    $HeadersFormatted.Add([string]$headerKey,$headers[$headerKey])
                }
                $BodyProps.Headers = $HeadersFormatted 
            }
            'Type'           { $BodyProps.Type = $Type }
            #If no Userid provided but Credential used, use Cred UserName
            'Credential'     { if (-Not $Anonymous -and $Credential) { $BodyProps.UserId = $Credential.UserName } }
            'TTL'            { $BodyProps.Expiration = $TTL.ToString()} #https://www.rabbitmq.com/ttl.html
        }
    }
    process
    {
        switch ($SerializeAs) {
            'application/clixml+xml' {
                try
                {
                    $Serialized = [Management.Automation.PSSerializer]::Serialize($InputObject, $Depth)
                }
                catch
                {
                    #This is for V2 clients...
                    $TempFile = [io.path]::GetTempFileName()
                    try
                    {
                        Export-Clixml -Path $TempFile -InputObject $InputObject -Depth $Depth -Encoding Utf8
                        $Serialized = [IO.File]::ReadAllLines($TempFile, [Text.Encoding]::UTF8)
                    }
                    finally
                    {
                        if ( (Test-Path -Path $TempFile) )
                        {
                            Remove-Item -Path $TempFile -Force
                        }
                    }
                }
            }
            'application/json' { #Convert to JSON if it's invalid JSON
                try {
                    $null = ConvertFrom-Json -InputObject $InputObject -ErrorAction Stop
                    $Serialized = $InputObject
                }
                catch {
                    $Serialized = ConvertTo-Json -InputObject $InputObject  -Compress -Depth $Depth
                }
            }
            'text/xml' {
                $Serialized = ([xml]$InputObject).OuterXml
            }
            'text/plain' {
                $Serialized = [string]$InputObject
            }
            Default {#unsupported SerializeAs type, or NONE, try sending byte[], or default to String serialization
                try {
                    $Body = [byte[]]$InputObject 
                }
                catch {
                    $Serialized = [string]$InputObject
                }
            }
        }
        if (!$Body)
        {
            $Body = [System.Text.Encoding]::UTF8.GetBytes($Serialized)
        }

        $Channel.BasicPublish($Exchange, $Key, $BodyProps, $Body)
    }
    end
    {
        if($Channel)
        {
            $Channel.Close()
        }
        if($Connection -and $Connection.IsOpen)
        {
            $Connection.Close()
        }
    }
}
