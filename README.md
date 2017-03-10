PSRabbitMQ
=============

PowerShell module to send and receive messages from a RabbitMQ server.

All credit to @gpduck, all blame for butchering to @ramblingcookiemonster.

### Functionality

Send and receive messages through a RabbitMQ server:

![Send and receive](/Media/SendAndReceive.png)

Listen for RabbitMQ messages until you break execution:

![Listener gif](/Media/Listener.gif)

### Instructions

#### Prerequisites

* A working RabbitMQ server
* More details at the [PowerShell and RabbitMQ post](http://ramblingcookiemonster.github.io/RabbitMQ-Intro/)

#### Managing RabbitMQ with RabbitMQTools

[RabbitMQTools](https://github.com/RamblingCookieMonster/RabbitMQTools/) is a separate module for managing RabbitMQ over the REST API. It was originally written by @mariuszwojcik, with [slight modifications](https://github.com/mariuszwojcik/RabbitMQTools/issues/1) from @ramblingcookiemonster.

Skip this section if you're just interested in using PSRabbitMQ to send and receive messages.

```PowerShell
# Install the module
    Install-Module RabbitMQTools

# No PowerShellGet module?
    # Download RabbitMQTools
    # https://github.com/RamblingCookieMonster/RabbitMQTools/archive/master.zip
    # Unblock the archive
    # Copy the RabbitMQTools module to one of your module paths ($env:PSModulePath -split ";")

#Import the module
    Import-Module RabbitMQTools -force

#Get commands from the module
    Get-Command -module RabbitMQTools

#Get help for a command
    Get-Help Get-RabbitMQOverview

#Define some credentials.  You need an account on RabbitMQ server before we can do this
    $credRabbit = Get-Credential
 
#Convenience - tab completion support for BaseUri
    Register-RabbitMQServer -BaseUri "https://rabbitmq.contoso.com:15671"
 
#I don't want to keep typing those common parameters... we'll splat them
    $Params = @{
        BaseUri = "https://rabbitmq.contoso.com:15671"
        Credential = $credRabbit
    }
 
#Can you hit the server?
    Get-RabbitMQOverview @params
 
#This shows how to create an Exchange and a Queue
#Think of the Exchange as the Blue USPS boxes, and a queue as the individual mailboxes the Exchanges route messages to
    $ExchangeName = "TestFanExc"
    $QueueName = 'TestQueue'
 
#Create an exchange
    Add-RabbitMQExchange @params -name $ExchangeName -Type fanout -Durable -VirtualHost /
 
#Create a queue for the exchange - / is a vhost initialized with install
    Add-RabbitMQQueue @params -Name $QueueName -Durable -VirtualHost /
 
#Bind them
    Add-RabbitMQQueueBinding @params -ExchangeName $ExchangeName -Name $QueueName -VirtualHost / -RoutingKey TestQueue
 
#Add a message to the exchange
    $message = [pscustomobject]@{samaccountname='cmonster';home='\\server\cmonster$'} | ConvertTo-Json
    Add-RabbitMQMessage @params -VirtualHost / -ExchangeName $ExchangeName -RoutingKey TestQueue -Payload $Message
 
#View your changes:
    Get-RabbitMQExchange @params
    Get-RabbitMQQueue @params
    Get-RabbitMQQueueBinding @params -Name $QueueName
 
#View the message we added:
    Get-RabbitMQMessage @params -VirtualHost / -Name $QueueName
    <#
 
        # = the number in the queue
        Queue = name of the queue
        R = whether we've read it (blank when you first read it, * if something has read it)
        Payload = your content.  JSON is helpful here.
 
              # Queue                R Payload
            --- -----                - -------
              1 TestQueue            * {...
    #>
 
#View the payload for the message we added:
    Get-RabbitMQMessage @params -VirtualHost / -Name $QueueName | Select -ExpandProperty Payload

    <#
        JSON output:

        {
            "samaccountname":  "cmonster",
            "home":  "\\\\server\\cmonster$"
        }
    #>

#Example processing the message
    $Incoming = Get-RabbitMQMessage @params -VirtualHost / -Name $QueueName -count 1 -Remove
    $IncomingData = $Incoming.payload | ConvertFrom-Json
    #If something fails, add the message back, or handle with other logic...

    #It's gone
    Get-RabbitMQMessage @params -VirtualHost / -Name $QueueName -count 1
 
    #We have our original data back...
    $IncomingData
 
    #There are better ways to handle this, illustrative purposes only : )
 
#Remove the Queue
    Remove-RabbitMQQueue @params -Name $QueueName -VirtualHost /
 
#Remove the Exchange
    Remove-RabbitMQExchange @params -ExchangeName $ExchangeName -VirtualHost /
 
#Verify that the queueu and Exchange are gone:
    Get-RabbitMQExchange @params
    Get-RabbitMQQueue @params

```

#### PSRabbitMQ

This is a module for sending and receiving messages using a RabbitMQ server and the .NET client library. Originally written by CD, slight modification by @ramblingcookiemonster.

```powershell
# Install the module
    Install-Module PSRabbitMQ

# No PowerShellGet module?
    # Download PSRabbitMQ
    # https://github.com/RamblingCookieMonster/PSRabbitMQ/archive/master.zip
    # Unblock the archiveiles
    # Copy the PSRabbitMQ module folder to one of your module paths ($env:PSModulePath -split ";")

#Import the module
    Import-Module PSRabbitMQ

#List commands in PSRabbitMQ
    Get-Command -Module PSRabbitMQ

#Get help for a function in PSRabbitMQ
    Get-Help Send-RabbitMQMessage -Full

#Define a default RabbitMQ server and get a credential to use
    Set-RabbitMQConfig -ComputerName rabbitmq.contoso.com
    $CredRabbit = Get-Credential

#Set some common parameters we will always use:
    $Params = @{
        Credential = $CredRabbit
        Ssl = 'Tls12' #I'm using SSL... omit this if you aren't
    }

#Assumes an exchange and bound queue set up per RabbitMQTools example:
    #$ExchangeName = "TestFanExc"
    #$QueueName = 'TestQueue'

#Start waiting for a RabbitMQ message for 120 seconds
    $Incoming = Wait-RabbitMQMessage -Exchange TestFanExc -Key 'TestQueue' -QueueName TestQueue -Timeout 120 @Params

#Open a new PowerShell Window import PSRabbitMQ, and send a persistent message
    Send-RabbitMQMessage -Exchange TestFanExc -Key 'TestQueue' -InputObject "Hello!" -Persistent @Params

#Send an arbitrary object
    $SomeObject = [pscustomobject]@{
        Some='Random'
        Data = $(Get-Date)
    }

    Send-RabbitMQMessage -Exchange TestFanExc -Key 'TestQueue' -InputObject $SomeObject -Persistent -Depth 2 @Params

        <#
            # InputObject is serialized when sent,
            # deserialized on the receiving end.
            # No need for messing with JSON

            Some   Data
            ----   ----
            Random 6/24/2015 4:24:51 PM
        #>
```

### Initial changes

Temporary section to document changes since reciept of code. Will retire this eventually and rely on git commits.

* 2015/6/23
  * Added option for SSL connections
  * Added option for authentication
  * Created public New-RabbitMQConnectionFactory function to simplify handling the new options
  * Created Add-RabbitMQConnCred private function to extract username/password from cred and add to factory
  * Created New-RabbitMQSslOption private function to simplify setting SSL options.
    * Note: the CertPath/CertPhrase/AcceptablePolicyErrors aren't specified by any calls to the function. Have not tested these.
  * Renamed private parse function to ConvertFrom-RabbitMQDelivery, made it public. Allows parsing from Register-RabbitMQEvent.
  * Wasn't sure how these were being used. Added handling for specifying an existing queue name and associated details (e.g. durable)
  * Converted timeouts to seconds
  * Added a LoopInterval (seconds) parameter for dequeue timeout
  * Added comment based help
  * Made asinine changes to formatting and organization. Sorry!
  * Wrote no new tests. Sorry!

* 2015/6/24
  * Replaced client dll with latest bits
  * Resolved issue with credential handling due to dll changes
  * Added config handling for computername (get/set rabbitmqconfig) on appropriate functions
  * Added persistent option for sending messages

### Notes

I don't know what messaging is and I'm terrible with code. Apologies for ugly, inefficient, or broken stuff : )

TODO:

 * Break down functions a bit more. For example, offer functions to handle acknowledgements. I might retrieve a message requireing acknowledgement, and only send the ack down the line if my code meets certain criteria.

References:

* [RabbitMQ .NET Client references](http://www.rabbitmq.com/releases/rabbitmq-dotnet-client/v3.5.3/rabbitmq-dotnet-client-3.5.3-client-htmldoc/html/)
* [RabbitMQ .NET / C# API Guide](http://www.rabbitmq.com/dotnet-api-guide.html)
* [RabbitMQ Management API](https://raw.githack.com/rabbitmq/rabbitmq-management/rabbitmq_v3_5_3/priv/www/api/index.html)
* [Accompanying blog post on RabbitMQ and PowerShell](http://ramblingcookiemonster.github.io/RabbitMQ-Intro/)