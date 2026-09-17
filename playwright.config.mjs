import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  timeout: 60_000,
  expect: { timeout: 20_000 },
  fullyParallel: false,
  workers: 1,
  reporter: [['list'], ['json', { outputFile: 'test-results/results.json' }], ['html', { outputFolder: 'test-results/html', open: 'never' }]],
  use: {
    browserName: 'chromium',
    headless: process.env.E2E_HEADED !== 'true',
    trace: 'off',
    screenshot: 'only-on-failure',
    video: 'off'
  },
  outputDir: 'test-results/artifacts'
});
