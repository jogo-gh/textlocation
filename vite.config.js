import { defineConfig } from "vite";
import elmPlugin from "vite-plugin-elm";
import { VitePWA } from 'vite-plugin-pwa'
import replace from "@rollup/plugin-replace"

export default defineConfig({
  plugins: [elmPlugin(),
  VitePWA({
    strategies: 'injectManifest',
    srcDir: 'src',
    filename: 'sw.js',
    registerType: 'autoUpdate',
    includeAssets:
      ['favicon.svg'
        , 'favicon.ico'
        , 'robots.txt'
        , 'apple-touch-icon.png'
      ],
    manifest: {
      name: "Text My Location!",
      short_name: 'TextLocation',
      description: 'Send my location as SMS',
      theme_color: '#ffffff',
      icons: [
        {
          src: 'pwa-192x192.png',
          sizes: '192x192',
          type: 'image/png',
        },
        {
          src: 'pwa-512x512.png',
          sizes: '512x512',
          type: 'image/png',
        },
        {
          src: 'pwa-512x512.png',
          sizes: '512x512',
          type: 'image/png',
          purpose: 'any maskable',
        }
      ],
      workbox: {
        cleanupOutdatedCaches: true
      }
    }
  })
    , replace({
      __buildVersion__: "0.0.1",
      __subpath__: "textlocation"
    })
  ],
  base: "/textlocation/"
});
