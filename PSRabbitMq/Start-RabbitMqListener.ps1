function Start-RabbitMqListener {
    <#
    .SYNOPSIS
        Start a RabbitMq listener

    .DESCRIPTION
        Start a RabbitMq listener that runs until you break execution

    .PARAMETER ComputerName
        RabbitMq host

        If SSL is specified, we use this as the SslOption server name as well.

    .PARAMETER Exchange
        RabbitMq Exchange

    .PARAMETER Key
        Routing Key to look for

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

    .PARAMETER LoopInterval
        Seconds. Timeout for each interval we wait for a RabbitMq message. Defaults to 1 second.

    .PARAMETER Credential
        Optional PSCredential to connect to RabbitMq with

    .PARAMETER Ssl
        Optional Ssl version to connect to RabbitMq with

        If specified, we use ComputerName as the SslOption ServerName property.

    .PARAMETER IncludeEnvelope
        Include the Message envelope (Metadata) of the message. If ommited, only 
        the payload (body of the message) is returned

    .EXAMPLE
        Start-RabbitMqListener -ComputerName RabbitMq.Contoso.com -Exchange MyExchange -Key 'wat' -Credential $Credential -Ssl Tls12

        # Connect to RabbitMq.contoso.com over Tls 1.2 with credentials in $Credential
        # Listen for new messages on MyExchange exchange, with routing key 'wat'
    #>
    param(
        [string]$ComputerName = $Script:RabbitMqConfig.ComputerName,

        [parameter(Mandatory = $True)]
        [string]$Exchange,

        [parameter(ParameterSetName = 'NoQueueName',Mandatory = $true)]
        [parameter(ParameterSetName = 'QueueName',Mandatory = $false)]
        [string]$Key,

        [parameter(ParameterSetName = 'QueueName',
                   Mandatory = $True)]
        [string]$QueueName,

        [parameter(ParameterSetName = 'QueueName')]
        [bool]$Durable = $true,

        [parameter(ParameterSetName = 'QueueName')]
        [bool]$Exclusive = $False,

        [parameter(ParameterSetName = 'QueueName')]
        [bool]$AutoDelete = $False,

        [switch]$RequireAck,

        [int]$LoopInterval = 1,

        [PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [System.Security.Authentication.SslProtocols]$Ssl,

        [switch]$IncludeEnvelope
    )
    try
    {
        #Build the connection and channel params
        $ConnParams = @{ ComputerName = $ComputerName }
        $ChanParams = @{ Exchange = $Exchange }
        Switch($PSBoundParameters.Keys)
        {
            'Ssl'        { $ConnParams.Add('Ssl',$Ssl) }
            'Credential' { $ConnParams.Add('Credential',$Credential) }
            'Key'        { $ChanParams.Add('Key',$Key)}
            'QueueName'
            {
                $ChanParams.Add('QueueName',$QueueName)
                $ChanParams.Add('Durable' ,$Durable)
                $ChanParams.Add('Exclusive',$Exclusive)
                $ChanParams.Add('AutoDelete' ,$AutoDelete)
            }
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
        while($true)
        {
            if($Consumer.Queue.Dequeue($Timeout.TotalMilliseconds, [ref]$Delivery))
            {
                ConvertFrom-RabbitMqDelivery -Delivery $Delivery -IncludeEnvelope:([bool]$IncludeEnvelope)
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
