# VietnamCity Workspace Notes

## Scope
- Project path: e:/root/php/vietnamcity
- Purpose: manage city/ward index dataset for VN administrative units.

## Data Structure
- City files: data/city/<city_code>.json
- Global index: index.json
- Build script: scripts/build-index.ps1
- XLS import script: scripts/import-xls.ps1
- Name normalization script: scripts/normalize-city-names-from-master.ps1
- Raw XLS input folder: data/raw_xls/

## Session Update 2026-04-20
- Imported multiple province datasets from XLS files in data/raw_xls.
- Synced province/city names with master file: data/raw_xls/DanhsachTinhThanhpho.xls.
- Normalized city_name format in index and city JSON files:
  - Provinces: "Tỉnh ..."
  - Centrally governed cities: "Thành phố ..."
- Migrated old city codes to latest codes from master list:
  - 10 -> 15 (Lào Cai)
  - 45 -> 44 (Quảng Trị)
  - 64 -> 52 (Gia Lai)
  - 72 -> 80 (Tây Ninh)
  - 87 -> 82 (Đồng Tháp)
  - 89 -> 91 (An Giang)
- Reordered index.json city list per custom rule:
  - Priority first: 001 (Hà Nội), 079 (Hồ Chí Minh), 048 (Đà Nẵng), 092 (Cần Thơ), 031 (Hải Phòng), 046 (Huế)
  - Remaining entries sorted by city_code ascending.
- Current index summary:
  - total_cities: 34

## Build Command
- PowerShell:
  - ./scripts/build-index.ps1 -RootPath .

## Import + Normalize Commands
- Import city data from all XLS files in data/raw_xls:
  - ./scripts/import-xls.ps1
- Normalize city names from master province list (code + Vietnamese diacritics):
  - ./scripts/normalize-city-names-from-master.ps1
- Recommended sequence after adding new XLS files:
  - ./scripts/import-xls.ps1
  - ./scripts/normalize-city-names-from-master.ps1
  - ./scripts/build-index.ps1 -RootPath .

## Troubleshooting
- Encoding issues (garbled Vietnamese text in PowerShell):
  - Prefer running prepared scripts instead of very long inline commands.
  - If output still looks broken in terminal, verify resulting JSON file content directly.
  - Re-run normalization script after imports:
    - ./scripts/normalize-city-names-from-master.ps1
- Execution policy blocks script run (PSSecurityException / UnauthorizedAccess):
  - Use process-scope bypass for current shell only:
    - Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
- Missing code mapping during import (SKIP_NO_MAPPING or SKIP_NO_MASTER):
  - Ensure file name key exists in scripts/import-xls.ps1 mapping table.
  - Ensure code/name exists in data/raw_xls/DanhsachTinhThanhpho.xls for normalization.
  - If province code changed in master list, migrate city_code/file name, then rebuild index.

## Verification Checklist
- index.json total_cities matches number of files in data/city.
- Priority city order in index.json is correct (001, 079, 048, 092, 031, 046).
- Priority city order in index.json is correct (01, 79, 48, 92, 31, 46).
- Remaining city entries are sorted by city_code ascending.
- city_name values are synced from DanhsachTinhThanhpho.xls.
- Latest migrated code files exist:
  - data/city/15.json
  - data/city/44.json
  - data/city/52.json
  - data/city/80.json
  - data/city/82.json
  - data/city/91.json
