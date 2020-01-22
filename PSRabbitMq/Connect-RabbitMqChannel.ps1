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

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Direct','Fanout','Topic','Headers')]
        [string]$ExchangeType = $null,

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

        [parameter(ParameterSetName = 'QueueName',ValueFromPipelineByPropertyName = $true)]
        [parameter(parameterSetName = 'QueueNameWithBasicQoS',ValueFromPipelineByPropertyName = $true)]
        [System.Collections.Generic.Dictionary[String, Object]]$Arguments = $null,

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

        Write-Progress -id 10 -Activity 'Create SCMB Connection' -Status 'Attempting connection to channel' -PercentComplete 80

        #Actively declare the Exchange (as non-autodelete, non-durable)
        if($ExchangeType -and ![string]::IsNullOrEmpty($Exchange)) {
            $ExchangeResult = $Channel.ExchangeDeclare($Exchange,$ExchangeType.ToLower())
        }

        #Create a personal queue or bind to an existing queue
        if($QueueName)
        {
            $QueueResult = $Channel.QueueDeclare($QueueName, $Durable, $Exclusive, $AutoDelete, $Arguments)
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
        #Bind our queue to the exchange
        foreach ($keyItem in $key) {
            $Channel.QueueBind($QueueName, $Exchange, $KeyItem)
        }

        Write-Progress -id 10 -Activity 'Create SCMB Connection' -Status ('Conneccted to channel: {0}, {1}, {2}' -f $QueueName, $Exchange, $KeyItem) -PercentComplete 90

        $Channel
    }
    Catch
    {
        Throw $_
    }

}