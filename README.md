These two PowerShell scripts will allow you to select any user logged into any Windows Virtual Desktop Session host within your tenant and then shadow that directly, rather then having to find the Sesison Host and Session ID.

Background info is here: https://xenithit.blogspot.com/2020/06/how-to-shadow-across-multiple-host_22.html

Start with 1. Save WVD Service Principal Password.ps1 which will save your Service Principal details in a local file
Then 2. Shadow a User.ps1 will connect to your WVD tenant and list in a GUI all Host Pools and all conencted users in each Host Pool

If you are using a user account rather than a Service Principal you can remove teh Service Principal parts and just add and run: 
Add-RdsAccount -DeploymentUrl https://rdbroker.wvd.microsoft.com -Credential "<UPN@domain.com>"

Credit goes to Garry Down at Ultima for creating the originals
