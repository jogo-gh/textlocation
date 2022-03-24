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
        , 'reshot-icon-angry-bull-RDFCV35TKJ.svg'
        , 'reshot-icon-cat-X7MDCQAJBV.svg'
        , 'reshot-icon-chick-EHGK643RB7.svg'
        , 'reshot-icon-chicken-A3LF7K6C8G.svg'
        , 'reshot-icon-cow-URMEQCY7SW.svg'
        , 'reshot-icon-dog-BN3K2EX8W7.svg'
        , 'reshot-icon-donkey-EKBHU4NVZW.svg'
        , 'reshot-icon-duck-G984NMJWTC.svg'
        , 'reshot-icon-fish-92ZSLJDT7R.svg'
        , 'reshot-icon-goat-6WU932E5VP.svg'
        , 'reshot-icon-horse-RAWMC2NSQK.svg'
        , 'reshot-icon-parrot-7L5NXGZRKW.svg'
        , 'reshot-icon-pet-bird-YB7M2V9K58.svg'
        , 'reshot-icon-rooster-VWQ5829NHB.svg'
        , 'reshot-icon-sheep-2GXLFHBVWT.svg'
        , 'reshot-icon-snake-CH8DLP2ZGT.svg'
        , 'reshot-icon-striped-fish-LZUWX6VB24.svg'
        , 'reshot-icon-wild-bird-CV2LRHUYJ6.svg'],
    manifest: {
      name: "Mach's Einfach!",
      short_name: 'MachsEinfach',
      description: 'TODO list as a PWA',
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
      __buildVersion__: "0.0.1"
    })
  ],
  base: "/textlocation/"
});
