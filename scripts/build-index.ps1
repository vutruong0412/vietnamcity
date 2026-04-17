Param(
    [string]$RootPath = "."
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path $RootPath
$cityDir = Join-Path $repoRoot "data/city"
$indexPath = Join-Path $repoRoot "index.json"

if (-not (Test-Path $cityDir)) {
    throw "City directory not found: $cityDir"
}

$cityFiles = Get-ChildItem -Path $cityDir -Filter "*.json" -File | Sort-Object Name

$cities = @()
foreach ($file in $cityFiles) {
    $raw = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $obj = $raw | ConvertFrom-Json

    if ([string]::IsNullOrWhiteSpace($obj.city_code)) {
        throw "Missing city_code in $($file.Name)"
    }
    if ([string]::IsNullOrWhiteSpace($obj.city_name)) {
        throw "Missing city_name in $($file.Name)"
    }
    if ($null -eq $obj.admin_units) {
        throw "Missing admin_units in $($file.Name)"
    }

    $cities += [ordered]@{
        city_code = [string]$obj.city_code
        city_name = [string]$obj.city_name
        file = "/data/city/$($file.Name)"
        admin_units_count = @($obj.admin_units).Count
    }
}

$indexObj = [ordered]@{
    version = 1
    country_code = "VN"
    total_cities = $cities.Count
    cities = $cities
}

$json = $indexObj | ConvertTo-Json -Depth 8
Set-Content -Path $indexPath -Value $json -Encoding UTF8

Write-Output "INDEX_GENERATED: $indexPath"
Write-Output "TOTAL_CITIES: $($cities.Count)"
