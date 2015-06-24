Function Add-RabbitMqConnCred {
    [cmdletbinding()]
    param(
        $Credential,
        $Factory
    )

    #Swapped GetField for GetProperty
    $UserNameProp = [RabbitMQ.Client.ConnectionFactory].GetProperty("UserName")
    $PasswordProp = [RabbitMQ.Client.ConnectionFactory].GetProperty("Password")
    $UserNameProp.SetValue($Factory, $Credential.Username)
    $PasswordProp.SetValue($Factory, $Credential.GetNetworkCredential().Password)

}