import { defineConfig } from 'vitest/config';

export default defineConfig({
    test: {
        include: ['src/**/__tests__/**/*.test.ts'],
        environment: 'node',
        // WEST of Greenwich, deliberately. The defect this module prevents is a UTC-parts read
        // replaced by a local-parts read, and east of Greenwich the two agree for a UTC-midnight
        // value — the suite stayed green under Asia/Kolkata with getUTCFullYear swapped for
        // getFullYear. Chicago fails it loudly.
        env: { TZ: 'America/Chicago' },
    },
});
