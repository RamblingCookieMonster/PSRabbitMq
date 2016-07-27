function ConvertFrom-RabbitMqDelivery {
    <#
    .SYNOPSIS
        Parse a RabbitMq delivery

    .DESCRIPTION
        Parse a RabbitMq delivery.

        Deserializes based on delivery contenttype, falls back to string

    .PARAMETER Delivery
        RabbitMq Delivery to parse.

    .PARAMETER IncludeEnvelope
        Include the Message envelope (Metadata) of the message. If ommited, only 
        the payload (body of the message) is returned

    .EXAMPLE
        ConvertFrom-RabbitMqDelivery -Delivery $Delivery
    #>
    param(
        [RabbitMQ.Client.Events.BasicDeliverEventArgs]$Delivery,
        [switch]$IncludeEnvelope
    )
    switch($Delivery.BasicProperties.ContentType) {
        'text/plain' {
            $Payload = [Text.Encoding]::UTF8.GetString($Delivery.Body)
        }
        'application/clixml+xml' {
            $XmlBody = [Text.Encoding]::UTF8.GetString($Delivery.Body)
            try
            {
                $deserialized = [System.Management.Automation.PSSerializer]::DeserializeAsList($XmlBody)
            }
            catch
            {
                #This is for V2 clients...
                $TempFile = [io.path]::GetTempFileName()
                try
                {
                    $null = New-Item -Name (Split-Path -Leaf $TempFile) -Value $XmlBody -ItemType File -Path (split-path $TempFile -Parent) -Force
                    $deserialized = Import-Clixml -Path $TempFile
                    $deserialized = [IO.File]::ReadAllLines($TempFile, [Text.Encoding]::UTF8)
                }
                finally
                {
                    if( (Test-Path -Path $TempFile) )
                    {
                        Remove-Item -Path $TempFile -Force
                    }
                }
            }
            $Payload = $deserialized
        }
        'application/json' {
            $JsonBody = [Text.Encoding]::UTF8.GetString($Delivery.Body)
            try
            {
                $Payload = ConvertFrom-Json $JsonBody
            }
            catch
            {
                Write-Error 'Invalid JSON. Returning String'
                $Payload = $JsonBody
            }
        }
        'text/xml' {
            $Payload = [xml]([Text.Encoding]::UTF8.GetString($Delivery.Body))
        }
        default {
            $Payload = [Text.Encoding]::UTF8.GetString($Delivery.Body)
        }
    }

    if (-not $IncludeEnvelope)
    {
        return $Payload
    }
    else {
        return [PSCustomObject][ordered]@{
            PSTypeName   = 'PSRabbitMQ.Envelope'
            'RoutingKey' = [string]$Delivery.RoutingKey
            'Exchange'   = [string]$Delivery.Exchange
            'Properties' = [PSCustomObject][ordered]@{
                'reply_to'         = [string]$Delivery.BasicProperties.ReplyTo
                'reply_to_Address' = [PSCustomObject][ordered]@{
                                    'ExchangeType' = $Delivery.BasicProperties.ReplyToAddress.ExchangeType
                                    'ExchangeName' = $Delivery.BasicProperties.ReplyToAddress.ExchangeName
                                    'RoutingKey' = $Delivery.BasicProperties.ReplyToAddress.RoutingKey
                                    }
                'correlation_id'   = [string]$Delivery.BasicProperties.CorrelationId
                'priority'         = [int]$Delivery.BasicProperties.Priority
                'delivery_mode'    = [int]$Delivery.BasicProperties.DeliveryMode
                'type'             = [string]$Delivery.BasicProperties.Type
                'message_id'       = [string]$Delivery.BasicProperties.MessageId
                'timestamp'        = [long]$Delivery.BasicProperties.Timestamp.UnixTime
                }
            'Payload'    = $Payload
        }
    }
}
