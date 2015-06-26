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

    .EXAMPLE
        $Channel = Connect-RabbitMqChannel -Connection $Connection -Exchange MyExchange -Key MyQueue
#>

    [cmdletbinding(DefaultParameterSetName = 'NoQueueName')]
    param(

        $Connection,

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
        [bool]$AutoDelete = $False
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

		#Bind our queue to the ServerBuilds exchange
		$Channel.QueueBind($QueueName, $Exchange, $Key)
        $Channel
    }
    Catch
    {
        Throw $_
    }

}