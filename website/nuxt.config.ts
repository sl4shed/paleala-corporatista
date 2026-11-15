// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  vite: {
    server: {
      allowedHosts: true
    }
  },

  nitro: {
    experimental: {
      websocket: true,
    },
  },

  modules: ["@nuxthub/core", "@vueuse/nuxt/module"],
  compatibilityDate: "2025-07-15",
  devtools: { enabled: true },
});
