#################################################################################################################################################################################################################################
<#

.ABOUT

Dylan Martinez | Shell FCU | 11/16/2017 | Episys Console Unlock
 
.HISTORY

Dylan Martinez | Shell FCU | 11/16/2017 | Created Project

.SUMMARY

The Unlock-EpisysConsole function will unlock a console.

#>
#################################################################################################################################################################################################################################

    ## Modules
    Import-Module Posh-SSH

    ## Configuration
    $config = GC "<Dev INI Location>\dev.example.ini"
    $config | % {

        if (($_ -ne "") -and ($_ -match "=")) {

            $key = ($_.Split("="));

            if ($key[1] -match ",") {

                Set-Variable -Name $key[0].trim() -Value @()

                ($key[1]).trim().split(",") | % { Invoke-Expression "`$$($key[0].trim()) += '$($_)'" }

            } else { New-Variable -Name $key[0].trim() -Value $key[1].trim() -Force }

        }

    }

#################################################################################################################################################################################################################################

## Episys Credentials
try
{
    ## Symitar Variables
    $symitarUser      = "<AIX Username>"
    $symitarPass      = GC "$credLoc\<AIX User Credential File Name>" | ConvertTo-SecureString -ErrorAction Stop
    $symitarCreds     = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $symitarUser, $symitarPass -ErrorAction Stop

    ## Episys Variables
    $userID           = GC "$credLoc\<Episys UserID File Name>" | ConvertTo-SecureString -ErrorAction Stop
    $userCryption     = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($userID)
    $userIDString     = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($userCryption)
}
catch
{
    $errorMessage = $_.Exception.Message
    
    switch ($errorMessage)
    {
        {($_ -match "Key not valid for use in specified state.")} { Write-Host "Review Symitar Credentials" }
        default { $errorMessage }
    }

    break
}

## Unlock Function
function Unlock-EpisysConsole {

    param(
          [string] $hostName,
          [System.Management.Automation.CredentialAttribute()] $hostCreds,
          [string] $userCreds,
          [int] $symNum,
          [string] $consoleNum
         )

    ## Production Episys Console Automation
    try
    {
        $symSession = New-SshSession -ComputerName "$hostName" -Credential $hostCreds
        $symStream  = $symSession.Session.CreateShellStream("symuser",0,0,0,0,1000); Sleep 1
    }
    catch
    {
        $errorMessage = $_.Exception.Message
    
        Write-Host "Symitar Session | $errorMessage"

        exit 1
    }

    ## Console Unlock
    $symStream.WriteLine("sym $symNum"); Sleep 1   ## SYM Selection
    $symStream.WriteLine("$userCreds"); Sleep 1    ## User Credentials
    $expiration = $symStream.read()                ## Password Expiration
    if($expiration -match "Your password will expire") {

        $days = $expiration.Substring(736,2)

        Write-Host "Your password will expire in $days!"

        $symStream.WriteLine("N");

    } else {  }
    $symStream.WriteLine("Y"); Sleep 1             ## Dedicate Console Y/N
    $symStream.WriteLine("8"); Sleep 1             ## Management Menu
    $symStream.WriteLine("6"); Sleep 1             ## Console Control
    $symStream.WriteLine("4"); Sleep 1             ## List of Consoles in Use
    $symStream.WriteLine("1"); Sleep 1             ## Reset Locked Consoles
    $symStream.WriteLine("$consoleNum");           ## Reset Locked Consoles
    $symStream.WriteLine("0");                     ## Unlock Console

}

## Example Execution

[string]$symNumber     = "007"
[string]$hostName      = "<Symitar Hostname>"
[string]$consoleNumber = "1234"

Unlock-EpisysConsole `
    -hostName $hostName `
    -hostCreds $symitarCreds `
    -symNum $symNumber `
    -userCreds $userIDString `
    -consoleNum $consoleNumber