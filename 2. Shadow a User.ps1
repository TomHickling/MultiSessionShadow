<##################################################################################################

    Script Name:  Shadow a User.ps1
    Written By:   Garry Down
    Version:      1.0

    The script has been created to allow an administrator to select a user via a PowerShell GUI
    and shadow that user

    Script connects to the WVD Environment using the a Service Principal. Details regarding the
	Service Principal ID and Azure Tenant ID are currently Hard Coded (Lines 73 & 74)
    The Service Principal Password is encrypted in the text file WVDSvcPrincipal_Password.txt
    located in the same folder as this script
    This encrypted text file is created by running the 'Save WVD Service Principal Password'
    script provided with this script

    The WVD Tenant Name is a Variable within the Script (Line 40)

    The Script Actions are:

        Install the Microsoft.RDInfra.RDPowerShell if not already installed (Admin Rights required)

        Connect to the WVD Management Platform using the Service Principal ID

        Via the PowerShell GUI:

            Select the Host Pool the user is connected too

            Populate the User List with all ACTIVE Users connected to the Host Pool

            Select the User to be shadowed

            Enable Remote Control if required

            Shadow the User

##################################################################################################>

# Variables
$TenantName = "<WVD Tenant Name Here>"

cls
# Load PowerShell Modules if needed.
Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host " Loading PowerShell Modules"
$Modules = @('Microsoft.RDInfra.RDPowerShell')
Foreach ($Module in $Modules) {
    if((Test-Path -Path "C:\Program Files\WindowsPowerShell\Modules\$Module" -ErrorAction SilentlyContinue)-eq $true) {
        if((Get-Module -Name $Module -ErrorAction SilentlyContinue) -eq $false) {
            Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host "   Importing Module" $Module -ForegroundColor DarkYellow
            Import-Module -Name $Module -Verbose -ErrorAction SilentlyContinue
            }
        Else {
            Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host "   PowerShell Module " -NoNewline -ForegroundColor DarkYellow ; Write-Host "'$Module'" -NoNewline -ForegroundColor DarkCyan ; Write-Host " already imported" -ForegroundColor DarkYellow
            }
        }
    Else {
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        If ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $false) {
            Write-Host ; Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host " To Install the PowerShell Module " -NoNewline ; Write-Host "'$Module'" -NoNewline -ForegroundColor Cyan ; Write-Host " this script needs to be run " -NoNewline ; Write-Host "'As Administrator'" -ForegroundColor Red -NoNewLine ; Write-Host ", Script Exiting"
            Exit
            }
        $NuGet = Get-PackageProvider | Where-Object -Property Name -EQ NuGet
        If(($NuGet) -eq $null) {
            Write-Host ; Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host " Installing PowerShell Package Provider " -NoNewline ; Write-Host "'NuGet'" -ForegroundColor Cyan
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.208 -Force -Verbose -ErrorAction Stop
            }
        Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host "   Installing PowerShell Module " -NoNewline -ForegroundColor DarkYellow ; Write-Host "'$Module'" -ForegroundColor DarkCyan
        Install-Module -Name $Module -Force -Verbose -ErrorAction Stop
        }
    }

# Log onto Management Plane using Service Principal
$svcPrincipalID         = "<Service Principal ID Here>"
$AzureTenantID          = "<Azure Tenant ID Here>"

$ScriptPath             = Split-Path -Parent $MyInvocation.MyCommand.Definition
$svcPrincipalIDPWD      = Get-Content "$ScriptPath\WVDSvcPrincipal_Password.txt" | ConvertTo-SecureString

Write-Host ; Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host " Connecting the WVD Platform"
$creds                  = New-Object System.Management.Automation.PSCredential($svcPrincipalID, ($svcPrincipalIDPWD))
$HideOutput             = Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com" -Credential $creds -ServicePrincipal -AadTenantId $AzureTenantID

# Or Log onto Management plane using a RDS Owner user account
#Add-RdsAccount -DeploymentUrl https://rdbroker.wvd.microsoft.com -Credential "<upn@domain.com">


#Gather Host Pool Details
Write-Host ; Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host " Gathering Available Host Pools"
$HostPools = Get-RdsHostPool -TenantName $TenantName

Write-Host ; Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host " Launching Shadow Selector Screen"
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$ShadowUser                      = New-Object system.Windows.Forms.Form
$ShadowUser.ClientSize           = '600,350'
$ShadowUser.text                 = "User Shadow Selector"
$ShadowUser.TopMost              = $false

$HostPool                        = New-Object system.Windows.Forms.ComboBox
$HostPool.text                   = "Select the Host Pool the User is connected too"
$HostPool.BackColor              = "#c2c2c2"
$HostPool.width                  = 540
$HostPool.height                 = 30
$HostPool.location               = New-Object System.Drawing.Point(30,30)
$HostPool.Font                   = 'Microsoft Sans Serif,18'
Foreach ($HostPoolName in $HostPools) {
    $HostPool.Items.Add($HostPoolName.HostPoolName) | Out-Null
}

