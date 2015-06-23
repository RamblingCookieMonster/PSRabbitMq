PSRabbitMq
=============

PowerShell module to send and receive messages from a RabbitMq server.

All credit to CD. All blame for butchering to WF.

#### Initial changes

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
* Made asinine changes to formatting. Sorry!!

#### Notes

I don't know what messaging is and I'm terrible with code. Apologies for ugly, inefficient, or broken stuff : )