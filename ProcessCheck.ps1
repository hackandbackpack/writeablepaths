# Introduction message
Write-Host "Listing processes with writable directories:"

# Get all running processes
$processes = Get-Process | Where-Object { $_.Path -ne $null }

# Create an empty array to store the results
$results = @()

# Check write permission and get process owner for each process
foreach ($process in $processes) {
    # Skip the process if the path is null
    if ($null -eq $process.Path) {
        continue
    }

    $folderPath = Split-Path $process.Path
    $canWrite = $false
    $testFilePath = Join-Path $folderPath ("tempfile" + [System.Guid]::NewGuid().ToString() + ".txt")
    $processOwner = $null

    # Get the owner of the process
    try {
        $processOwner = (Get-WmiObject Win32_Process -Filter "ProcessId = $($process.Id)").GetOwner().User
    } catch {
        $processOwner = "Unknown"
    }

    # Attempt to create a temporary file to check write permission
    try {
        New-Item -ItemType File -Path $testFilePath -Force -ErrorAction SilentlyContinue | Out-Null
        if (Test-Path $testFilePath) {
            $canWrite = $true
            Remove-Item -Path $testFilePath -Force -ErrorAction SilentlyContinue
        }
    } catch {
        $canWrite = $false
    }

    # Add the result to the array if the directory is writable
    if ($canWrite) {
        $results += [PSCustomObject]@{
            ProcessName = $process.ProcessName
            Path = $folderPath
            Owner = $processOwner
        }
    }
}

# Output the results formatted as a table with wrapped text
$results | Format-Table -AutoSize -Wrap

# Note: The script now uses Format-Table with AutoSize and Wrap to display the full directory paths.
