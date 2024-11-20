# Batch size for processing
$batchSize = 20

# Connect to Microsoft Graph with appropriate permissions
Write-Output "Connecting to Microsoft Graph..."
Connect-MgGraph -Scopes "User.Read.All", "IdentityRiskyUser.ReadWrite.All", "IdentityRiskyUser.Read.All"

# Load user IDs from ids.txt file
$userIds = Get-Content -Path "ids.txt"
$totalUserCount = $userIds.Count
Write-Host "Total user IDs to process: $totalUserCount"

# Initialize counter for tracking
$processedCount = 0

# Process in batches
for ($i = 0; $i -lt $userIds.Count; $i += $batchSize) {
    # Define the current batch of user IDs
    $batchUserIds = $userIds[$i..([Math]::Min($i + $batchSize - 1, $userIds.Count - 1))]

    Write-Host "Attempting to dismiss risk state for batch $((($i / $batchSize) + 1))..."

    try {
        # Attempt to dismiss risk state for all user IDs in this batch
        Invoke-MgDismissRiskyUser -BodyParameter @{ userIds = $batchUserIds } -ErrorAction Stop
        Write-Host "Risk state dismissed for $($batchUserIds.Count) users in batch $((($i / $batchSize) + 1))."

        # If the batch is successful, log successful dismissals to processed.txt and output user IDs
        $batchUserIds | ForEach-Object {
            Add-Content -Path "processed.txt" -Value $_
            Write-Host "Processed user ID: $_"
        }

        # Update processed counter
        $processedCount += $batchUserIds.Count

        # Output processed so far out of total
        Write-Host "Processed $processedCount out of $totalUserCount users so far."

    } catch {
        Write-Error "Failed to dismiss risk state for batch $((($i / $batchSize) + 1)). Error: $_"
    }

    # Only remove processed batch from ids.txt if the batch was successful
    if ($processedCount -gt 0) {
        $remainingUserIds = Get-Content -Path "ids.txt" | Where-Object { $batchUserIds -notcontains $_ }
        Set-Content -Path "ids.txt" -Value $remainingUserIds
    }
}

Write-Host "Script execution completed. Total users processed: $processedCount out of $totalUserCount."
