# Lightweight Verification Harness

`verify_local.ps1` checks the canonical migration inventory and unique 14-digit versions.

`scan_credentials.ps1` scans client source while excluding server-only Edge Functions.

`music_catalog.sql` contains SELECT-only schema and policy inspection. Execute it only through the approved linked read-only Supabase path; it is not a test-data generator.

Expected labels are PASS, FAIL, or UNPROVEN. A query error is not automatically a security pass.
