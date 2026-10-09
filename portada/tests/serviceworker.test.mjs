import assert from "node:assert/strict";
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { after, before, test } from "node:test";
import { abrirNavegador, conServidor, copiarProyecto, leer } from "./ayudas.mjs";

let navegador;

before(async () => {
  navegador = await abrirNavegador();
});

after(async () => {
  await navegador.close();
});

const SW_VIEJO = `
self.addEventListener("install", () => self.skipWaiting());
self.addEventListener("activate", (e) => e.waitUntil(self.clients.claim()));
self.addEventListener("fetch", (e) => e.respondWith(caches.match("/") .then((r) => r || fetch(e.request))));
`;

test("el service worker viejo de Flutter se reemplaza por uno que se desinstala solo", async () => {
  const raiz = copiarProyecto();
  const ruta = join(raiz, "flutter_service_worker.js");
  const nuevo = readFileSync(ruta, "utf8");
  writeFileSync(ruta, SW_VIEJO);

  await conServidor(raiz, async (url) => {
    const pagina = await navegador.newPage();
    await pagina.goto(url, { waitUntil: "networkidle0" });
    await pagina.evaluate(async () => {
      const registro = await navigator.serviceWorker.register("/flutter_service_worker.js");
      await navigator.serviceWorker.ready;
      const cache = await caches.open("flutter-app-cache");
      await cache.put("/", new Response("app vieja"));
      return registro.scope;
    });
    const antes = await pagina.evaluate(async () => (await navigator.serviceWorker.getRegistrations()).length);
    assert.equal(antes, 1);

    writeFileSync(ruta, nuevo);
    await pagina.evaluate(async () => {
      const [registro] = await navigator.serviceWorker.getRegistrations();
      await registro.update();
    });
    let restantes = 1;
    for (let intento = 0; intento < 50 && restantes > 0; intento++) {
      await new Promise((r) => setTimeout(r, 200));
      try {
        restantes = await pagina.evaluate(async () => (await navigator.serviceWorker.getRegistrations()).length);
      } catch {
        // la pagina se recarga cuando el service worker se desinstala
      }
    }
    await pagina.reload({ waitUntil: "networkidle0" });
    const guardados = await pagina.evaluate(async () => (await window.caches.keys()).length);
    await pagina.close();
    assert.equal(restantes, 0);
    assert.equal(guardados, 0);
  });
});

test("el archivo de limpieza existe y no guarda nada en cache", () => {
  const codigo = leer("flutter_service_worker.js");
  assert.match(codigo, /unregister\(\)/);
  assert.match(codigo, /caches\.delete/);
  assert.doesNotMatch(codigo, /cache\.put|cache\.add/);
});
