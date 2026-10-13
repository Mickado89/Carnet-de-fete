// Carnet de Fête — service worker
// • Le site s'ouvre même sans réseau (dernière version connue).
// • Les bibliothèques et les fonds de carte déjà vus restent disponibles hors ligne.
// • Les données (Supabase) ne passent jamais par ce cache : elles sont gérées par la page.
const VERSION = 'fete-v3';
const APP_CACHE = VERSION + '-app';
const LIB_CACHE = VERSION + '-lib';
const TILE_CACHE = 'fete-tiles';          // gardé d'une version à l'autre
const MAX_TILES = 800;

const APP_FILES = ['./', './index.html', './config.js', './manifest.webmanifest', './icon-192.png', './icon-512.png', './apple-touch-icon.png'];

self.addEventListener('install', event => {
  event.waitUntil(caches.open(APP_CACHE).then(c => c.addAll(APP_FILES)).catch(() => {}));
  self.skipWaiting();
});

self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    const keep = [APP_CACHE, LIB_CACHE, TILE_CACHE];
    for (const k of await caches.keys()) if (!keep.includes(k)) await caches.delete(k);
    await self.clients.claim();
  })());
});

const isTile = u => /basemaps\.cartocdn\.com|tile\.openstreetmap\.org|arcgisonline\.com\/ArcGIS\/rest\/services/.test(u.href);
const isLib = u => /unpkg\.com|cdn\.jsdelivr\.net|fonts\.googleapis\.com|fonts\.gstatic\.com/.test(u.href);

async function trimTiles() {
  const c = await caches.open(TILE_CACHE);
  const keys = await c.keys();
  for (let i = 0; i < keys.length - MAX_TILES; i++) await c.delete(keys[i]);
}

self.addEventListener('fetch', event => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);

  // Données, itinéraires, recherche d'adresse : toujours en direct
  if (/supabase\.co|nominatim\.openstreetmap\.org|routing\.openstreetmap\.de/.test(url.href)) return;

  // Pages et fichiers du site : réseau d'abord (toujours la dernière version), cache si hors ligne
  if (url.origin === self.location.origin) {
    event.respondWith((async () => {
      try {
        const res = await fetch(req);
        if (res.ok) { const c = await caches.open(APP_CACHE); c.put(req, res.clone()); }
        return res;
      } catch {
        const hit = await caches.match(req, { ignoreSearch: true });
        if (hit) return hit;
        if (req.mode === 'navigate') return (await caches.match('./index.html')) || (await caches.match('./'));
        return Response.error();
      }
    })());
    return;
  }

  // Bibliothèques et polices : cache d'abord, mise à jour en arrière-plan
  if (isLib(url)) {
    event.respondWith((async () => {
      const c = await caches.open(LIB_CACHE);
      const hit = await c.match(req);
      const net = fetch(req).then(res => { if (res.ok || res.type === 'opaque') c.put(req, res.clone()); return res; }).catch(() => null);
      return hit || (await net) || Response.error();
    })());
    return;
  }

  // Fonds de carte : cache d'abord (les zones déjà vues restent visibles hors ligne)
  if (isTile(url)) {
    event.respondWith((async () => {
      const c = await caches.open(TILE_CACHE);
      const hit = await c.match(req);
      if (hit) return hit;
      try {
        const res = await fetch(req);
        if (res.ok) { c.put(req, res.clone()); trimTiles(); }   // tuiles chargées en CORS : pas de réponses opaques
        return res;
      } catch { return Response.error(); }
    })());
  }
});
