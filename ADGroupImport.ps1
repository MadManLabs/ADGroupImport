[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
   [string]$filePath
)

# Variables to hold if the data is still good. 
[Boolean]$GroupsValid = 1;
[Boolean]$UsersValid = 1;

# Import CSV
$Data = Import-CSV $filePath;

If($Data.Length -lt 1)
{
    exit;
}

# Parse out all the groups
$Groups = ($Data | Select-Object -Property * -ExcludeProperty "Last Name","First Name" | Get-Member | Where-Object {$_.MemberType -eq "NoteProperty"}).Name

# Parse out Users
$Users = $Data | Select-Object "First Name","Last Name"


Write-Host "`n === Check Users === `n`n" -ForegroundColor White


# Check that Users exist
foreach($user in $Users)
{
    $fn = $User."First Name"
    $ln = $user."Last Name"
    $u = Get-ADUser -ErrorAction SilentlyContinue -Filter {(GivenName -eq $fn) -and (Surname -eq $ln)}

    if([String]::IsNullOrEmpty($u))
    {
        Write-Host "[!] ERROR: $fn $ln - No User Found" -ForegroundColor Red
        $UsersValid = $false;
    }
}

Write-Host "`n === Check Groups === `n`n" -ForegroundColor White

# Check if the Groups Exist
foreach($group in $Groups)
{
    $gn = $group

    $g = Get-ADGroup -ErrorAction SilentlyContinue -Filter {(Name -eq $gn)}

    if([String]::IsNullOrEmpty($g))
    {
        Write-Host "[!] ERROR: $gn - No Group Found" -ForegroundColor Red
        $GroupsValid = $false;
    }
}

# If no errors with users or groups, run through the add process. 
if(($GroupsValid -eq $true) -and ($UsersValid -eq $true))
{
    foreach($group in $Groups)
    {

        # Get the AD Object for the group. 
        $g = Get-ADGroup -ErrorAction SilentlyContinue -Filter {(Name -eq $group)}
    
        # Loop through each data object
        foreach($d in $Data)
        {
            # If there is a character in the column, we need to add the user to the group. 
            if( -not ([String]::IsNullOrEmpty(($d | Select-Object -ExpandProperty $group)) ))
            {

                # Get the user object
                $fn = $d."First Name"
                $ln = $d."Last Name"
                $u = Get-ADUser -ErrorAction SilentlyContinue -Filter {(GivenName -eq $fn) -and (Surname -eq $ln)}

                # Add the object
                Add-ADGroupMember $g $u.SamAccountName -Confirm:$false -Verbose
                #Write-Host "$($g.Name) :: $($u.SamAccountName)"
            }
        }

    }
}


