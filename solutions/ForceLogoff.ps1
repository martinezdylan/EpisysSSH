#################################################################################################################################################################################################################################
<#

.ABOUT

Dylan Martinez | Shell FCU | 10/25/2017 | Episys Force Log Off
 
.HISTORY

Dylan Martinez | Shell FCU | 10/25/2017 | Created
Dylan Martinez | Shell FCU | 11/16/2017 | Updated password expiration message

.SUMMARY

This will determine the users currently logged into Episys and force them off.

#>
#################################################################################################################################################################################################################################

    ## Modules
    Import-Module Posh-SSH

    ## Configuration
    $config = GC "<Dev INI Location>\<Dev INI>.ini"
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

## General Arguments
[string]$symNum = $args[0]

    ## Symitar Connection
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

        ## Symop Variables
        $operatorID       = GC "$credLoc\<Symop OperatorID File Name>" | ConvertTo-SecureString -ErrorAction Stop
        $operatorCryption = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($operatorID)
        $operatorString   = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($operatorCryption)
    }
    catch
    {
        $errorMessage = $_.Exception.Message
    
        switch ($errorMessage)
        {
            {($_ -match "Key not valid for use in specified state.")} { Write-Host "Review Symitar Credentials" }
            default { $errorMessage }
        }

        exit 1
    }

## Production Episys Console Automation
try
{
$symSession = New-SshSession -ComputerName "<Symitar Hostname>" -Credential $symitarCreds
$symStream  = $symSession.Session.CreateShellStream("symuser",0,0,0,0,1000); Sleep 1
}
catch
{
    $errorMessage = $_.Exception.Message
    
    Write-Host "Symitar Session | $errorMessage"

    exit 1
}

        ## Production Force Log Off
        $symStream.WriteLine("sym $symNum"); Sleep 1   ## SYM Selection
        $symStream.WriteLine("$userIDString"); Sleep 1 ## User Credentials
        $expiration = $symStream.read()                ## Password Expiration
        if($expiration -match "Your password will expire") {

            $days = $expiration.Substring(736,2)

            Write-Host "Your password will expire in $days!"

            $symStream.WriteLine("N");

        } else {  }
        $symStream.WriteLine("Y"); Sleep 1             ## Dedicate Console Y/N
        $symStream.WriteLine("8"); Sleep 1             ## Management Menu
        $symStream.WriteLine("6"); Sleep 1             ## Console Control
        $symStream.WriteLine("3"); Sleep 1             ## List of Consoles in Use
        $symStream.WriteLine("");  Sleep 1             ## Enter Through
        $output = $symStream.read()                    ## Consoles In Use
        $symStream.Dispose()                           ## Dispose Login

Remove-SSHSession -SSHSession $symSession | Out-Null

    ## Create Console List Array
    $i        = 0
    $begin    = $false
    $consoles = @()
    $output.Split("`n") | % {

        $line = $_

        ## Check For Start
        if ( $line -match "--" ) { $i++; $begin = $true; }

        ## Create Array
        if ( ($begin -eq $true) -and ($i -eq 1) -and ($line -notmatch "[a-zA-Z]")) {

            $line.Split(",") | % {

                if ($_ -match "[0-9]") {

                    $consoles += $_

                }

            }

        }

    }

## Production Episys Console Automation
try
{
$symSession = New-SshSession -ComputerName "<Symitar Hostname>" -Credential $symitarCreds
$symStream  = $symSession.Session.CreateShellStream("symuser",0,0,0,0,1000); Sleep 1
}
catch
{
    $errorMessage = $_.Exception.Message
    
    Write-Host "Symitar Session | $errorMessage"

    exit 1
}
    ## Force Log Off
    $symStream.WriteLine("symop"); Sleep 1           ## SYMOP
    $symStream.WriteLine("$operatorString"); Sleep 1 ## Operator Credentials
    $symStream.WriteLine("FORCE");                   ## FORCE

        ## Loop Consoles
        $tempCons = ""
        $consoles | % {

            $console = $_
            
            if ( ($tempCons -eq "") -and ($console -ne "") ) { $tempCons += $console } else { $tempCons = $tempCons + "," + $console }
            
        }

    $symStream.WriteLine("$tempCons");              ## FORCE
    $symStream.WriteLine("EXIT"); Sleep 1           ## Back to Console

Remove-SSHSession -SSHSession $symSession | Out-Null