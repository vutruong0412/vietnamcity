Param(
    [string]$RawDir = "e:\root\php\vietnamcity\data\raw_xls",
    [string]$OutDir = "e:\root\php\vietnamcity\data\city"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$map = [ordered]@{
    "DongNai"    = @{ code = "75"; name = "Dong Nai" }
    "DongThap"   = @{ code = "82"; name = "Dong Thap" }
    "GiaLai"     = @{ code = "52"; name = "Gia Lai" }
    "HaiPhong"   = @{ code = "31"; name = "Hai Phong" }
    "HaTinh"     = @{ code = "42"; name = "Ha Tinh" }
    "HungYen"    = @{ code = "33"; name = "Hung Yen" }
    "KhanhHoa"   = @{ code = "56"; name = "Khanh Hoa" }
    "LaiChau"    = @{ code = "12"; name = "Lai Chau" }
    "LamDong"    = @{ code = "68"; name = "Lam Dong" }
    "LangSon"    = @{ code = "20"; name = "Lang Son" }
    "LaoCai"     = @{ code = "15"; name = "Lao Cai" }
    "NgheAn"     = @{ code = "40"; name = "Nghe An" }
    "NinhBinh"   = @{ code = "37"; name = "Ninh Binh" }
    "PhuTho"     = @{ code = "25"; name = "Phu Tho" }
    "QuangNgai"  = @{ code = "51"; name = "Quang Ngai" }
    "QuangNinh"  = @{ code = "22"; name = "Quang Ninh" }
    "QuangTri"   = @{ code = "44"; name = "Quang Tri" }
    "SonLa"      = @{ code = "14"; name = "Sơn La" }
    "TayNinh"    = @{ code = "80"; name = "Tay Ninh" }
    "ThanhHoa"   = @{ code = "38"; name = "Thanh Hoa" }
    "TPHue"      = @{ code = "46"; name = "Hue" }
    "TuyenQuang" = @{ code = "08"; name = "Tuyen Quang" }
    "VinhLong"   = @{ code = "86"; name = "Vinh Long" }
}

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
$created = @()

try {
    Get-ChildItem -Path $RawDir -Filter "*.xls" -File | Sort-Object Name | ForEach-Object {
        $base = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        if (-not $map.Contains($base)) {
            Write-Output "SKIP_NO_MAPPING`t$base"
            return
        }

        $meta = $map[$base]
        $wb = $excel.Workbooks.Open($_.FullName)
        $ws = $wb.Worksheets.Item(1)

        $rows = @()
        $r = 2

        while ($true) {
            $name = ("" + $ws.Cells.Item($r, 1).Text).Trim()
            $code = ("" + $ws.Cells.Item($r, 2).Text).Trim()
            $level = ("" + $ws.Cells.Item($r, 3).Text).Trim()

            if ([string]::IsNullOrWhiteSpace($name) -and [string]::IsNullOrWhiteSpace($code) -and [string]::IsNullOrWhiteSpace($level)) {
                break
            }

            if (-not [string]::IsNullOrWhiteSpace($name) -and -not [string]::IsNullOrWhiteSpace($code) -and -not [string]::IsNullOrWhiteSpace($level)) {
                $code = ($code -replace "[^0-9]", "")
                $rows += [ordered]@{
                    name  = $name
                    code  = $code
                    level = $level
                }
            }

            $r++
        }

        $obj = [ordered]@{
            city_code    = $meta.code
            city_name    = $meta.name
            country_code = "VN"
            admin_units  = $rows
        }

        $json = $obj | ConvertTo-Json -Depth 8
        $outPath = Join-Path $OutDir ("{0}.json" -f $meta.code)
        Set-Content -Path $outPath -Value $json -Encoding UTF8
        $created += $outPath

        $wb.Close($false)
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($ws) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($wb) | Out-Null

        Write-Output ("CREATED`t{0}`t{1}`t{2}" -f $meta.code, $meta.name, $rows.Count)
    }
}
finally {
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}

Write-Output ("TOTAL_CREATED`t{0}" -f $created.Count)
