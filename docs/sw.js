if(!self.define){let e,i={};const n=(n,s)=>(n=new URL(n+".js",s).href,i[n]||new Promise((i=>{if("document"in self){const e=document.createElement("script");e.src=n,e.onload=i,document.head.appendChild(e)}else e=n,importScripts(n),i()})).then((()=>{let e=i[n];if(!e)throw new Error(`Module ${n} didn’t register its module`);return e})));self.define=(s,r)=>{const o=e||("document"in self?document.currentScript.src:"")||location.href;if(i[o])return;let c={};const t=e=>n(e,o),f={module:{uri:o},exports:c,require:t};i[o]=Promise.all(s.map((e=>f[e]||t(e)))).then((e=>(r(...e),c)))}}define(["./workbox-f8b5deff"],(function(e){"use strict";self.skipWaiting(),e.clientsClaim(),e.precacheAndRoute([{url:"assets/index.9ca066b4.css",revision:null},{url:"assets/index.ce29c4c6.js",revision:null},{url:"assets/vendor.894d8734.js",revision:null},{url:"index.html",revision:"3d58e2d844a7f52910d5ac55534b3b60"},{url:"favicon.svg",revision:"1821c958bbe5e0a6a4563025af907760"},{url:"favicon.ico",revision:"f3f70846cad486fc894f0d6145364266"},{url:"robots.txt",revision:"5e0bd1c281a62a380d7a948085bfe2d1"},{url:"apple-touch-icon.png",revision:"e5775df1a5c2c28ac93b6f8d6f75965b"},{url:"pwa-192x192.png",revision:"3cff40bf2df764a31684c5af1209529c"},{url:"pwa-512x512.png",revision:"9e4a5662204269de19e4a9fe4abdf3ac"},{url:"manifest.webmanifest",revision:"985bded84ee9dc983ad1afeb30aecea0"}],{}),e.cleanupOutdatedCaches(),e.registerRoute(new e.NavigationRoute(e.createHandlerBoundToURL("index.html")))}));
