import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import { mkdirSync, writeFileSync } from 'node:fs';

const loginUrl = process.env.SF_LOGIN_URL;

function salesforceDate(value) {
  const day = String(value.getDate()).padStart(2, '0');
  const month = value.toLocaleString('en-GB', { month: 'short' });
  return `${day}-${month}-${value.getFullYear()}`;
}

const milestones = [];
function mark(name) {
  milestones.push({ name, at: new Date().toISOString() });
  mkdirSync('test-results', { recursive: true });
  writeFileSync('test-results/e2e-milestones.json', JSON.stringify(milestones, null, 2));
}

test.describe.serial('Smart Appointment browser lifecycle', () => {
  let subject;

  test.beforeAll(async () => {
    if (!loginUrl) throw new Error('SF_LOGIN_URL is required.');
    const suffix = Date.now().toString().slice(-8);
    subject = `E2E lifecycle ${suffix}`;
  });

  test.beforeEach(async ({ page }) => {
    await page.goto(loginUrl);
    await expect(page.getByText('LadminAI', { exact: true }).first()).toBeVisible();
  });

  test('books, reschedules, changes status, cancels, and drills into reports', async ({ page }) => {
    mark('authenticated');
    await page.getByRole('button', { name: 'Appointment Booking', exact: true }).click();
    mark('booking-opened');
    await expect(page.locator('[data-testid="booking-lead"]')).toHaveCount(0);
    mark('lead-deep-link-selected');
    await expect(page.locator('[data-testid="booking-location"] button[role="combobox"]')).not.toContainText('Select an Option');
    await expect(page.locator('[data-testid="booking-resource"] button[role="combobox"]')).not.toContainText('Select an Option');
    mark('single-location-resource-selected');
    const date = new Date(); date.setDate(date.getDate() + 2);
    await page.locator('[data-testid="booking-date"] input').fill(salesforceDate(date));
    mark('booking-date-filled');
    await page.locator('[data-testid="booking-subject"] input').fill(subject);
    mark('booking-subject-filled');
    const bookingDebug = {
      check: await page.locator('[data-testid="check-availability"]').locator('button').evaluate((button) => ({ disabled: button.disabled, text: button.textContent?.trim() })),
      location: await page.locator('[data-testid="booking-location"] button[role="combobox"]').textContent(),
      resource: await page.locator('[data-testid="booking-resource"] button[role="combobox"]').textContent()
    };
    writeFileSync('test-results/booking-state.json', JSON.stringify(bookingDebug, null, 2));
    await page.locator('[data-testid="check-availability"] button').click();
    mark('availability-requested');
    await expect(page.locator('[data-testid="check-availability"] button')).toBeEnabled();
    await page.locator('[data-testid="booking-slot"] button[role="combobox"]').click();
    await page.getByRole('option').first().click();
    await expect(page.locator('[data-testid="booking-slot"] button[role="combobox"]')).not.toContainText('Select an Option');
    mark('slot-selected');
    await page.locator('[data-testid="book-appointment"] button').click();
    await expect(page.getByText(/was booked successfully/)).toBeVisible();
    mark('booking-passed');

    await page.getByRole('button', { name: 'Appointment Schedule', exact: true }).click();
    const row = page.locator('[data-testid="schedule-row"]').filter({ hasText: subject });
    await expect(row).toBeVisible();
    await row.getByTitle('Reschedule').click();
    const rescheduleDate = new Date(date); rescheduleDate.setDate(date.getDate() + 1);
    const rescheduleDateInput = page.locator('[data-testid="reschedule-date"] input');
    await expect(rescheduleDateInput).toBeEnabled();
    await rescheduleDateInput.fill(salesforceDate(rescheduleDate));
    await rescheduleDateInput.press('Tab');
    await expect.poll(() => page.locator('c-ladmin-ai-appointment-calendar').evaluate((component) => component.hasRescheduleSlots())).toBe(true);
    await page.locator('[data-testid="reschedule-slot"] button[role="combobox"]').click();
    await page.getByRole('option').first().click();
    await expect(page.locator('[data-testid="reschedule-slot"] button[role="combobox"]')).not.toContainText('Select an available time');
    await page.locator('[data-testid="dialog-save"] button').click();
    await expect(page.getByRole('heading', { name: 'Reschedule Appointment' })).toBeHidden();
    mark('reschedule-passed');

    const refreshedRow = page.locator('[data-testid="schedule-row"]').filter({ hasText: subject });
    await refreshedRow.getByRole('button', { name: 'More appointment actions' }).click();
    await page.getByRole('menuitem', { name: 'Update status' }).click();
    await page.locator('[data-testid="status-choice"] button[role="combobox"]').click();
    await page.getByRole('option', { name: 'Confirmed' }).click();
    await page.locator('[data-testid="dialog-save"] button').click();
    await expect(refreshedRow).toContainText('Confirmed');
    mark('status-change-passed');

    await refreshedRow.getByRole('button', { name: 'More appointment actions' }).click();
    await page.getByRole('menuitem', { name: 'Cancel appointment' }).click();
    await page.locator('[data-testid="cancel-reason"] textarea').fill('Automated lifecycle validation');
    await page.locator('[data-testid="dialog-save"] button').click();
    await expect(refreshedRow).toContainText('Cancelled');
    mark('cancellation-passed');

    await page.getByRole('button', { name: 'Reports & Dashboard', exact: true }).click();
    await page.getByRole('button', { name: /Appointments this month/ }).click();
    await expect(page.getByRole('heading', { name: /Appointments this month/ })).toBeVisible();
    await expect(page.locator('.details tbody tr').first()).toBeVisible();
    mark('report-drilldown-passed');
    for (const pageName of ['Home', 'Appointment Booking', 'Appointment Schedule', 'Reports & Dashboard']) {
      await page.getByRole('button', { name: pageName, exact: true }).click();
      await expect(page.locator('c-ladmin-ai-appointment-home main')).toBeVisible();
      const results = await new AxeBuilder({ page })
        .include('c-ladmin-ai-appointment-home')
        .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
        .analyze();
      const blocking = results.violations.filter((violation) => ['serious', 'critical'].includes(violation.impact));
      expect(blocking, `${pageName} accessibility violations:\n${JSON.stringify(blocking, null, 2)}`).toEqual([]);
    }
    mark('accessibility-passed');
  });
});
