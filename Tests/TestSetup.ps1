$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Server = "localhost"

$RabbitAssembly = Join-Path $Here "..\PSRabbitMQ\lib\RabbitMQ.Client.dll"
Add-Type -Path $RabbitAssembly
