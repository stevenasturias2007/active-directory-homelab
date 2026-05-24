Import-Module ActiveDirectory

# === CONFIGURATION ===
$CSVPath = "C:\lab_users_100.csv"   
# =====================

if (Test-Path $CSVPath) {
    $Users = Import-Csv -Path $CSVPath
    $Counter = 1
    
    foreach ($User in $Users) {
        $GroupName = "GG-$($User.Department)-Users"
        
        # Search AD for a user matching this exact First and Last name combo
        # This will find them regardless of whether they end in 1, 2, 3, or anything else!
        $ADUser = Get-ADUser -Filter "GivenName -eq '$($User.FirstName)' -and Surname -eq '$($User.LastName)'"
        
        if ($ADUser) {
            # Grab the actual, real username from Active Directory
            $ActualSAMAccountName = $ADUser.SamAccountName
            
            try {
                # Force add the real username directly to the group
                Add-ADGroupMember -Identity $GroupName -Members $ActualSAMAccountName -ErrorAction Stop
                Write-Host "[$Counter/100] Success: Added $ActualSAMAccountName to $GroupName" -ForegroundColor Green
            } 
            catch {
                Write-Host "[$Counter/100] ERROR adding $ActualSAMAccountName to $GroupName : $_" -ForegroundColor Red
            }
        } else {
            Write-Host "[$Counter/100] Skip: Could not find a user named $($User.FirstName) $($User.LastName) in AD." -ForegroundColor Yellow
        }
        $Counter++
    }
    Write-Host "Security group synchronization complete!" -ForegroundColor Cyan
} else {
    Write-Error "Could not find the CSV file at $CSVPath."
}