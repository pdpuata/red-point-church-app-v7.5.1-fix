$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $root
$expected = @(
  '20260903000001_red_point_baseline.sql',
  '20260903000002_admin_rls_fix.sql',
  '20260904000001_production_backend.sql',
  '20260904000002_sermon_audio_source.sql',
  '20260904000003_table_grants.sql',
  '20260905000001_event_time_integrity.sql',
  '20260905000002_visitor_rate_limit.sql',
  '20260905000003_music_foundation.sql',
  '20260905000004_music_operating_layers.sql',
  '20260905000005_music_operational_audit.sql',
  '20260905000006_music_band_and_device_ownership.sql',
  '20260905000007_music_band_leader_integrity.sql'
)
$actual = @(Get-ChildItem supabase/migrations -File -Filter '*.sql' | Select-Object -ExpandProperty Name | Sort-Object)
if (($actual -join "`n") -ne (($expected | Sort-Object) -join "`n")) { throw 'Migration inventory mismatch.' }
$bad = @($actual | Where-Object { $_ -notmatch '^\d{14}_[^/]+\.sql$' })
if ($bad.Count) { throw ('Invalid migration filename: ' + ($bad -join ', ')) }
$duplicateVersions = @($actual | ForEach-Object { $_.Substring(0, 14) } | Group-Object | Where-Object Count -gt 1)
if ($duplicateVersions.Count) { throw 'Duplicate migration versions found.' }
Write-Output 'PASS: canonical migration inventory and versions.'
