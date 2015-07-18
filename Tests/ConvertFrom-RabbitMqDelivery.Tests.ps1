$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

. "$here\TestSetup.ps1"
. "$here\..\PSRabbitMQ\$sut"

Describe "ConvertFrom-RabbitMQDelivery" {
    context "Plain Text Delivery" {
        $Delivery = New-Object RabbitMQ.Client.Events.BasicDeliverEventArgs
        $Delivery.Body = [Text.Encoding]::UTF8.GetBytes("test string")
        $Properties = New-Object RabbitMQ.Client.Framing.BasicProperties
        $Delivery.BasicProperties = $Properties
        
        It "returns the plain text with no ContentType" {
            $Delivery.BasicProperties.ClearContentType()
            ConvertFrom-RabbitMQDelivery -Delivery $Delivery | Should Be "test string"
        }
        
        It "returns the plain text with ContentType = text/plain" {
            $Delivery.BasicProperties.ContentType = "text/plain"
            ConvertFrom-RabbitMQDelivery -Delivery $Delivery | Should Be "test string"
        }
    }
    
    context "CliXML Delivery" {
        It "returns the object with ContentType = application/clixml+xml" {
            $Delivery = New-Object RabbitMQ.Client.Events.BasicDeliverEventArgs
            $TestObject = [PSCustomObject]@{
                P1 = "Property 1"
                P2 = "Property 2"
            }
            
            $Delivery.Body = [Text.Encoding]::UTF8.GetBytes([System.Management.Automation.PSSerializer]::Serialize($TestObject, 1))
            $Properties = New-Object RabbitMQ.Client.Framing.BasicProperties
            $Delivery.BasicProperties = $Properties
        
        
            $Delivery.BasicProperties.ContentType = "application/clixml+xml"
            $ParsedObject = ConvertFrom-RabbitMQDelivery -Delivery $Delivery
            $ParsedObject.P1 | Should Be "Property 1"
            $ParsedObject.P2 | Should Be "Property 2"
            ($ParsedObject | Get-Member -MemberType Properties).Count | Should Be 2
        }
        
        It "returns an ArrayList when an array is passed in" {
            $Delivery = New-Object RabbitMQ.Client.Events.BasicDeliverEventArgs
            $TestObject1 = [PSCustomObject]@{
                P1 = "Object 1"
                P2 = "Object 1"
            }
            $TestObject2 = [PSCustomObject]@{
                P1 = "Object 2"
                P2 = "Object 2"
            }
            
            $Delivery.Body = [Text.Encoding]::UTF8.GetBytes([System.Management.Automation.PSSerializer]::Serialize(@($TestObject1, $TestObject2), 2))
            $Properties = New-Object RabbitMQ.Client.Framing.BasicProperties
            $Delivery.BasicProperties = $Properties
            $Delivery.BasicProperties.ContentType = "application/clixml+xml"
            
            $ParsedObject = ConvertFrom-RabbitMQDelivery -Delivery $Delivery
            $ParsedObject -is [System.Collections.ArrayList] | Should Be $true
            $ParsedObject.Count | Should Be 2
        }
    }
    
    context "JSON Delivery" {
        $Delivery = New-Object RabbitMQ.Client.Events.BasicDeliverEventArgs
        $TestObject = [PSCustomObject]@{
            P1 = "Property 1"
            P2 = "Property 2"
        }
        
        $Delivery.Body = [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json $TestObject))
        $Properties = New-Object RabbitMQ.Client.Framing.BasicProperties
        $Delivery.BasicProperties = $Properties
                
        It "returns the object with ContentType = application/json" {
            $Delivery.BasicProperties.ContentType = "application/json"
            $ParsedObject = ConvertFrom-RabbitMQDelivery -Delivery $Delivery
            $ParsedObject.P1 | Should Be "Property 1"
            $ParsedObject.P2 | Should Be "Property 2"
            ($ParsedObject | Get-Member -MemberType Properties).Count | Should Be 2
        }
    }
}
