import { test, expect } from '@playwright/test';

const loginUrl = process.env.SF_LOGIN_URL;

function dateValue(daysFromToday) {
  const value = new Date();
  value.setDate(value.getDate() + daysFromToday);
  return value.toISOString().slice(0, 10);
}

test('enables a multi-day special-date override for the sole active resource', async ({ page }) => {
  if (!loginUrl) throw new Error('SF_LOGIN_URL is required.');
  await page.goto(loginUrl);
  await expect(page.getByText('LadminAI', { exact: true }).first()).toBeVisible({ timeout: 30000 });
  await page.getByRole('button', { name: 'Resource Availability', exact: true }).click();

  await expect(page.getByText('No doctor selected', { exact: true })).toHaveCount(0);
  await page.getByLabel('Start date', { exact: true }).fill(dateValue(10));
  await page.getByLabel('End date (optional)', { exact: true }).fill(dateValue(12));

  await expect(page.getByRole('button', { name: 'Save Special Date(s)' })).toBeEnabled();
  await expect(page.locator('.slds-datepicker')).toHaveCount(0);
});
