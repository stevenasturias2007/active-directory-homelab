Import-Module ActiveDirectory

# === CONFIGURATION (Pre-filled for your lab) ===
$DomainDNS = "myhomelab.local"        
$DomainUPN = "@" + $DomainDNS
$CSVPath   = "C:\lab_users_100.csv"   
# ===============================================

# Break down your domain name into Distinguished Name format (DC=myhomelab,DC=local)
$DomainDN = "DC=" + ($DomainDNS -replace '\.', ',DC=')

# Define a single root folder to keep your lab organized
$ParentOUName = "Departments"
$ParentOUPath = "OU=$ParentOUName,$DomainDN"

# 1. Create the master Parent OU if it doesn't exist
if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ParentOUPath'")) {
    Write-Host "Creating master Parent OU: $ParentOUName..." -ForegroundColor Cyan
    New-ADOrganizationalUnit -Name $ParentOUName -Path $DomainDN
}

# 2. Process the 100 users
if (Test-Path $CSVPath) {
    $Users = Import-Csv -Path $CSVPath
    $Counter = 1

    foreach ($User in $Users) {
        # Establish naming conventions (First Initial + Last Name -> e.g., jsmith)
        $BaseSAM = ($User.FirstName.Substring(0,1) + $User.LastName).ToLower()
        $SAMAccountName = $BaseSAM
        $UPN = $SAMAccountName + $DomainUPN
        $DisplayName = "$($User.FirstName) $($User.LastName)"
        
        # Resolve potential duplicate usernames (e.g., if there are two John Smiths -> jsmith, jsmith1)
        $Append = 1
        while (Get-ADUser -Filter "SamAccountName -eq '$SAMAccountName'") {
            $SAMAccountName = $BaseSAM + $Append
            $UPN = $SAMAccountName + $DomainUPN
            $Append++
        }

        # Target Department OU Path
        $DeptOUPath = "OU=$($User.Department),$ParentOUPath"

        # 3. Create Department OU dynamically if missing
        if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$DeptOUPath'")) {
            Write-Host "Creating missing department folder: $($User.Department)..." -ForegroundColor Cyan
            New-ADOrganizationalUnit -Name $User.Department -Path $ParentOUPath
        }

        # 4. Create the User Account
        $SecurePassword = ConvertTo-SecureString "LabPassword123!" -AsPlainText -Force
        
        Write-Host "[$Counter/100] Provisioning: $DisplayName ($SAMAccountName)" -ForegroundColor Green
        
        New-ADUser -Name $DisplayName `
                   -SamAccountName $SAMAccountName `
                   -UserPrincipalName $UPN `
                   -GivenName $User.FirstName `
                   -Surname $User.LastName `
                   -DisplayName $DisplayName `
                   -Title $User.JobTitle `
                   -Department $User.Department `
                   -Path $DeptOUPath `
                   -AccountPassword $SecurePassword `
                   -Enabled $true `
                   -ChangePasswordAtLogon $false
                   
        $Counter++
    }
    Write-Host "All 100 users processed successfully!" -ForegroundColor Green
} else {
    Write-Error "Could not find the CSV file at $CSVPath. Please run Step 1 first!"
}