import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: ['test/**/*.test.ts'],
    globalSetup: ['test/preparar.ts'],
    // Cada archivo de pruebas crea su propia base: pueden correr en paralelo.
    testTimeout: 20_000,
    hookTimeout: 30_000,
  },
});
