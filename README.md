PSRabbitMq
=============

PowerShell module to send and receive messages from a RabbitMq server.

All credit to CD. All blame for butchering to @ramblingcookiemonster.

### Functionality

Send and receive messages through a RabbitMq server

[![Send and receive](/Media/SendAndReceive.png)](https://raw.githubusercontent.com/RamblingCookieMonster/PSRabbitMq/master/Media/SendAndReceive.png)

### Instructions

#### Prerequisites

* A working RabbitMq server
* Optionally, enable rabbitmq_management plugin for RabbitMQTools
* Optionally, configure SSL
  * Use OpenSSL and the rabbitmq.config file (docs online)
  * On Windows, you might need to start SSL in the Erlang envirnment via werl.exe ```ssl:start().```

#### Managing RabbitMq with RabbitMqTools

[RabbitMqTools](https://github.com/RamblingCookieMonster/RabbitMQTools/) is a separate module for managing RabbitMq over the REST API. It was originally written by @mariuszwojcik, with [slight modifications](https://github.com/mariuszwojcik/RabbitMQTools/issues/1) from @ramblingcookiemonster.

Skip this section if you're just interested in using PSRabbitMq to send and receive messages.

```PowerShell
# Download RabbitMqTools
# https://github.com/RamblingCookieMonster/RabbitMQTools/archive/master.zip
# Unblock the zip files
# Copy them to one of your module paths: $env:PSModulePath -split ";"

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

#### PSRabbitMq

This is a module for sending and receiving messages using a RabbitMq server and the .NET client library. Originally written by CD, slight modification by @ramblingcookiemonster.

```powershell
# Download PSRabbitMq
# https://github.com/RamblingCookieMonster/PSRabbitMq/archive/master.zip
# Unblock the zip files
# Copy them to one of your module paths: $env:PSModulePath -split ";"

#Import the module
    Import-Module PSRabbitMq

#List commands in PSRabbitMq
    Get-Command -Module PSRabbitMq

#Get help for a function in PSRabbitMq
    Get-Help Send-RabbitMqMessage -Full

#Define a default RabbitMq server and get a credential to use
    Set-RabbitMqConfig -ComputerName rabbitmq.contoso.com
    $CredRabbit = Get-Credential

#Set some common parameters we will always use:
    $Params = @{
        Credential = $CredRabbit
        Ssl = 'Tls12' #I'm using SSL... omit this if you aren't
    }

#Assumes an exchange and bound queue set up per RabbitMqTools example:
    #$ExchangeName = "TestFanExc"
    #$QueueName = 'TestQueue'

#Start waiting for a RabbitMQ message for 120 seconds
    $Incoming = Wait-RabbitMqMessage -Exchange TestFanExc -Key 'TestQueue' -QueueName TestQueue -Timeout 120 @Params

#Open a new PowerShell Window import PSRabbitMq, and send a persistent message
    Send-RabbitMqMessage -Exchange TestFanExc -Key 'TestQueue' -InputObject "Hello!" -Persistent @Params

#Send an arbitrary object
    $SomeObject = [pscustomobject]@{
        Some='Random'
        Data = $(Get-Date)
    }

    Send-RabbitMqMessage -Exchange TestFanExc -Key 'TestQueue' -InputObject $SomeObject -Persistent -Depth 2 @Params

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
  * Created public New-RabbitMqConnectionFactory function to simplify handling the new options
  * Created Add-RabbitMqConnCred private function to extract username/password from cred and add to factory
  * Created New-RabbitMqSslOption private function to simplify setting SSL options.
    * Note: the CertPath/CertPhrase/AcceptablePolicyErrors aren't specified by any calls to the function. Have not tested these.
  * Renamed private parse function to ConvertFrom-RabbitMqDelivery, made it public. Allows parsing from Register-RabbitMqEvent.
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