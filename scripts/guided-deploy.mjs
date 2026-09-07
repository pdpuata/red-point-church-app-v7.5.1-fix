import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const checkOnly = process.argv.includes('--check');
const pkg = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
const migrationDir = path.join(root, 'supabase', 'migrations');
const migrations = [
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
const checks = [
  ['Node project', 'package.json'],
  ['Expo app config', 'app.json'],
  ['Mobile environment template', '.env.example'],
  ['Server environment template', '.supabase.production.env.example'],
  ['Supabase config', 'supabase/config.toml'],
  ['Deployment order', 'supabase/DEPLOYMENT_ORDER.md'],
  ['Production setup guide', 'supabase/PRODUCTION_SETUP.md'],
  ['Visitor function', 'supabase/functions/submit-visitor/index.ts'],
  ['Device registration function', 'supabase/functions/register-device/index.ts'],
  ['Push function', 'supabase/functions/send-push/index.ts'],
  ['YouTube sync function', 'supabase/functions/sync-youtube-sermons/index.ts'],
  ['Podcast RSS sync function', 'supabase/functions/sync-podcast-sermons/index.ts'],
];
let failures = 0;
console.log(`\nRed Point Church — Guided Production Deployment v${pkg.version}`);
console.log('This tool never prints secret values. It does not deploy automatically.');
console.log('\nSTEP 0 — Project integrity');
for (const [label, rel] of checks) {
  const ok = fs.existsSync(path.join(root, rel));
  console.log(`${ok ? 'PASS' : 'FAIL'} ${label}: ${rel}`);
  if (!ok) failures++;
}
for (const migration of migrations) {
  const ok = fs.existsSync(path.join(migrationDir, migration));
  console.log(`${ok ? 'PASS' : 'FAIL'} Migration: ${migration}`);
  if (!ok) failures++;
}
if (failures) process.exit(1);
console.log('\nSTEP 1 — Prepare local configuration');
console.log('COMPUTER: copy .env.example to .env and enter only mobile/public values.');
console.log('COMPUTER: copy .supabase.production.env.example to .supabase.production.env and enter server-only values.');
console.log('Never put SUPABASE_SERVICE_ROLE_KEY, RESEND_API_KEY, or YOUTUBE_API_KEY in Expo .env.');
console.log('\nSTEP 2 — Authenticate and link Supabase');
console.log('COMPUTER: npx supabase login');
console.log('COMPUTER: npx supabase link --project-ref YOUR_PROJECT_REF');
console.log('\nSTEP 3 — Verify migration state before deploy');
console.log('COMPUTER: npx supabase migration list');
console.log('COMPUTER: npx supabase db push --dry-run');
console.log('STOP if the remote ledger contains migrations absent locally. Do not use --include-all, reset, pull, or overwrite history.');
console.log('\nSTEP 4 — Deploy database only after the dry-run is clean');
console.log('COMPUTER: npx supabase db push');
console.log('\nSTEP 5 — Deploy Edge Functions');
for (const fn of ['submit-visitor','register-device','send-push','sync-youtube-sermons','sync-podcast-sermons']) {
  console.log(`COMPUTER: npx supabase functions deploy ${fn}`);
}
console.log('\nSTEP 6 — Configure server secrets');
console.log('COMPUTER: set VISITOR_EMAIL_TO, RESEND_API_KEY, RESEND_FROM_EMAIL, and YOUTUBE_API_KEY in Supabase secrets.');
console.log('Never paste secret values into chat or commit them to Git.');
console.log('\nSTEP 7 — Bootstrap admin');
console.log('COMPUTER: create the staff user in Supabase Authentication, then insert its UUID into public.admin_users.');
console.log('\nSTEP 8 — Verify live backend');
console.log('COMPUTER: npm run check:live');
console.log('\nSTEP 9 — Verify mobile configuration');
console.log('COMPUTER: npm run check:production-config');
console.log('\nSTEP 10 — Run local release checks');
console.log('COMPUTER: npm run preflight');
console.log('COMPUTER: npm run release-check');
console.log('COMPUTER: npm run typecheck');
console.log('COMPUTER: npx expo-doctor');
console.log('\nSTEP 11 — Build preview');
console.log('COMPUTER: npm run build:android:preview');
console.log('\nSTEP 12 — PHONE: install and test Home, Events, Sermons, visitor form, notifications, admin, Music, and airplane-mode recovery.');
console.log('\nGUIDED DEPLOYMENT GATE: repository files are consistent. Live deployment and device testing remain required.');
if (checkOnly) console.log('CHECK MODE: no deployment commands were executed.');
