$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

. "$here\TestSetup.ps1"
. "$here\..\PSRabbitMQ\$sut"

Describe "Get-RabbitMqConfig" {

    context "Getting current RabbitMQ Configuration" {
        It "gets the current Configuration"{
            $Script:RabbitMqConfig = [pscustomobject]@{
                ComputerName = "rabbitmq.contoso.com"
            }

            $currentConfig = Get-RabbitMqConfig -Source "RabbitMQConfig"
            $currentConfig.ComputerName | Should be "rabbitmq.contoso.com"
        }
    }

    context "Getting the persistent RabbitMQ Configuration"{

        It "gets the current persistent Configuration from Old 'PSRabbitMq.xml' (AppData)"{
            Mock Import-CliXml {}
            $currentConfig = Get-RabbitMqConfig -Source "PSRabbitMq.xml"
            Assert-MockCalled -CommandName Import-CliXml -Times 1
        }

        It "gets the current persistent Configuration from CurrentUser"{
            Mock Import-CliXml {}
            $currentConfig = Get-RabbitMqConfig -Source "CurrentUser"
            Assert-MockCalled -CommandName Import-CliXml -Times 1
        }

        It "gets the current persistent Configuration from System"{
            Mock Import-CliXml {}
            $currentConfig = Get-RabbitMqConfig -Source "System"
            Assert-MockCalled -CommandName Import-CliXml -Times 1
        }
    }
}
