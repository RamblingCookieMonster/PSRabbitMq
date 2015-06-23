Function Add-RabbitMqConnCred {
    [cmdletbinding()]
    param(
        $Credential,
        $Factory
    )

    $UserNameProp = [RabbitMQ.Client.ConnectionFactory].GetField("UserName")
    $PasswordProp = [RabbitMQ.Client.ConnectionFactory].GetField("Password")
    $UserNameProp.SetValue($Factory, $Credential.Username)
    $PasswordProp.SetValue($Factory, $Credential.GetNetworkCredential().Password)

}