import { test, expect } from '@playwright/test';

test.describe('Login page', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:9292/login');
  });

  test('renders login form', async ({ page }) => {
    await expect(page.getByRole('heading', { name: 'Login' })).toBeVisible();

    await expect(page.getByLabel('Email')).toBeVisible();
    await expect(page.getByLabel('Password')).toBeVisible();

    await expect(page.getByRole('button', { name: 'Login' })).toBeVisible();
  });

  test('shows validation when fields are empty', async ({ page }) => {
    await page.getByRole('button', { name: 'Login' }).click();

    const emailInput = page.locator('input[name="email"]');
    await expect(emailInput).toHaveAttribute('required', '');
  });

  test('can fill and submit login form', async ({ page }) => {
    await page.getByLabel('Email').fill('test@example.com');
    await page.getByLabel('Password').fill('password123');

    await page.getByRole('button', { name: 'Login' }).click();

    await expect(page).toHaveURL(/products/);
  });

  test('shows error on invalid credentials', async ({ page }) => {
    await page.getByLabel('Email').fill('wrong@example.com');
    await page.getByLabel('Password').fill('wrongpassword');

    await page.getByRole('button', { name: 'Login' }).click();

    await expect(page.locator('text=Invalid credentials')).toBeVisible();
  });
});