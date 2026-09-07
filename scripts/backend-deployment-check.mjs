import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const migrationDir = path.join(root, 'supabase', 'migrations');
const requiredFunctions = ['register-device','send-push','submit-visitor','sync-youtube-sermons','sync-podcast-sermons'];
let failures = 0;

if (!fs.existsSync(migrationDir)) {
  console.error('FAIL missing migration directory: supabase/migrations');
  failures++;
} else {
  const migrations = fs.readdirSync(migrationDir).filter((file) => file.endsWith('.sql')).sort();
  if (!migrations.length) {
    console.error('FAIL no canonical SQL migrations found');
    failures++;
  } else {
    console.log(`PASS migrations directory: ${migrations.length} local SQL migrations`);
    for (const file of migrations) console.log(`PASS migration: supabase/migrations/${file}`);
  }
}

for (const fn of requiredFunctions) {
  const file = `supabase/functions/${fn}/index.ts`;
  if (!fs.existsSync(path.join(root, file))) {
    console.error(`FAIL missing Edge Function: ${file}`);
    failures++;
  } else {
    console.log(`PASS Edge Function: ${file}`);
  }
}

for (const file of ['supabase/config.toml','supabase/DEPLOYMENT_ORDER.md','.env.example','package.json','app.json','eas.json']) {
  if (!fs.existsSync(path.join(root, file))) {
    console.error(`FAIL missing release/backend file: ${file}`);
    failures++;
  } else {
    console.log(`PASS release/backend file: ${file}`);
  }
}

if (fs.existsSync(path.join(root, 'supabase/config.toml'))) {
  const config = fs.readFileSync(path.join(root, 'supabase/config.toml'), 'utf8');
  for (const fn of requiredFunctions) {
    if (!config.includes(`[functions.${fn}]`)) {
      console.error(`FAIL config missing [functions.${fn}]`);
      failures++;
    }
  }
}

if (failures) process.exit(1);
console.log('\nPASS backend repository structure is internally consistent.');
console.log('NOTE: this gate does not prove production migration parity or live deployment.');
