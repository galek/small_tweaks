# Get the number of logical processors to calculate accurate CPU percentage
$LogicalProcessors = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors

# Query formatted performance data directly via CIM (language-independent)
$TopProcess = Get-CimInstance Win32_PerfFormattedData_PerfProc_Process |
    Where-Object { $_.Name -notin @('_Total', 'Idle') } |
    Select-Object Name, IDProcess, @{
        Name       = 'CpuPercent'
        Expression = { [math]::Round($_.PercentProcessorTime / $LogicalProcessors, 2) }
    } |
    Sort-Object CpuPercent -Descending |
    Select-Object -First 1

# Output the top CPU-consuming process name, PID, and load
if ($TopProcess) {
    Write-Host "Top CPU Process: $($TopProcess.Name) (PID: $($TopProcess.IDProcess)) - $($TopProcess.CpuPercent)%" -ForegroundColor Yellow
} else {
    Write-Host "No active process data retrieved." -ForegroundColor Red
}
