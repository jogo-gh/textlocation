import { defineConfig } from "vite";
import elmPlugin from "vite-plugin-elm";
import { VitePWA } from 'vite-plugin-pwa'
import replace from "@rollup/plugin-replace"

export default defineConfig({
  plugins: [elmPlugin(),
  VitePWA({
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
        cleanupOutdatedCaches: true,
        runtimeCaching: [
          {
            urlPattern: /^https:\/\/fonts\.googleapis\.com\/.*/i,
            handler: 'CacheFirst',
            options: {
              cacheName: 'google-fonts-cache',
              expiration: {
                maxEntries: 10,
                maxAgeSeconds: 60 * 60 * 24 * 365 // <== 365 days
              },
              cacheableResponse: {
                statuses: [0, 200]
              }
            }
          },
          {
            urlPattern: /^https:\/\/fonts\.gstatic\.com\/.*/i,
            handler: 'CacheFirst',
            options: {
              cacheName: 'gstatic-fonts-cache',
              expiration: {
                maxEntries: 10,
                maxAgeSeconds: 60 * 60 * 24 * 365 // <== 365 days
              },
              cacheableResponse: {
                statuses: [0, 200]
              },
            }
          }
        ]
      }
    }
  })
    , replace({
      __buildVersion__: "0.0.4",
      __subpath__: "textlocation"
    })
  ],
  base: "/textlocation/"
});
