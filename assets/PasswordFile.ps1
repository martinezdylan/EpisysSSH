##################################################################################################################################################################################################################################
<#

.ABOUT

Dylan Martinez | Shell FCU | 08/18/2017 | Password File
 
.HISTORY

Dylan Martinez | Shell FCU | 08/18/2017 | Created
Dylan Martinez | Shell FCU | 08/19/2017 | Modified File Location / Added Description

.SUMMARY

Use this to create your secure string to be referenced in remote execution. This is user AND machine
specific, meaning the user and machine you execute it on is the only user/machine combination that can
use the credential.

.NOTE

Username doesn't matter when inputing the credential, only the password.

#>
#################################################################################################################################################################################################################################

$filePath = "\\<Server Name>\<Shared Directory>"
$fileName = "dm_example"

$credential = Get-Credential
$credential.Password | ConvertFrom-SecureString | Set-Content "$filePath\$fileName"