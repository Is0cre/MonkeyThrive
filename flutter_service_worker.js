// Retires the service worker from when the PWA was served at the domain root.
// The landing page does not register this file. Browsers that already
// installed that worker download this replacement on their update check,
// clear the old caches, and drop the registration so "/" can show the page.
self.addEventListener('install', function (event) {
  event.waitUntil(self.skipWaiting());
});

self.addEventListener('activate', function (event) {
  event.waitUntil(
    caches.keys()
      .then(function (keys) {
        return Promise.all(keys.map(function (key) {
          return caches.delete(key);
        }));
      })
      .then(function () {
        return self.registration.unregister();
      })
      .then(function () {
        return self.clients.matchAll({ type: 'window' });
      })
      .then(function (clients) {
        clients.forEach(function (client) {
          if (client.navigate) client.navigate(client.url);
        });
      })
  );
});
