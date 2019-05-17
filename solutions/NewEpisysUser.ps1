#################################################################################################################################################################################################################################
<#

.ABOUT

Dylan Martinez | Shell FCU | 12/25/2016 | Episys User Automation (SSH)
 
.HISTORY

Dylan Martinez | Shell FCU | 12/25/2016 | Created Project
Dylan Martinez | Shell FCU | 03/18/2017 | Function/Cmdlet Support
Dylan Martinez | Shell FCU | 05/20/2017 | Added params, two functions // testing..need cred support
Dylan Martinez | Shell FCU | 05/21/2017 | Added credential support // need try catch for permission failure
Dylan Martinez | Shell FCU | 11/16/2017 | Added dynamic creds // added try catch to connection // added if on personal directory

.SUMMARY

The New-EpisysUser function creates a new Episys user. You can set user property values by using the cmdlet parameters. 

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

## Connection
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

    ## SYMOP Variables
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

    break
}

function New-EpisysUser {

    param(
          [string] $hostName,
          [System.Management.Automation.CredentialAttribute()] $hostCreds,
          [string] $userCreds,
          [string] $operatorString,
          [int] $symNum,
          [string] $userNumber,
          [string] $userName,
          [string] $userEmail,
          [string] $userTitle,
          [string] $userBranch,
          [string] $userDepartment,
          [string] $userPassword,
          [int] $userPrivilege,
          [switch] $createDirectory,
          [string] $userDirectory
         )
    
    function createUserDirectory {

        try
        {
        ## Create SSH Session / Stream
        $session = New-SshSession -ComputerName $hostName -Credential $hostCreds
        $stream  = $session.Session.CreateShellStream("stream",0,0,0,0,1000); Sleep 1
        }
        catch
        {
            $errorMessage = $_.Exception.Message
    
            switch ($errorMessage)
            {
                {($_ -match "Key not valid for use in specified state.")} { Write-Host "Credentials must be created on the execution machine." }
                {($_ -match "Permission denied")} {Write-Host "Review Symitar Credentials (username/password)"}
                default { $errorMessage }
            }

            break

        }

        $stream.WriteLine("symop"); Sleep 1           ## SYMOP
        $stream.WriteLine("$operatorString"); Sleep 1 ## Operator ID
        $stream.WriteLine("PERS");                    ## PERS
        $stream.WriteLine("0");                       ## (0) Create a Personal Directory
        $stream.WriteLine("$userDirectory"); Sleep 1  ## Personal Directory Name
        $existingDir = $stream.read()                 ## Existing Directory
        if($existingDir -match "Directory already exists!") {
    
            Write-Host "Personal Directory already exists!"

        } else {

            $stream.WriteLine("2");                       ## (2) Accessible from a specific SYM Institution
            $stream.WriteLine("$symNum");                 ## Institutions
            $stream.WriteLine("0");                       ## Log on to a specific SYM Institution
            $stream.WriteLine("");                        ## Institution
            $stream.WriteLine("");                        ## FTP Access to Institutions
            $stream.WriteLine("Y"); Sleep 1               ## Okay?
            $stream.WriteLine("$userPassword"); Sleep 1   ## Temporary Password
            $stream.WriteLine("$userPassword"); Sleep 7   ## Temporary Password x2
            $stream.WriteLine("EXIT"); Sleep 1            ## Back to Console

        }

    }

    function createUser {

        try
        {
        ## Create SSH Session / Stream
        $session = New-SshSession -ComputerName $hostName -Credential $hostCreds
        $stream  = $session.Session.CreateShellStream("stream",0,0,0,0,1000); Sleep 1
        }
        catch
        {
            $errorMessage = $_.Exception.Message
    
            switch ($errorMessage)
            {
                {($_ -match "Key not valid for use in specified state.")} { Write-Host "Credentials must be created on the execution machine." }
                {($_ -match "Permission denied")} {Write-Host "Review Symitar Credentials (username/password)"}
                default { $errorMessage }
            }

            break

        }

        $stream.WriteLine("sym $symNum");           ## SYM Selection
        $stream.WriteLine("$userCreds"); Sleep 1    ## User Credentials
        $expiration = $stream.read()                ## Password Expiration
        if($expiration -match "Your password will expire") {

            $days = $expiration.Substring(736,2)

            Write-Host "Your password will expire in $days!"

            $stream.WriteLine("N");

        } else {  }
        $stream.WriteLine("Y");              ## Dedicate Console Y/N
        $stream.WriteLine("8");              ## Management Menu
        $stream.WriteLine("7");              ## User Control
        $stream.WriteLine("1");              ## User Maintenance
        $stream.WriteLine("1");              ## User File Maintenance
        $stream.WriteLine("$userNumber");    ## UserID
        $stream.WriteLine("");               ## Enter Through
        $stream.WriteLine("0");              ## User Write
        $stream.WriteLine("1");              ## Name Selection
        $stream.WriteLine("$userName");      ## UserName
        $stream.WriteLine("2");              ## Password Selection
        $stream.WriteLine("$userPass");      ## TempPass
        $stream.WriteLine("8");              ## Email Selection
        $stream.WriteLine("$userEmail")      ## EmailAddress
        $stream.WriteLine("13")              ## Directory Selection
        $stream.WriteLine("$userDirectory")  ## Personal Directory
        $stream.WriteLine("");               ## Enter Through
        $stream.WriteLine("1");              ## Title Selection
        $stream.WriteLine("$userTitle");     ## Job Title
        $stream.WriteLine("4");              ## Location Selection
        $stream.WriteLine("$userBranch");    ## Branch Name
        $stream.WriteLine("5");              ## Department Selection
        $stream.WriteLine("$userDepartment");## Department Name
        $stream.WriteLine("");               ## Enter Through
        $stream.WriteLine("1");              ## Privilege Group Selection
        $stream.WriteLine("$userPrivilege"); ## Privilege Group (Set it to whatever)
        $stream.WriteLine("");               ## Enter Through
        $stream.WriteLine("Y"); Sleep 1      ## Okay Y/N

    }

    if($createDirectory) {

        createUserDirectory
        createUser

    } else { createUser }

}

## User Variables
[string]$userNumber = "1337"
[string]$userName   = "Smug Master"
[string]$userEmail  = "smug.master@smugmaster.org"
[string]$userDir    = "smugm"
[string]$userTitle  = "The Smug Master"
[string]$userDept   = "Information Technology"
[string]$userBranch = "Deer Park"
[string]$userPass   = "Password1!"
[string]$symNumber  = "007"
[string]$hostName   = "<Symitar Hostname>"

New-EpisysUser `
    -hostName $hostName `
    -hostCreds $symitarCreds `
    -operatorString $operatorString `
    -symNum $symNumber `
    -userCreds $userIDString `
    -userNumber $userNumber `
    -userName $userName `
    -userEmail $userEmail `
    -userTitle $userTitle `
    -userBranch $userBranch `
    -userDepartment $userDept `
    -userPassword $userPass `
    -userPrivilege "1" `
    -createDirectory `
    -userDirectory $userDir