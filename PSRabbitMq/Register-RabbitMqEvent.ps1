function Register-RabbitMqEvent {
    <#
    .SYNOPSIS
        Register a PSJob that reads RabbitMq messages and runs a specified scriptblock

    .DESCRIPTION
        Register a PSJob that reads RabbitMq messages and runs a specified scriptblock

    .PARAMETER ComputerName
        RabbitMq host

        If SSL is specified, we use this as the SslOption server name as well.

    .PARAMETER Exchange
        RabbitMq Exchange

    .PARAMETER ExchangeType
        Specify the Exchange Type to be Explicitly declared as non-durable, non-autodelete, without any option.
        Should you want more specific Exchange, create it prior connecting to the channel, and do not specify this parameter.

    .PARAMETER Key
        Routing Keys to look for

        If you specify a QueueName and no Key, we use the QueueName as the key

    .PARAMETER QueueName
        If specified, bind to this queue.

        If not specified, create a temporal queue

    .PARAMETER Durable
        If queuename is specified, this needs to match whether it is durable

    .PARAMETER Exclusive
        If queuename is specified, this needs to match whether it is Exclusive

    .PARAMETER AutoDelete
        If queuename is specified, this needs to match whether it is AutoDelete

    .PARAMETER RequireAck
        If specified, require an ack for messages

        Note: Without this, dequeue seems to empty a whole queue?

    .PARAMETER Timeout
        Seconds. Timeout Wait-RabbitMqMessage after this expires. Defaults to 1 second

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

    .PARAMETER ActionData
        Allows you to specify an Object to be available in the Action scriptblock triggered upon reception of message.
        
    .PARAMETER IncludeEnvelope
        Include the Message envelope (Metadata) of the message. If ommited, only
        the payload (body of the message) is returned

    .PARAMETER Port
        Port number used by the RabbitMq (AMQP) Server

    .EXAMPLE
        Register-RabbitMqEvent -ComputerName RabbitMq.Contoso.com -Exchange TestFanExc -Key 'wat' -Credential $Credential -Ssl Tls12 -QueueName TestQueue -Action {"HI! $_"}

        # Create a PowerShell job that...
            Connects to RabbitMq.consoto.com over tls 1.2, with credentials in $Credential
            Listens for messages on RabbitMq.consoto.com over the TestFanExc, with routing key 'wat' and queuename TestQueue.
            Runs a scriptblock that says "Hi! <message body>"

    #>
    [Cmdletbinding(DefaultParameterSetName = 'NoQueueName')]
    param(
        [string]$ComputerName = $Script:RabbitMqConfig.ComputerName,

        [parameter(Mandatory = $True)]
        [AllowEmptyString()]
        [string]$Exchange,
        
        [parameter(Mandatory = $false)]
        [ValidateSet('Direct','Fanout','Topic','Headers')]
        [string]$ExchangeType = $null,

        [parameter(ParameterSetName = 'NoQueueName', Mandatory = $true)]
        [parameter(ParameterSetName = 'NoQueueNameWithBasicQoS', Mandatory = $true)]
        [parameter(ParameterSetName = 'QueueName', Mandatory = $false)]
        [parameter(parameterSetName = 'QueueNameWithBasicQoS')]
        [string[]]$Key,

        [parameter(ParameterSetName = 'QueueName', Mandatory = $True)]
        [parameter(parameterSetName = 'QueueNameWithBasicQoS', Mandatory = $True)]
        [string]$QueueName,

        [parameter(ParameterSetName = 'QueueName')]
        [parameter(parameterSetName = 'QueueNameWithBasicQoS')]
        [bool]$Durable = $true,

        [parameter(ParameterSetName = 'QueueName')]
        [parameter(parameterSetName = 'QueueNameWithBasicQoS')]
        [bool]$Exclusive = $False,

        [parameter(ParameterSetName = 'QueueName')]
        [parameter(parameterSetName = 'QueueNameWithBasicQoS')]
        [bool]$AutoDelete = $False,

        [parameter(ParameterSetName = 'QueueName')]
        [parameter(parameterSetName = 'QueueNameWithBasicQoS')]
        [System.Collections.Generic.Dictionary[String, Object]]$Arguments = $null,

        [switch]$RequireAck,

        [int]$LoopInterval = 1,

        [ScriptBlock]$Action,

        [PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [string]$CertPath,

        [securestring]$CertPassphrase,

        [System.Security.Authentication.SslProtocols]$Ssl,

        [string]$vhost = '/',

        [parameter(parameterSetName = 'QueueNameWithBasicQoS', Mandatory = $true)]
        [parameter(ParameterSetName = 'NoQueueNameWithBasicQoS', Mandatory = $true)]
        [uint32]$prefetchSize,

        [parameter(parameterSetName = 'QueueNameWithBasicQoS', Mandatory = $true)]
        [parameter(ParameterSetName = 'NoQueueNameWithBasicQoS', Mandatory = $true)]
        [uint16]$prefetchCount,

        [parameter(parameterSetName = 'QueueNameWithBasicQoS', Mandatory = $true)]
        [parameter(ParameterSetName = 'NoQueueNameWithBasicQoS', Mandatory = $true)]
        [switch]$global,

        [switch]$IncludeEnvelope,

        [string]$ListenerJobName, 

        $ActionData,
        
        [int16]$Port = 5672
    )

    if ( !$PSBoundParameters.ContainsKey('ListenerJobName') ) {
        $ListenerJobName = "RabbitMq_${ComputerName}_${Exchange}_${Key}"
    }

    $ArgList = $ComputerName, $Exchange, $ExchangeType, $Key, $Action, $Credential, $CertPath, $CertPassphrase, $Ssl, $LoopInterval, $QueueName, $Durable, $Exclusive, $AutoDelete, $Arguments, $RequireAck, $prefetchSize,$prefetchCount,$global,[bool]$IncludeEnvelope,$ActionData,$vhost,$Port
    
    Start-Job -Name $ListenerJobName -ArgumentList $Arglist -ScriptBlock {
        param(
            $ComputerName,
            $Exchange,
            $ExchangeType,
            $Key,
            $Action,
            [PSCredential]
            [System.Management.Automation.Credential()]
            $Credential,
            [string]$CertPath,
            [securestring]$CertPassphrase,
            $Ssl,
            $LoopInterval,
            $QueueName,
            $Durable,
            $Exclusive,
            $AutoDelete,
            $Arguments,
            $RequireAck,
            $prefetchSize,
            $prefetchCount,
            $global,
            $IncludeEnvelope,
            $ActionData,
            $vhost,
            $Port
        )

        $ActionSB = [System.Management.Automation.ScriptBlock]::Create($Action)
        try
        {
            Import-Module PSRabbitMq

            #Build the connection and channel params
            $ConnParams = @{ 
                ComputerName = $ComputerName 
                Port = $Port
            }
            $ConnParams.Add('vhost',$vhost)

            $ChanParams = @{ Exchange = $Exchange }
            If($Ssl)       { $ConnParams.Add('Ssl',$Ssl) }
            if ($CertPath) {
                $ConnParams.Add('CertPath',$CertPath)
                $ConnParams.Add('CertPassphrase',$CertPassphrase)
            }
            If($Credential -and ! $CertPath){ $ConnParams.Add('Credential',$Credential) }
            If($Key)       { $ChanParams.Add('Key',$Key)}
            If($QueueName)
            {
                $ChanParams.Add('QueueName',$QueueName)
                $ChanParams.Add('Durable' ,$Durable)
                $ChanParams.Add('Exclusive',$Exclusive)
                $ChanParams.Add('AutoDelete' ,$AutoDelete)
                $ChanParams.Add('Arguments' ,$Arguments)
            }
            if($prefetchSize) {
                $ChanParams.Add('prefetchSize',$prefetchSize)
                $ChanParams.Add('prefetchCount',$prefetchCount)
                $ChanParams.Add('global',$global)
            }

            if( $ExchangeType ) {
                $ChanParams.Add('ExchangeType',$ExchangeType)
            }

            #Create the connection and channel
            $Connection = New-RabbitMqConnectionFactory @ConnParams
            $Channel = Connect-RabbitMqChannel @ChanParams -Connection $Connection

            #Create our consumer
            $Consumer = New-Object RabbitMQ.Client.QueueingBasicConsumer($Channel)
            $Channel.BasicConsume($QueueResult.QueueName, [bool](!$RequireAck), $Consumer) > $Null

            $Delivery = New-Object RabbitMQ.Client.Events.BasicDeliverEventArgs

            #Listen on an infinite loop but still use timeouts so Ctrl+C will work!
            $Timeout = New-TimeSpan -Seconds $LoopInterval
            $Message = $null
            while($True)
            {
                if($Consumer.Queue.Dequeue($Timeout.TotalMilliseconds, [ref]$Delivery))
                {
                    ConvertFrom-RabbitMqDelivery -Delivery $Delivery -IncludeEnvelope:$IncludeEnvelope | ForEach-Object $ActionSB
                    if($RequireAck)
                    {
                        $Channel.BasicAck($Delivery.DeliveryTag, $false)
                    }
                }
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
}
