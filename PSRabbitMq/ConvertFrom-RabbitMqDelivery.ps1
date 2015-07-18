function ConvertFrom-RabbitMqDelivery {
    <#
    .SYNOPSIS
        Parse a RabbitMq delivery

    .DESCRIPTION
        Parse a RabbitMq delivery.

        Deserializes based on delivery contenttype, falls back to string

    .PARAMETER Delivery
        RabbitMq Delivery to parse.

    .EXAMPLE
        ConvertFrom-RabbitMqDelivery -Delivery $Delivery
    #>
    param(
        [RabbitMQ.Client.Events.BasicDeliverEventArgs]$Delivery
    )
    switch($Delivery.BasicProperties.ContentType) {
        "text/plain" {
            [Text.Encoding]::UTF8.GetString($Delivery.Body)
        }
        "application/clixml+xml" {
            $XmlBody = [Text.Encoding]::UTF8.GetString($Delivery.Body)
            [System.Management.Automation.PSSerializer]::DeserializeAsList($XmlBody)
        }
        "application/json" {
            $JsonBody = [Text.Encoding]::UTF8.GetString($Delivery.Body)
            ConvertFrom-Json $JsonBody
        }
        default {
            [Text.Encoding]::UTF8.GetString($Delivery.Body)
        }
    }
}