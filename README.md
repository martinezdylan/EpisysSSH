# EpisysSSH
A few legacy solutions that leveraged SSH streams to automate various tasks for Symitar based Credit Unions.

## Requirements (ALL)

- SSH Access to Symitar host
- [SYMULATE/Episys Text Mode](#SYMULATE-and-Episys-Text-Mode)
- [Posh-SSH](https://github.com/darkoperator/Posh-SSH)
- PowerShell 4.0+

## Installation (ALL)

Assuming you've met the requirements, you will also need to configure a `dev.ini` file that is used at the beginning of each solution.

__Example:__

```ini
####################################################################################################
##
## DevTeam Configuration File
##
####################################################################################################

[PowerShell]
SMTPServer   = 127.0.0.1
from         = automation@cu.org
devTeamEmail = devteam@cu.org
devTeamText  = 7135550101@vzwpix.com,7135550102@vzwpix.com
archLoc      = \\shared01\DevArch
credLoc      = \\shared01\DevCreds
tempLoc      = \\shared01\DevTemp
ocagent      = OCAGENT01
```

You will also need to create a few of passwords for __Symitar__, __EpisysUserID__, and __SYMOP__.

__Symitar Example:__

```powershell
$filePath = "\\shared01\DevCreds"
$fileName = "dm_aix"

$credential = Get-Credential
$credential.Password | ConvertFrom-SecureString | Set-Content "$filePath\$fileName"
```

__Note:__ A credential prompt will pop-up, you can type whatever you'd like for the username but enter in the password for the AIX user that will access the Symitar host.

__EpisysUserID/SYMOP Example:__

```powershell
$filePath = "\\shared01\DevCreds"
$fileName = "dm_episys" ## or "dm_symop"

$credential = Get-Credential
$credential.Password | ConvertFrom-SecureString | Set-Content "$filePath\$fileName"
```

__Note:__ Similarly, a credntial prompt will pop-up, username is irrelevant however as these passwords will be required to pass in as strings through the automation you'll need to type the full string. Ex: 1337.Password1!

Finally, to successfully use any of the solutions, you will need to parse through and replace any filler text `<Insert Value Here>` with values that support your institution.

## SYMULATE and Episys Text Mode

You can confirm as to whether or not you have access to this feature via the AIX shell.

```bash
$ sym 1
```

__Note:__ The SYM number doesn't matter. SYM001 was simply used as an example.

If you receive a menu similar to the following, after typing in your __UserID__ and __Dedicating the User to the Console__, all solutions will work:

```bash

                               ***************
                               *  Main Menu  *
                   *************             *************
                   *                                     *
                   *     (0) Teller Transactions         *
                   *     (1) Account Inquiries           *
                   *     (2) Account File Maintenance    *
                   *     (3) Payee Control               *
                   *     (4) Projections                 *
                   *     (5) Personal File Control       *
                   *     (6) Teller Totals               *
                   *     (7) Message System              *
                   *     (8) Management Menu             *
                   *                                     *
                   ***************************************

                             Menu Selection [0] :

```

## Questions/Concerns

Please direct all questions to me via SMUG.