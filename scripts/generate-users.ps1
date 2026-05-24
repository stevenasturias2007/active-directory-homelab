# Define pools of realistic data to mix and match
$FirstNames = @("John","Jane","Michael","Emily","David","Sarah","James","Jessica","Robert","Ashley","William","Amanda","Joseph","Stephanie","Chris","Nicole","Matthew","Rachel","Daniel","Megan")
$LastNames = @("Smith","Johnson","Williams","Brown","Jones","Garcia","Miller","Davis","Rodriguez","Martinez","Hernandez","Lopez","Gonzalez","Wilson","Anderson","Thomas","Taylor","Moore","Jackson","Martin")
$Depts = @("HR", "IT", "Finance", "Sales", "Marketing")
$Titles = @("Coordinator", "Specialist", "Analyst", "Manager", "Director")

$UsersList = @()

# Loop until we hit exactly 100 unique names
while ($UsersList.Count -lt 100) {
    $RandomFirst = Get-Random -InputObject $FirstNames
    $RandomLast = Get-Random -InputObject $LastNames
    $RandomDept = Get-Random -InputObject $Depts
    $RandomTitle = "$RandomDept $(Get-Random -InputObject $Titles)"
    
    # Check for duplicate names to keep data clean
    $DuplicateCheck = $UsersList | Where-Object { $_.FirstName -eq $RandomFirst -and $_.LastName -eq $RandomLast }
    if (-not $DuplicateCheck) {
        $UserObj = [PSCustomObject]@{
            FirstName  = $RandomFirst
            LastName   = $RandomLast
            Department = $RandomDept
            JobTitle   = $RandomTitle
        }
        $UsersList += $UserObj
    }
}

# Save all 100 users to your C drive
$UsersList | Export-Csv -Path "C:\lab_users_100.csv" -NoTypeInformation
Write-Host "Success! Created a roster file with $($UsersList.Count) users at C:\lab_users_100.csv" -ForegroundColor Green