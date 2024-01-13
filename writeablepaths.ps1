# Get all running processes
$processes = Get-Process | Where-Object { $_.Path -ne $null }

# Check write permission and get process owner for each process
foreach ($process in $processes) {
    $folderPath = Split-Path $process.Path
    $canWrite = $false
    $testFilePath = Join-Path $folderPath ("tempfile" + [System.Guid]::NewGuid().ToString() + ".txt")
    $processOwner = $null

    # Get the owner of the process
    try {
        $processOwner = (Get-WmiObject Win32_Process -Filter "ProcessId = $($process.Id)").GetOwner().User
    } catch {
        # Silently handle exceptions
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
        # Silently handle exceptions
        $canWrite = $false
    }

    # Output the result
    [PSCustomObject]@{
        ProcessName = $process.ProcessName
        Path = $folderPath
        CanWrite = $canWrite
        Owner = $processOwner
    }
}

# Note: This script might require administrative privileges for accurate results, especially for system processes or services.
