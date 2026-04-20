Param(
    [string]$MasterFile = "e:\root\php\vietnamcity\data\raw_xls\DanhsachTinhThanhpho.xls",
    [string]$CityDir = "e:\root\php\vietnamcity\data\city"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $MasterFile)) {
    throw "Master file not found: $MasterFile"
}

if (-not (Test-Path $CityDir)) {
    throw "City directory not found: $CityDir"
}

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

$codeToName = @{}

function Convert-ToNormalizedCityCode {
    param([string]$digits)

    $clean = ("" + $digits).Trim() -replace "[^0-9]", ""
    if ([string]::IsNullOrWhiteSpace($clean)) {
        return ""
    }

    if ($clean.Length -eq 3 -and $clean.StartsWith("0")) {
        $clean = $clean.Substring(1)
    }

    if ($clean.Length -eq 1) {
        return $clean.PadLeft(2, '0')
    }

    return $clean
}

try {
    $wb = $excel.Workbooks.Open($MasterFile)
    $ws = $wb.Worksheets.Item(1)

    $r = 2
    while ($true) {
        $codeRaw = ("" + $ws.Cells.Item($r, 1).Text).Trim()
        $name = ("" + $ws.Cells.Item($r, 2).Text).Trim()

        if ([string]::IsNullOrWhiteSpace($codeRaw) -and [string]::IsNullOrWhiteSpace($name)) {
            break
        }

        $digits = ($codeRaw -replace "[^0-9]", "")
        if (-not [string]::IsNullOrWhiteSpace($digits) -and -not [string]::IsNullOrWhiteSpace($name)) {
            $code = Convert-ToNormalizedCityCode $digits
            $codeToName[$code] = $name
        }

        $r++
    }

    $wb.Close($false)
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($ws) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($wb) | Out-Null
}
finally {
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}

$updated = 0
$skipped = 0

Get-ChildItem -Path $CityDir -Filter "*.json" -File | ForEach-Object {
    $path = $_.FullName
    $raw = Get-Content -Path $path -Raw -Encoding UTF8

    $codeMatch = [regex]::Match($raw, '"city_code"\s*:\s*"([0-9]+)"')
    if (-not $codeMatch.Success) {
        Write-Output ("SKIP_NO_CODE`t{0}" -f $_.Name)
        $skipped++
        return
    }

    $code = Convert-ToNormalizedCityCode $codeMatch.Groups[1].Value
    if (-not $codeToName.ContainsKey($code)) {
        Write-Output ("SKIP_NO_MASTER`t{0}`t{1}" -f $_.Name, $code)
        $skipped++
        return
    }

    $newName = $codeToName[$code]
    $newRaw = [regex]::Replace($raw, '"city_name"\s*:\s*"[^"]*"', ('"city_name":  "{0}"' -f $newName), 1)

    if ($newRaw -ne $raw) {
        Set-Content -Path $path -Value $newRaw -Encoding UTF8
        Write-Output ("UPDATED`t{0}`t{1}`t{2}" -f $_.Name, $code, $newName)
        $updated++
    }
    else {
        Write-Output ("UNCHANGED`t{0}`t{1}`t{2}" -f $_.Name, $code, $newName)
    }
}

Write-Output ("SUMMARY_UPDATED`t{0}" -f $updated)
Write-Output ("SUMMARY_SKIPPED`t{0}" -f $skipped)
