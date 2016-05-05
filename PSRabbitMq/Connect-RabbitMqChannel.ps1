Function Connect-RabbitMqChannel {
    <#
    .SYNOPSIS
        Create a RabbitMQ channel and bind it to a queue

    .DESCRIPTION
        Create a RabbitMQ channel and bind it to a queue

    .PARAMETER Connection
        RabbitMq Connection to create channel on

    .PARAMETER Exchange
        Optional PSCredential to connect to RabbitMq with

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

    .EXAMPLE
        $Channel = Connect-RabbitMqChannel -Connection $Connection -Exchange MyExchange -Key MyQueue
 #>
    [outputType([RabbitMQ.Client.Framing.Impl.Model])]
    [cmdletbinding(DefaultParameterSetName = 'NoQueueName')]
    param(

        $Connection,

        [parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()]
        [string]$Exchange,

        [parameter(ParameterSetName = 'NoQueueNameWithBasicQoS',Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [parameter(ParameterSetName = 'NoQueueName',Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [parameter(ParameterSetName = 'QueueName',Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [parameter(parameterSetName = 'QueueNameWithBasicQoS',Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string[]]$Key,

        [parameter(ParameterSetName = 'QueueName',
                   Mandatory = $True,ValueFromPipelineByPropertyName = $true)]
        [parameter(parameterSetName = 'QueueNameWithBasicQoS',
                   Mandatory = $True,ValueFromPipelineByPropertyName = $true)]
        [string]$QueueName,

        [parameter(ParameterSetName = 'QueueName',ValueFromPipelineByPropertyName = $true)]
        [parameter(parameterSetName = 'QueueNameWithBasicQoS',ValueFromPipelineByPropertyName = $true)]
        [bool]$Durable = $true,

        [parameter(ParameterSetName = 'QueueName',ValueFromPipelineByPropertyName = $true)]
        [parameter(parameterSetName = 'QueueNameWithBasicQoS',ValueFromPipelineByPropertyName = $true)]
        [bool]$Exclusive = $False,

        [parameter(ParameterSetName = 'QueueName',ValueFromPipelineByPropertyName = $true)]
        [parameter(parameterSetName = 'QueueNameWithBasicQoS',ValueFromPipelineByPropertyName = $true)]
        [bool]$AutoDelete = $False,
        
        [parameter(parameterSetName = 'QueueNameWithBasicQoS',Mandatory = $true,ValueFromPipelineByPropertyName = $true)]
        [parameter(ParameterSetName = 'NoQueueNameWithBasicQoS',Mandatory = $true,ValueFromPipelineByPropertyName = $true)]
        [uint32]$prefetchSize,
        [parameter(parameterSetName = 'QueueNameWithBasicQoS',Mandatory = $true,ValueFromPipelineByPropertyName = $true)]
        [parameter(ParameterSetName = 'NoQueueNameWithBasicQoS',Mandatory = $true,ValueFromPipelineByPropertyName = $true)]
        [uint16]$prefetchCount,
        [parameter(parameterSetName = 'QueueNameWithBasicQoS',Mandatory = $true,ValueFromPipelineByPropertyName = $true)]
        [parameter(ParameterSetName = 'NoQueueNameWithBasicQoS',Mandatory = $true,ValueFromPipelineByPropertyName = $true)]
        [switch]$global
    )
    Try
    {
        $Channel = $Connection.CreateModel()

        #Create a personal queue or bind to an existing queue
        if($QueueName)
        {
            $QueueResult = $Channel.QueueDeclare($QueueName, $Durable, $Exclusive, $AutoDelete, $null)
            if(-not $Key)
            {
                $Key = $QueueName
            }
        }
        else
        {
            $QueueResult = $Channel.QueueDeclare()
        }
        if($PsCmdlet.ParameterSetName.Contains('BasicQoS')) {
         $channel.BasicQos($prefetchSize,$prefetchCount,$global)
        }
        #Bind our queue to the ServerBuilds exchange
        foreach ($keyItem in $key) {
            $Channel.QueueBind($QueueName, $Exchange, $KeyItem)
        }
        $Channel
    }
    Catch
    {
        Throw $_
    }

}