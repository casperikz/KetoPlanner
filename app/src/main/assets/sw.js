/* Keto Planner service worker — network-first so updates are always picked up online, with an offline cache fallback. */
const CACHE = 'keto-planner-v2';
const ASSETS = ['./', './index.html', './manifest.json', './icon.svg'];

self.addEventListener('install', (e) => {
    e.waitUntil(caches.open(CACHE).then((c) => c.addAll(ASSETS)).catch(() => { }));
    self.skipWaiting();
});

self.addEventListener('activate', (e) => {
    e.waitUntil(caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))));
    self.clients.claim();
});

self.addEventListener('fetch', (e) => {
    if (e.request.method !== 'GET') return;
    const url = new URL(e.request.url);
    if (url.origin !== location.origin) return;
    e.respondWith(
        fetch(e.request)
            .then((resp) => {
                const copy = resp.clone();
                caches.open(CACHE).then((c) => c.put(e.request, copy)).catch(() => { });
                return resp;
            })
            .catch(() => caches.match(e.request).then((r) => r || caches.match('./index.html')))
    );
});