$UserSession                     = New-Object system.Windows.Forms.ComboBox
$UserSession.text                = "Please Select Host Pool to Populate"
$UserSession.width               = 540
$UserSession.height              = 30
$UserSession.location            = New-Object System.Drawing.Point(30,100)
$UserSession.Font                = 'Microsoft Sans Serif,18'

$TakeControl                     = New-Object system.Windows.Forms.CheckBox
$TakeControl.text                = " Allow Remote Control of the Users Session"
$TakeControl.width               = 500
$TakeControl.height              = 20
$TakeControl.location            = New-Object System.Drawing.Point(30,170)
$TakeControl.Font                = 'Microsoft Sans Serif,14'

$ErrorMsg                        = New-Object system.Windows.Forms.Button
$ErrorMsg.BackColor              = "#db1a1a"
$ErrorMsg.width                  = 500
$ErrorMsg.height                 = 50
$ErrorMsg.enabled                = $false
$ErrorMsg.location               = New-Object System.Drawing.Point(50,210)
$ErrorMsg.Font                   = 'Microsoft Sans Serif,12'
$ErrorMsg.Visible                = $false

$Shadow                          = New-Object system.Windows.Forms.Button
$Shadow.BackColor                = "#f8e71c"
$Shadow.text                     = "Shadow User"
$Shadow.width                    = 400
$Shadow.height                   = 50
$Shadow.enabled                  = $true
$Shadow.location                 = New-Object System.Drawing.Point(100,280)
$Shadow.Font                     = 'Microsoft Sans Serif,14'
$Shadow.ForeColor                = "#0000ff"

$ShadowUser.controls.AddRange(@($HostPool,$UserSession,$TakeControl,$ErrorMsg,$Shadow))

$HostPool.Add_SelectedValueChanged({ HostPoolSelected })

$Shadow.Add_Click({

    $ValidRunChecksResult = RunChecks
    If ($ValidRunChecksResult -eq "No Host Pool Selected") {
        $ErrorMsg.text = "No Host Pool Selected"
        $ErrorMsg.Visible = $true
        $ErrorMsg.enabled = $true
        }
    ElseIf ($ValidRunChecksResult -eq "No User Selected") {
        $ErrorMsg.text = "No User Selected"
        $ErrorMsg.Visible = $true
        $ErrorMsg.enabled = $true
        }
    Else {
        ShadowUserSession
        }
    })


Function HostPoolSelected {

    $UserSession.BackColor = "white"
    $UserSession.text      = "Please Select the User to be Shadowed"

    Write-Host ; Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host " Gathering a list of connected users"
    $ActiveUsers = Get-RdsUserSession -TenantName $TenantName -HostPoolName $HostPool.Text | where { $_.SessionState -eq "active"}

    $UserSession.Items.Count
    $UserSession.Items.Clear()
    $UserSession.Items.Count

    Foreach ($ActiveUser in $ActiveUsers) {
        $UserSession.Items.Add($ActiveUser.UserPrincipalName)
        }
    }


Function RunChecks {

    If ($HostPool.Text -eq "Select the Host Pool the User is connected too") {
        Write-Host "No Host Pool Selected"
        $ValidRunChecksResult = "No Host Pool Selected"
        Return $ValidRunChecksResult
        }
    If ($UserSession.text -eq "Please Select the User to be Shadowed") {
        Write-Host "No User Selected"
        $ValidRunChecksResult = "No User Selected"
        Return $ValidRunChecksResult
        }
    }


Function ShadowUserSession {

    $UserUPN = $UserSession.Text
    $WVDHostPool = $HostPool.text
    If ($TakeControl.Checked -eq $True) {
        $AllowControl = "Yes"
        }
    Else {
        $AllowControl = "No"
        }

    $ShadowUser.Dispose()

    $Session = Get-RdsUserSession -TenantName $TenantName -HostPoolName $WVDHostPool | where { $_.UserPrincipalName -eq $UserUPN}

    Write-Host ; Write-Host $(Get-Date -Format HH:mm:ss:) -ForegroundColor Gray -NoNewLine ; Write-Host " Shadowing User " -NoNewline
    Write-Host $UserUPN -ForegroundColor Cyan -NoNewline ; Write-Host ", Connected to " -NoNewline
    Write-Host $Session.SessionHostName -ForegroundColor Green -NoNewline ; Write-Host " on Session ID " -NoNewline
    Write-Host $Session.SessionId -ForegroundColor Gray -NoNewline
    If ($AllowControl -eq "Yes") {
        Write-Host " with Remote Control " -NoNewline ; Write-Host "Enabled" -ForegroundColor Green
        Start-Process -FilePath "mstsc.exe" -ArgumentList "/v:$($Session.SessionHostName) /shadow:$($Session.SessionId) /control"
        }
    Else {
        Write-Host " with Remote Control " -NoNewline ; Write-Host "Disabled" -ForegroundColor Red
        Start-Process -FilePath "mstsc.exe" -ArgumentList "/v:$($Session.SessionHostName) /shadow:$($Session.SessionId)"
        }
    }

[void]$ShadowUser.ShowDialog()