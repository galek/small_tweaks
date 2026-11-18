# Get the number of logical processors to calculate accurate CPU percentage
$LogicalProcessors = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors

# Query performance counters for all processes excluding _Total and Idle
$TopProcess = Get-Counter '\Process(*)\% Processor Time' -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty CounterSamples |
    Where-Object { $_.InstanceName -notin @('_total', 'idle') } |
    ForEach-Object {
        [PSCustomObject]@{
            Name       = $_.InstanceName
            CpuPercent = [math]::Round($_.CookedValue / $LogicalProcessors, 2)
        }
    } |
    Sort-Object CpuPercent -Descending |
    Select-Object -First 1

# Output the top CPU-consuming process name and load
if ($TopProcess) {
    Write-Host "Top CPU Process: $($TopProcess.Name) ($($TopProcess.CpuPercent)%)" -ForegroundColor Yellow
} else {
    Write-Host "No active process data retrieved." -ForegroundColor Red
}
