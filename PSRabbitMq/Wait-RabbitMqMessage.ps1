function Wait-RabbitMqMessage {
    <#
    .SYNOPSIS
        Wait for a RabbitMq message

    .DESCRIPTION
        Wait for a RabbitMq message

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
        Seconds. Timeout Wait-RabbitMqMessage after this expires. Defaults to 1 second

    .PARAMETER LoopInterval
        Seconds. Timeout for each interval we wait for a RabbitMq message. Defaults to 1 second.

    .PARAMETER Credential
        Optional PSCredential to connect to RabbitMq with

    .PARAMETER Ssl
        Optional Ssl version to connect to RabbitMq with

        If specified, we use ComputerName as the SslOption ServerName property.

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

        [int]$Timeout = 1,

        [int]$LoopInterval = 1,

        [PSCredential]$Credential,

        [System.Security.Authentication.SslProtocols]$Ssl
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
        Write-Verbose "Connection parameters: $($ConnParams | Out-String)`nChannel parameters: $($ChanParams | Out-String)"

        #Create the connection and channel
        $Connection = New-RabbitMqConnectionFactory @ConnParams
        $Channel = Connect-RabbitMqChannel @ChanParams -Connection $Connection

        #Create our consumer
        $Consumer = New-Object RabbitMQ.Client.QueueingBasicConsumer($Channel)
        $Channel.BasicConsume($QueueName, [bool](!$RequireAck), $Consumer) > $Null

        $Delivery = New-Object RabbitMQ.Client.Events.BasicDeliverEventArgs

        if($Timeout)
        {
            $TimeSpan = New-TimeSpan -Seconds $Timeout
            $SecondsRemaining = $Timeout
		}
        else
        {
			$SecondsRemaining = [Double]::PositiveInfinity
		}
        $RMQTimeout = New-TimeSpan -Seconds $LoopInterval

		while($SecondsRemaining -gt 0)
        {
			#Listen on a loop but still use short timeouts so Ctrl+C will work!
			$MessageReceived = $false
			if($Consumer.Queue.Dequeue($RMQTimeout.TotalMilliseconds, [ref]$Delivery))
            {
				ConvertFrom-RabbitMqDelivery -Delivery $Delivery
				#Kill the loop since we got a message
				$SecondsRemaining = 0
				$MessageReceived = $true
                if($RequireAck)
                {
				    $Channel.BasicAck($Delivery.DeliveryTag, $false)
                }
			}
			$SecondsRemaining--
		}
		if($Timeout -and -not $MessageReceived)
        {
			#Write an error if -Timeout was specified and there is nothing in $Message after the loop
			Write-Error -Message "Timeout waiting for event" -ErrorAction Stop
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
