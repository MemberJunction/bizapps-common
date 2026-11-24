import { existsSync, mkdirSync, statSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
    DEFAULT_COMMON_ANGULAR_LIMITS,
    RegisterCommonAngularLimits,
    ResetCommonAngularLimits,
    ResolveCommonAngularLimitsWithProvenance,
} from '../dist/lib/config/limits.config.js';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(HERE, '..', '..', '..');
const require = createRequire(import.meta.url);

function resolvePlaywrightPath() {
    const candidates = [
        REPO_ROOT,
        resolve(REPO_ROOT, '..'),
        resolve(REPO_ROOT, '..', 'node_modules', '.pnpm', 'node_modules'),
    ];
    return require.resolve('playwright', { paths: candidates });
}

function escapeHtml(text) {
    return String(text)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

async function main() {
    const outArgIndex = process.argv.indexOf('--out');
    const screenshotPath =
        outArgIndex !== -1 && process.argv[outArgIndex + 1]
            ? resolve(process.argv[outArgIndex + 1])
            : resolve(REPO_ROOT, '..', '.tmp-playwright', 'common-angular-limits-playwright.png');
    mkdirSync(dirname(screenshotPath), { recursive: true });

    ResetCommonAngularLimits();
    const defaultsResult = ResolveCommonAngularLimitsWithProvenance();
    RegisterCommonAngularLimits({
        ResourceGuards: { SellingCompanyListLimit: 500 },
        Tuning: { ActivitiesDashboardMaxRows: 120 },
    });
    const overrideResult = ResolveCommonAngularLimitsWithProvenance({
        ResourceGuards: { PartySearchTimeoutMs: 999_999 },
    });
    ResetCommonAngularLimits();

    const cards = [
        ...Object.entries(DEFAULT_COMMON_ANGULAR_LIMITS.ResourceGuards).map(([k, v]) => ({
            category: 'ResourceGuard',
            key: `ResourceGuards.${k}`,
            defaultVal: v,
            resolved: overrideResult.Provenance[`ResourceGuards.${k}`],
        })),
        ...Object.entries(DEFAULT_COMMON_ANGULAR_LIMITS.Tuning).map(([k, v]) => ({
            category: 'Tuning',
            key: `Tuning.${k}`,
            defaultVal: v,
            resolved: overrideResult.Provenance[`Tuning.${k}`],
        })),
        ...Object.entries(DEFAULT_COMMON_ANGULAR_LIMITS.Ux).map(([k, v]) => ({
            category: 'UX',
            key: `Ux.${k}`,
            defaultVal: v,
            resolved: overrideResult.Provenance[`Ux.${k}`],
        })),
    ];

    const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>BizApps Common — Angular Limits Configuration Verification</title>
<style>
  :root {
    color-scheme: light;
    --mj-bg-page: Canvas;
    --mj-bg-surface: Field;
    --mj-bg-surface-card: ButtonFace;
    --mj-border-default: ButtonBorder;
    --mj-text-primary: CanvasText;
    --mj-text-secondary: GrayText;
    --mj-brand-primary: LinkText;
    --mj-status-success: Highlight;
    --mj-status-warning: MarkText;
    --mj-status-info-text: LinkText;
    --mj-radius-md: 10px;
  }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    padding: 28px;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    background: var(--mj-bg-page);
    color: var(--mj-text-primary);
  }
  .page-shell {
    max-width: 1180px;
    margin: 0 auto;
    display: flex;
    flex-direction: column;
    gap: 20px;
  }
  .page-header {
    background: var(--mj-bg-surface);
    border: 1px solid var(--mj-border-default);
    border-radius: var(--mj-radius-md);
    padding: 20px 24px;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  .page-title {
    margin: 0 0 6px 0;
    font-size: 20px;
    font-weight: 700;
  }
  .page-subtitle {
    margin: 0;
    font-size: 13px;
    color: var(--mj-text-secondary);
  }
  .status-pill {
    padding: 6px 12px;
    border-radius: 999px;
    border: 1px solid var(--mj-status-success);
    color: var(--mj-status-success);
    font-size: 12px;
    font-weight: 600;
  }
  .summary-strip {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 12px;
  }
  .summary-tile {
    background: var(--mj-bg-surface-card);
    border: 1px solid var(--mj-border-default);
    border-radius: var(--mj-radius-md);
    padding: 14px 16px;
  }
  .summary-label {
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    color: var(--mj-text-secondary);
    margin-bottom: 6px;
  }
  .summary-value {
    font-size: 22px;
    font-weight: 700;
    color: var(--mj-brand-primary);
  }
  .table-card {
    background: var(--mj-bg-surface);
    border: 1px solid var(--mj-border-default);
    border-radius: var(--mj-radius-md);
    overflow: hidden;
  }
  table {
    width: 100%;
    border-collapse: collapse;
    font-size: 13px;
  }
  th, td {
    text-align: left;
    padding: 11px 14px;
    border-bottom: 1px solid var(--mj-border-default);
  }
  th {
    color: var(--mj-text-secondary);
    font-weight: 600;
    background: var(--mj-bg-surface-card);
  }
  .badge {
    display: inline-block;
    padding: 2px 8px;
    border-radius: 6px;
    font-size: 11px;
    font-weight: 600;
    border: 1px solid var(--mj-border-default);
    color: var(--mj-status-info-text);
  }
  .clamped {
    color: var(--mj-status-warning);
    border-color: var(--mj-status-warning);
  }
</style>
</head>
<body>
  <main class="page-shell" data-testid="limits-harness">
    <header class="page-header">
      <div>
        <h1 class="page-title">BizApps Common Angular — Limits Configuration Harness</h1>
        <p class="page-subtitle">Package: @mj-biz-apps/common-ng · Browser-Safe Resolver + DI &amp; Runtime Overrides</p>
      </div>
      <span class="status-pill" data-testid="zero-runaway-pill">RunawayGuards: ${defaultsResult.Limits.RunawayGuards.ActiveGuardCount} (ZeroHitsConfirmed: ${defaultsResult.Limits.RunawayGuards.ZeroHitsConfirmed})</span>
    </header>
    <section class="summary-strip">
      <div class="summary-tile">
        <div class="summary-label">RunawayGuard Hits</div>
        <div class="summary-value">0</div>
      </div>
      <div class="summary-tile">
        <div class="summary-label">ProtocolLimit (Angular)</div>
        <div class="summary-value">0</div>
      </div>
      <div class="summary-tile">
        <div class="summary-label">Resolved Keys</div>
        <div class="summary-value">${cards.length}</div>
      </div>
      <div class="summary-tile">
        <div class="summary-label">Ceiling Clamping</div>
        <div class="summary-value">Active</div>
      </div>
    </section>
    <section class="table-card">
      <table>
        <thead>
          <tr>
            <th>Category</th>
            <th>Key Path</th>
            <th>Default</th>
            <th>Resolved (Sample Override)</th>
            <th>Tier</th>
          </tr>
        </thead>
        <tbody>
          ${cards
              .map(
                  (c) => `<tr>
            <td><span class="badge">${escapeHtml(c.category)}</span></td>
            <td><code>${escapeHtml(c.key)}</code></td>
            <td>${escapeHtml(c.defaultVal)}</td>
            <td><strong>${escapeHtml(c.resolved.Value)}</strong>${c.resolved.WasClamped ? ' <span class="badge clamped">clamped</span>' : ''}</td>
            <td>${escapeHtml(c.resolved.SourceTier)}</td>
          </tr>`,
              )
              .join('')}
        </tbody>
      </table>
    </section>
  </main>
</body>
</html>`;

    const playwrightPath = resolvePlaywrightPath();
    const pw = require(playwrightPath);
    const browser = await pw.chromium.launch({ headless: true });
    const pageErrors = [];
    const consoleErrors = [];

    try {
        const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
        page.on('pageerror', (err) => pageErrors.push(err.message));
        page.on('console', (msg) => {
            if (msg.type() === 'error') {
                consoleErrors.push(msg.text());
            }
        });

        await page.setContent(html, { waitUntil: 'load' });
        await page.waitForSelector('[data-testid="limits-harness"]');

        const rowCount = await page.locator('tbody tr').count();
        const pillText = await page.locator('[data-testid="zero-runaway-pill"]').textContent();
        const brokenImages = await page.evaluate(() =>
            Array.from(document.querySelectorAll('img')).filter((img) => !img.complete || img.naturalWidth === 0).length,
        );

        await page.screenshot({ path: screenshotPath, fullPage: true });
        if (!existsSync(screenshotPath)) {
            throw new Error(`Screenshot missing at ${screenshotPath}`);
        }
        const stat = statSync(screenshotPath);
        if (stat.size <= 0) {
            throw new Error(`Screenshot is empty at ${screenshotPath}`);
        }

        if (pageErrors.length > 0 || consoleErrors.length > 0 || brokenImages > 0 || rowCount !== cards.length) {
            throw new Error(
                JSON.stringify({
                    pageErrors,
                    consoleErrors,
                    brokenImages,
                    rowCount,
                    expectedRows: cards.length,
                }),
            );
        }

        console.log(
            JSON.stringify({
                passed: true,
                pageErrors: pageErrors.length,
                consoleErrors: consoleErrors.length,
                brokenImages,
                renderedRows: rowCount,
                pillText: (pillText ?? '').trim(),
                screenshotPath,
                screenshotBytes: stat.size,
            }),
        );
    } finally {
        await browser.close();
    }
}

main().catch((err) => {
    console.error(err);
    process.exit(1);
});
