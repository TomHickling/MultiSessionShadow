$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Credential = Get-Credential -UserName "<Service Principal ID Here>" -Message "Enter Service Principal Details"
$Credential.Password | ConvertFrom-SecureString | Set-Content "$ScriptPath\WVDSvcPrincipal_Password.txt"