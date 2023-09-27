
##### Procces Check ####
function ProcessCheck {
    if ($?) {
        Write-Host "Successuf"
        Write-host "---------"
    }
    else {
        Write-Host "Failed"
	Write-host "---------"
    }
}

#### Run Again ####
function RunAgain {
$RunAgain = Read-Host "Would you like to run again? (Y/N)"
    if ($RunAgain -eq "Y") {
    OUConfiguration
    }
    else {
    exit
    }
}

##### OU Configuration #######
function OUConfiguration {

    ####Settings Configuration ####
    $NewOU = Read-Host "Please enter New OU Name"
    $UserCount = Read-Host "Please enter number of new users in the new OU"
    $SysAdminCount = Read-Host "Please enter number of SysAdmins"
    $Path = "OU=$NewOU,DC=kernel,DC=com" 
    $Nickname = $NewOU.Substring(0,3)
    $NicknameConfirm = Read-Host "Your users nickname will be $Nickname-user. OK? (Y/N)"
        if ($NicknameConfirm -eq "N") {
        $Nickname = read-host "Please enter your preffered user nickname"
        }
    
    #### OU Creation ####
    New-ADOrganizationalUnit -Name "$NewOU" -Path "DC=kernel,DC=com" -ProtectedFromAccidentalDeletion $false
    write-host "OU Creation"
    ProcessCheck

    #### Computer Sub-OU Creation #### 
    New-ADOrganizationalUnit -Name "Computers" -Path "$Path" -ProtectedFromAccidentalDeletion $false
    write-host "Computer OU Creation"
    ProcessCheck

    #### Users Sub-OU Creation ####
    New-ADOrganizationalUnit -Name "Users" -Path "$Path" -ProtectedFromAccidentalDeletion $false
    for ($i=1; $i -le $UserCount; $i++) {
        New-ADUser -Path "OU=Users, $Path" -Name "$Nickname-User$i" -SamAccountName "$Nickname-User$i" -UserPrincipalName "$Nickname-User$i" -AccountPassword (ConvertTo-SecureString "qwer4321!" -AsPlainText -Force) -Enabled $true
    } 
    write-host "User OU Creation"
    ProcessCheck 
    
    #### Groups Sub-OU Creation ####
    New-ADOrganizationalUnit -Name "Groups" -Path "$Path" -ProtectedFromAccidentalDeletion $false
    New-ADGroup -path "OU=Groups, $Path" -name "$NewOU" -SamAccountName "$NewOU" -GroupCategory Security -GroupScope Global -DisplayName "$NewOU Group"
    for ($i=1; $i -le $UserCount; $i++) {
        Add-ADGroupMember -Identity $NewOU -Members "$Nickname-User$i" 
    }
    write-host "Group OU Creation"
    ProcessCheck
    
    #### SysAdmin Sub-OU Creation ####
    if ($SysAdminCreation) {
        New-ADOrganizationalUnit -Name "SysAdmin" -Path "DC=kernel,DC=com" -ProtectedFromAccidentalDeletion $false
        New-ADOrganizationalUnit -Name "Users" -Path "OU=SysAdmin,DC=kernel,DC=com" -ProtectedFromAccidentalDeletion $false
        New-ADOrganizationalUnit -Name "Computers" -Path "OU=SysAdmin,DC=kernel,DC=com" -ProtectedFromAccidentalDeletion $false
        New-ADOrganizationalUnit -Name "Groups" -Path "OU=SysAdmin,DC=kernel,DC=com" -ProtectedFromAccidentalDeletion $false
        
        New-ADGroup -path "OU=Groups,OU=SysAdmin,DC=kernel,DC=com" -name "SysAdmin" -SamAccountName "SysAdmin" -GroupCategory Security -GroupScope Global -DisplayName "SysAdmin Group"
        for ($i=1; $i -le $SysAdminCount; $i++) {
            New-ADUser -Path "OU=Users,OU=SysAdmin,DC=kernel,DC=com" -Name "SysAdmin$i" -SamAccountName "SysAdmin$i" -UserPrincipalName "SysAdmin$i" -AccountPassword (ConvertTo-SecureString "qwer4321!" -AsPlainText -Force) -Enabled $true
            Add-ADGroupMember -Identity "SysAdmin" -Members "SysAdmin$i"
        }
        $SysAdminCreation = $false
        write-host "SysAdmin Creation"
        ProcessCheck
    }
    else {
        write-host "SysAdmin Creation skipped because it can only be created once. You have created $SysAdminCount SysAdmins"
    }

    #### SysAdmin Deligate Control to Password Reset ####
    # set-adpermission -identity $NewOU -user "SysAdmin" -AccessRights ExtendedRight -extendedRights "Reset Password"
    # Write-Host "Reset Password Deligation"
    # ProcessCheck

    #### Run Again ####
    RunAgain
}

$SysAdminCreation = $true
OUConfiguration 2> $null
