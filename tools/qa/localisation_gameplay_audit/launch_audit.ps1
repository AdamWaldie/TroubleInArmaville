param(
    [switch]$Run,
    [string[]]$Languages,
    [int]$ResolutionWidth = 3840,
    [int]$ResolutionHeight = 2160,
    [int]$TimeoutSeconds = 300,
    [string]$OutputDirectory = ".\.qa\localisation-gameplay-audit",
    [string]$PythonExecutable
)

$ErrorActionPreference = "Stop"
$qaRoot = $PSScriptRoot
$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $qaRoot))
$manifest = Get-Content (Join-Path $qaRoot "audit_manifest.json") -Raw | ConvertFrom-Json
if ($null -eq $Languages -or $Languages.Count -eq 0) {
    $Languages = @($manifest.languages)
}
foreach ($language in $Languages) {
    if ($language -notin $manifest.languages) { throw "Unsupported language: $language" }
}

$pythonPrefix = @()
if (-not [string]::IsNullOrWhiteSpace($PythonExecutable)) {
    $pythonPath = $PythonExecutable
    if (-not (Test-Path -LiteralPath $pythonPath)) { throw "Python executable not found: $pythonPath" }
} else {
    $python = $null
    foreach ($candidate in @("python", "python3", "py")) {
        $python = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($null -ne $python) { break }
    }
    if ($null -eq $python) { throw "Python 3 is required to assemble the audit mission. Install it or pass -PythonExecutable." }
    $pythonPath = $python.Source
    $pythonPrefix = if ($python.Name -in @("py", "py.exe")) { @("-3") } else { @() }
}

if (-not $Run) {
    $dryMission = Join-Path $repoRoot ".qa\Missions\TTT_Localisation_Gameplay_Audit.Altis"
    & $pythonPath @pythonPrefix (Join-Path $qaRoot "build_audit_mission.py") --destination $dryMission --language $Languages[0]
    if ($LASTEXITCODE -ne 0) { throw "Dry-run mission assembly failed." }
    Write-Output "DRY RUN ONLY: assembled and checked the disposable mission at $dryMission"
    Write-Output "Arma 3 was not started. Use -Run to execute the full $($Languages.Count)-language audit."
    exit 0
}

if (Get-Process arma3_x64, arma3server_x64 -ErrorAction SilentlyContinue) {
    throw "An Arma process is already running. Close it before starting this isolated audit."
}
$armaKey = Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\bohemia interactive\arma 3"
$armaRoot = $armaKey.main
$armaExe = Join-Path $armaRoot "arma3_x64.exe"
if (-not (Test-Path -LiteralPath $armaExe)) { throw "Arma 3 executable not found at $armaExe" }
$missionRoot = Join-Path $armaRoot "Missions\TTT_Localisation_Gameplay_Audit.Altis"

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$runRoot = Join-Path ([System.IO.Path]::GetFullPath($OutputDirectory)) "run-$stamp"
[System.IO.Directory]::CreateDirectory($runRoot) | Out-Null
$manifest.languages = @($Languages)
$manifest | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $runRoot "audit_manifest.json") -Encoding utf8

foreach ($language in $Languages) {
    $languageRoot = Join-Path $runRoot $language
    $captureRoot = Join-Path $languageRoot "screenshots"
    $profileRoot = Join-Path $languageRoot "profile"
    [System.IO.Directory]::CreateDirectory($captureRoot) | Out-Null
    [System.IO.Directory]::CreateDirectory($profileRoot) | Out-Null

    & $pythonPath @pythonPrefix (Join-Path $qaRoot "build_audit_mission.py") --destination $missionRoot --language $language
    if ($LASTEXITCODE -ne 0) { throw "Mission assembly failed for $language." }

    # Keep the whole -init value free of spaces and quotes. ProcessStartInfo's
    # raw argument string otherwise lets Windows/Arma split `call compile...`
    # at the first space before the encoded body ever reaches SQF.
    $missionName = "TTT_Localisation_Gameplay_Audit.Altis"
    $missionNameBytes = ($missionName.ToCharArray() | ForEach-Object { [int]$_ }) -join ","
    $arguments = @(
        "-noBattlEye", "-noSplash", "-skipIntro", "-world=empty", "-showScriptErrors", "-filePatching",
        "-window", "-x=$ResolutionWidth", "-y=$ResolutionHeight",
        "-windowWidth=$ResolutionWidth", "-windowHeight=$ResolutionHeight", "-noPause",
        "-language=$language", "-profiles=$profileRoot", "-name=TTT-QA-$language",
        "-init=playMission[toString[],toString[$missionNameBytes]]"
    )
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $armaExe
    $startInfo.UseShellExecute = $false
    $startInfo.Arguments = $arguments -join " "
    $process = [System.Diagnostics.Process]::Start($startInfo)
    Write-Output "[$language] started isolated audit as PID $($process.Id)"

    $captured = @{}
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $rpt = $null
    $uiComplete = $false
    $roundComplete = $false
    try {
        while ((Get-Date) -lt $deadline -and -not $process.HasExited) {
            $rpt = Get-ChildItem $profileRoot -Filter "*.rpt" -Recurse -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($null -ne $rpt) {
                $text = Get-Content -LiteralPath $rpt.FullName -Raw -ErrorAction SilentlyContinue
                $matches = [regex]::Matches($text, "TTT QA CAPTURE READY: ([a-z0-9-]+)")
                foreach ($match in $matches) {
                    $captureId = $match.Groups[1].Value
                    if (-not $captured.ContainsKey($captureId)) {
                        & (Join-Path $qaRoot "capture_arma_window.ps1") -ProcessId $process.Id -OutputPath (Join-Path $captureRoot "$captureId.png")
                        $captured[$captureId] = $true
                        Write-Output "[$language] captured $captureId"
                    }
                }
                $uiComplete = $text.Contains("TTT QA UI COMPLETE:")
                $roundComplete = $text.Contains("TTT QA ROUND COMPLETE:")
                if ($uiComplete -and $roundComplete -and $captured.Count -eq $manifest.captures.Count) { break }
            }
            Start-Sleep -Milliseconds 200
            $process.Refresh()
        }
        if (-not ($uiComplete -and $roundComplete)) { throw "[$language] audit did not reach both completion markers." }
        if ($captured.Count -ne $manifest.captures.Count) { throw "[$language] captured $($captured.Count) of $($manifest.captures.Count) expected surfaces." }
        if ($text.Contains("TTT QA FAIL:")) { throw "[$language] reported a gameplay/localisation QA failure." }
    } finally {
        if (-not $process.HasExited) {
            Stop-Process -Id $process.Id
            $process.WaitForExit(10000) | Out-Null
        }
        if ($null -ne $rpt -and (Test-Path -LiteralPath $rpt.FullName)) {
            Copy-Item -LiteralPath $rpt.FullName -Destination (Join-Path $languageRoot "arma3.rpt") -Force
        }
    }
}

& $pythonPath @pythonPrefix (Join-Path $qaRoot "validate_results.py") --run-root $runRoot
if ($LASTEXITCODE -ne 0) { throw "Audit result validation failed." }
Write-Output "Audit passed. Results: $runRoot"
