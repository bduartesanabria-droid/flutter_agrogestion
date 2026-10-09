self.addEventListener("install", () => self.skipWaiting());

self.addEventListener("activate", (event) => {
  event.waitUntil(
    (async () => {
      await Promise.all((await caches.keys()).map((nombre) => caches.delete(nombre)));
      await self.registration.unregister();
      const ventanas = await self.clients.matchAll({ type: "window" });
      ventanas.forEach((ventana) => ventana.navigate(ventana.url));
    })(),
  );
});
