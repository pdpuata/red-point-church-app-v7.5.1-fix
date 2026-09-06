$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $root
$hits = @(Get-ChildItem . -Recurse -File -Include '*.ts','*.tsx','*.js','*.jsx' | Where-Object { $_.FullName -notmatch 'node_modules|supabase[\\/]functions' } | Select-String -Pattern 'service_role|SUPABASE_SERVICE_ROLE|SERVICE_ROLE_KEY' -CaseSensitive:$false)
if ($hits.Count) { $hits | ForEach-Object { Write-Output $_.Path; Write-Output $_.Line }; throw 'Client credential match found.' }
Write-Output 'PASS: no service-role credential matches in client files.'
