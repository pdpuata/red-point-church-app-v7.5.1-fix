import fs from 'node:fs';
import path from 'node:path';
const root = process.cwd();
const required = [
  'supabase/config.toml',
  'supabase/DEPLOYMENT_ORDER.md',
  'supabase/functions/register-device/index.ts',
  'supabase/functions/submit-visitor/index.ts',
  'supabase/functions/send-push/index.ts',
  'supabase/functions/sync-youtube-sermons/index.ts',
  'supabase/functions/sync-podcast-sermons/index.ts',
  'supabase/functions/_shared/cors.ts',
  'supabase/functions/_shared/supabase.ts',
];
const requiredMigrations = [
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
  '20260905000007_music_band_leader_integrity.sql',
];
let failures=0;
for (const file of required) {
  if (fs.existsSync(path.join(root,file))) console.log(`PASS ${file}`);
  else { console.error(`FAIL ${file}`); failures++; }
}
const migrationDir=path.join(root,'supabase/migrations');
const migrations=fs.existsSync(migrationDir) ? fs.readdirSync(migrationDir).filter(f=>f.endsWith('.sql')) : [];
for (const file of requiredMigrations) {
  if (migrations.includes(file)) console.log(`PASS migration ${file}`);
  else { console.error(`FAIL migration ${file}`); failures++; }
}
const config=fs.readFileSync(path.join(root,'supabase/config.toml'),'utf8');
for (const fn of ['register-device','submit-visitor','send-push','sync-youtube-sermons','sync-podcast-sermons']) {
  if (!config.includes(`[functions.${fn}]`)) { console.error(`FAIL config missing ${fn}`); failures++; }
  else console.log(`PASS config ${fn}`);
}
if (failures) process.exit(1);
console.log('\nBackend launch gate passed. Credentials and live deployment are intentionally not tested here.');
