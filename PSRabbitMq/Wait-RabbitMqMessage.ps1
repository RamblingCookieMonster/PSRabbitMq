function Wait-RabbitMqMessage {
    <#
    .SYNOPSIS
        Wait for a RabbitMq message

    .DESCRIPTION
        Wait for a RabbitMq message

    .PARAMETER ComputerName
        RabbitMq host

        If SSL is specified, we use this as the SslOption server name as well.

    .PARAMETER Port
        Port number used by the RabbitMq (AMQP) Server

    .PARAMETER Exchange
        RabbitMq Exchange

    .PARAMETER ExchangeType
        Specify the Exchange Type to be Explicitly declared as non-durable, non-autodelete, without any option.
        Should you want more specific Exchange, create it prior connecting to the channel, and do not specify this parameter.
        
    .PARAMETER Key
        Routing Key to look for

        If you specify a QueueName and no Key, we use the QueueName as the key

    .PARAMETER QueueName
        If specified, bind to this queue.

        If not specified, create a temporal queue

    .PARAMETER Durable
        If queuename is specified, this needs to match whether it is durable

        See Get-RabbitMQQueue

    .PARAMETER Exclusive
        If queuename is specified, this needs to match whether it is Exclusive

        See Get-RabbitMQQueue

    .PARAMETER AutoDelete
        If queuename is specified, this needs to match whether it is AutoDelete

        See Get-RabbitMQQueue

    .PARAMETER RequireAck
        If specified, require an ack for messages

        Note: Without this, dequeue seems to empty a whole queue?

    .PARAMETER Timeout
        Seconds. Timeout Wait-RabbitMqMessage after this expires. Defaults to 10 second

    .PARAMETER LoopInterval
        Seconds. Timeout for each interval we wait for a RabbitMq message. Defaults to 1 second.

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
        Create a connection via the specified virtual host, default is /

    .PARAMETER IncludeEnvelope
        Include the Message envelope (Metadata) of the message. If ommited, only
        the payload (body of the message) is returned

    .EXAMPLE
        Wait-RabbitMqMessage -ComputerName rabbitmq.contoso.com -Exchange MyExchange -Key "message.key"

        # Wait for the "message.key" message on the "MyExchange" exchange.

    .EXAMPLE
        Wait-RabbitMqMessage -ComputerName rabbitmq.contoso.com -Exchange MyExchange -Queue MyQueue -Key "message.key" -Ssl Tls12 -Credential $Credential

        # Connect to rabbitmq.contoso.com over SSL, with credentials stored in $Credential
        # Wait for the "message.key" message on the "MyExchange" exchange, "MyQueue" queue.
    #>
    [Cmdletbinding(DefaultParameterSetName = 'NoQueueName')]
    param(
        [string]$ComputerName = $Script:RabbitMqConfig.ComputerName,
        [int16]$Port = 5672,

        [parameter(Mandatory = $True)]
        [AllowEmptyString()]
        [string]$Exchange,

        [parameter(Mandatory = $false)]
        [ValidateSet('Direct','Fanout','Topic','Headers')]
        [string]$ExchangeType,

        [Alias('routing_key')]
        [parameter(ParameterSetName = 'NoQueueName',Mandatory = $true)]
        [parameter(ParameterSetName = 'QueueName',Mandatory = $false)]
        [string]$Key,

        [Alias('Queue')]
        [parameter(ParameterSetName = 'QueueName',
                   Mandatory = $True)]
        [string]$QueueName,

        [parameter(ParameterSetName = 'QueueName')]
        [bool]$Durable = $true,

        [parameter(ParameterSetName = 'QueueName')]
        [bool]$Exclusive = $False,

        [parameter(ParameterSetName = 'QueueName')]
        [bool]$AutoDelete = $False,

        [parameter(ParameterSetName = 'QueueName')]
        [System.Collections.Generic.Dictionary[String, Object]]$Arguments = $null,

        [switch]$RequireAck,

        [int]$Timeout = 10,

        [int]$LoopInterval = 1,

        [double]$LoopIntervalMilliseconds = 0,

        [PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [string]$CertPath,

        [securestring]$CertPassphrase,

        [System.Security.Authentication.SslProtocols]$Ssl,

        [string]$vhost = '/',

        [switch]$IncludeEnvelope
    )

    Write-Progress -id 10 -Activity 'Create SCMB Connection' -Status 'Building connection' -PercentComplete 0

    try
    {
        #Build the connection and channel params
        $ConnParams = @{ ComputerName = $ComputerName }
        $ChanParams = @{ Exchange = $Exchange }
        Switch($PSBoundParameters.Keys)
        {
            'Port'           { $ConnParams.Add('Port',$Port)}
            'Ssl'            { $ConnParams.Add('Ssl',$Ssl) }
            'CertPath'       { $ConnParams.Add('CertPath',$CertPath)}
            'CertPassphrase' { $ConnParams.Add('CertPassphrase',$CertPassphrase)}
            'Credential'     { $ConnParams.Add('Credential',$Credential) }
            'vhost'          { $ConnParams.Add('vhost',$vhost) }
            'Key'            { $ChanParams.Add('Key',$Key)}
            'ExchangeType'   { $ChanParams.Add('ExchangeType',$ExchangeType)}
            'QueueName'
            {
                $ChanParams.Add('QueueName',$QueueName)
                $ChanParams.Add('Durable' ,$Durable)
                $ChanParams.Add('Exclusive',$Exclusive)
                $ChanParams.Add('AutoDelete' ,$AutoDelete)
                $ChanParams.Add('Arguments' ,$Arguments)
            }
        }
        Write-Verbose "Connection parameters: $($ConnParams | Out-String)`nChannel parameters: $($ChanParams | Out-String)"

        #Create the connection and channel
        $Connection = New-RabbitMqConnectionFactory @ConnParams
        Write-Progress -id 10 -Activity 'Create SCMB Connection' -Status 'Connection Established' -PercentComplete 75

        $Channel = Connect-RabbitMqChannel @ChanParams -Connection $Connection

        Write-Progress -id 10 -Activity 'Create SCMB Connection' -Status 'Connected' -Completed

        #Create our consumer
        $Consumer = New-Object RabbitMQ.Client.QueueingBasicConsumer($Channel)
        $Channel.BasicConsume($QueueName, [bool](!$RequireAck), $Consumer) > $Null

        $Delivery = New-Object RabbitMQ.Client.Events.BasicDeliverEventArgs

        if($Timeout)
        {
            $TimeSpan = New-TimeSpan -Seconds $Timeout
            $SecondsRemaining = [timespan]::FromSeconds($Timeout)
        }
        else
        {
            $SecondsRemaining = [timespan]::MaxValue
        }

        $RMQTimeout = (New-TimeSpan -Seconds $LoopInterval) + ([timeSpan]::FromMilliseconds($LoopIntervalMilliseconds))

        while($SecondsRemaining -gt 0)
        {
            #Listen on a loop but still use short timeouts so Ctrl+C will work!
            $MessageReceived = $false
            if($Consumer.Queue.Dequeue($RMQTimeout.TotalMilliseconds, [ref]$Delivery))
            {
                ConvertFrom-RabbitMqDelivery -Delivery $Delivery -IncludeEnvelope:([bool]$IncludeEnvelope)
                #Kill the loop since we got a message
                $SecondsRemaining = 0
                $MessageReceived = $true
                if($RequireAck)
                {
                    $Channel.BasicAck($Delivery.DeliveryTag, $false)
                }
            }
            $SecondsRemaining-=$RMQTimeout
        }
        if($Timeout -and -not $MessageReceived)
        {
            #Write an error if -Timeout was specified and there is nothing in $Message after the loop
            Write-Error -Message 'No message received while waiting for event in allowed time.' -ErrorAction Stop
        }
    }
    finally
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
