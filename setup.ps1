$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "refresh-rate.ps1"
$taskName = "Automatic Refresh Rate"

if (-not (Test-Path $scriptPath)) {
    Write-Host "ERROR: refresh-rate.ps1 not found."
    exit 1
}

# Run refresh-rate.ps1
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""

# Trigger when Windows reports a power-source change
$eventTrigger = New-ScheduledTaskTrigger `
    -AtStartup

# Create/update the task
$principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -LogonType Interactive `
    -RunLevel Highest

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $eventTrigger `
    -Principal $principal `
    -Force | Out-Null

# Add the actual Event 105 trigger using schtasks XML
$xml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Triggers>
    <EventTrigger>
      <Enabled>true</Enabled>
      <Subscription>
        <![CDATA[
        <QueryList>
          <Query Id="0">
            <Select Path="System">
              *[System[
                Provider[@Name='Microsoft-Windows-Kernel-Power']
                and (EventID=105)
              ]]
            </Select>
          </Query>
        </QueryList>
        ]]>
      </Subscription>
    </EventTrigger>
  </Triggers>

  <Principals>
    <Principal id="Author">
      <UserId>$env:USERDOMAIN\$env:USERNAME</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>

  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <ExecutionTimeLimit>PT1M</ExecutionTimeLimit>
  </Settings>

  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "$scriptPath"</Arguments>
    </Exec>
  </Actions>
</Task>
"@

$tempXml = Join-Path $env:TEMP "RefreshRateTask.xml"

$xml | Out-File -FilePath $tempXml -Encoding Unicode

schtasks.exe /Create `
    /TN $taskName `
    /XML $tempXml `
    /F | Out-Null

Remove-Item $tempXml -Force

Write-Host ""
Write-Host "================================="
Write-Host " Refresh Rate Switcher Installed"
Write-Host "================================="
Write-Host ""
Write-Host "AC power  -> 144 Hz"
Write-Host "Battery   -> 60 Hz"
Write-Host ""
Write-Host "Trigger: Kernel-Power Event 105"