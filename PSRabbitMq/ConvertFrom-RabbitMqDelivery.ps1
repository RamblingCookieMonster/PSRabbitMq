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
        'text/plain' {
            [Text.Encoding]::UTF8.GetString($Delivery.Body)
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
            $deserialized
        }
        'application/json' {
            $JsonBody = [Text.Encoding]::UTF8.GetString($Delivery.Body)
            ConvertFrom-Json $JsonBody
        }
        'text/xml' {
            [xml]([Text.Encoding]::UTF8.GetString($Delivery.Body))
        }
        default {
            [Text.Encoding]::UTF8.GetString($Delivery.Body)
        }
    }
}