const { Client } = require('pg');

const projectRef = 'pwxhgvuyaxgavommtqpr';
const password = 'Tzt0bkistz7Hi2af';
const user = `postgres.${projectRef}`;

const regions = [
  'aws-0-ap-southeast-1', // Singapore
  'aws-0-ap-northeast-1', // Tokyo
  'aws-0-ap-northeast-2', // Seoul
  'aws-0-ap-south-1',     // Mumbai
  'aws-0-us-west-1',      // US West
  'aws-0-us-east-1',      // US East
  'aws-0-eu-central-1',   // Frankfurt
  'aws-0-eu-west-1',      // Ireland
  'aws-0-eu-west-2',      // London
  'aws-0-sa-east-1',      // Sao Paulo
];

async function checkRegion(region) {
  const host = `${region}.pooler.supabase.com`;
  console.log(`Checking ${region} (${host})...`);

  const client = new Client({
    user: user,
    password: password,
    host: host,
    port: 6543,
    database: 'postgres',
    ssl: { rejectUnauthorized: false },
    connectionTimeoutMillis: 5000,
  });

  try {
    await client.connect();
    console.log(`✅ SUCCESS! Connected to ${region}`);
    await client.end();
    return region;
  } catch (err) {
    if (err.message.includes('Tenant or user not found')) {
      console.log(`❌ ${region}: Tenant not found`);
    } else if (err.code === 'ENOTFOUND') {
      console.log(`❌ ${region}: Host not found (DNS)`);
    } else {
      console.log(`❌ ${region}: ${err.message}`);
    }
  }
}

(async () => {
  for (const region of regions) {
    const success = await checkRegion(region);
    if (success) {
      console.log(`\n🎉 FOUND IT! The correct hostname is: ${success}.pooler.supabase.com`);
      process.exit(0);
    }
  }
  console.log('\n❌ Could not connect to any region.');
  process.exit(1);
})();
