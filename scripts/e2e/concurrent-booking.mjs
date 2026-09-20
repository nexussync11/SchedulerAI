import { spawn } from 'node:child_process';

const org = process.env.SF_TARGET_ORG || 'ladminai-fresh-20260917';
if (org !== 'ladminai-fresh-20260917') throw new Error('Concurrency harness is restricted to the authorized non-Harley scratch org.');

function runApex(file) {
  return new Promise((resolve, reject) => {
    const process = spawn('sf', ['apex', 'run', '--target-org', org, '--file', file], { shell: true, windowsHide: true });
    let output = '';
    process.stdout.on('data', (chunk) => { output += chunk; });
    process.stderr.on('data', (chunk) => { output += chunk; });
    process.on('error', reject);
    process.on('close', (code) => code === 0 ? resolve(output) : reject(new Error(output)));
  });
}

await runApex('scripts/e2e/reset-concurrent-booking.apex');
const outcomes = await Promise.all([
  runApex('scripts/e2e/concurrent-booking.apex'),
  runApex('scripts/e2e/concurrent-booking.apex')
]);
const results = outcomes.map((output) => output.match(/CONCURRENCY_RESULT=(true|false):([^\r\n]*)/)?.slice(1));
if (results.some((result) => !result)) throw new Error(`Missing booking outcome: ${JSON.stringify(outcomes)}`);
const successes = results.filter((result) => result[0] === 'true').length;
const conflicts = results.filter((result) => result[1].includes('SLOT_CONFLICT')).length;
console.log(JSON.stringify({ successes, conflicts, results }));
if (successes !== 1 || conflicts !== 1) process.exitCode = 1;
