import assert from "node:assert/strict";
import { mkdirSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { after, before, test } from "node:test";
import { generar } from "../scripts/generar_version.mjs";
import { abrirNavegador, conServidor, copiarProyecto } from "./ayudas.mjs";

let navegador;

before(async () => {
  navegador = await abrirNavegador();
});

after(async () => {
  await navegador.close();
});

function sitio({ android = true, windows = true, version = true } = {}) {
  const raiz = copiarProyecto();
  const carpeta = join(raiz, "descargas");
  rmSync(carpeta, { recursive: true, force: true });
  mkdirSync(carpeta);
  if (android) writeFileSync(join(carpeta, "AgroGestion.apk"), Buffer.alloc(3 * 1024 * 1024, 1));
  if (windows) writeFileSync(join(carpeta, "AgroGestion_windows.zip"), Buffer.alloc(5 * 1024 * 1024, 2));
  if (version) generar(carpeta, "1.4.0", "2026-10-09");
  return raiz;
}

async function leerTarjetas(raiz) {
  return conServidor(raiz, async (url) => {
    const pagina = await navegador.newPage();
    await pagina.setViewport({ width: 390, height: 844 });
    await pagina.goto(url, { waitUntil: "networkidle0" });
    const datos = await pagina.evaluate(() =>
      Object.fromEntries(
        [...document.querySelectorAll("[data-plataforma]")].map((t) => [
          t.dataset.plataforma,
          {
            meta: t.querySelector("[data-meta]").textContent,
            estado: t.querySelector("[data-estado]").textContent,
            habilitado: t.querySelector("[data-boton]").getAttribute("aria-disabled") === "false",
            href: t.querySelector("[data-boton]").getAttribute("href"),
            hashVisible: !t.querySelector("[data-hash]").hidden,
            hash: t.querySelector("[data-hash-valor]").textContent,
          },
        ]),
      ),
    );
    await pagina.close();
    return datos;
  });
}

test("con los dos archivos muestra version, tamano, fecha y huella", async () => {
  const datos = await leerTarjetas(sitio());
  assert.equal(datos.android.meta, "Versión 1.4.0 · 3.0 MB · 2026-10-09");
  assert.equal(datos.windows.meta, "Versión 1.4.0 · 5.0 MB · 2026-10-09");
  assert.equal(datos.android.habilitado, true);
  assert.equal(datos.android.href, "descargas/AgroGestion.apk");
  assert.equal(datos.windows.href, "descargas/AgroGestion_windows.zip");
  assert.match(datos.android.hash, /^[0-9a-f]{64}$/);
  assert.equal(datos.windows.hashVisible, true);
});

test("sin version.json no hay botones ni cifras inventadas", async () => {
  const datos = await leerTarjetas(sitio({ version: false }));
  for (const plataforma of ["android", "windows"]) {
    assert.equal(datos[plataforma].meta, "Descarga no disponible por ahora");
    assert.equal(datos[plataforma].habilitado, false);
    assert.equal(datos[plataforma].hashVisible, false);
    assert.ok(datos[plataforma].estado.length > 0);
  }
});

test("si solo existe el APK, Windows queda como no disponible", async () => {
  const datos = await leerTarjetas(sitio({ windows: false }));
  assert.equal(datos.android.habilitado, true);
  assert.equal(datos.windows.habilitado, false);
  assert.equal(datos.windows.meta, "Descarga no disponible por ahora");
});

test("el archivo anunciado se descarga completo y con el tipo correcto", async () => {
  const raiz = sitio();
  await conServidor(raiz, async (url) => {
    const apk = await fetch(`${url}/descargas/AgroGestion.apk`);
    assert.equal(apk.status, 200);
    assert.equal(apk.headers.get("content-type"), "application/vnd.android.package-archive");
    assert.equal((await apk.arrayBuffer()).byteLength, 3 * 1024 * 1024);
    const zip = await fetch(`${url}/descargas/AgroGestion_windows.zip`);
    assert.equal(zip.headers.get("content-type"), "application/zip");
  });
});

test("copiar la huella usa el portapapeles", async () => {
  await conServidor(sitio(), async (url) => {
    const pagina = await navegador.newPage();
    await pagina.evaluateOnNewDocument(() => {
      window.__copiado = null;
      Object.defineProperty(navigator, "clipboard", {
        value: { writeText: async (texto) => (window.__copiado = texto) },
      });
    });
    await pagina.goto(url, { waitUntil: "networkidle0" });
    await pagina.click('[data-plataforma="android"] [data-copiar]');
    const copiado = await pagina.evaluate(() => window.__copiado);
    const boton = await pagina.$eval('[data-plataforma="android"] [data-copiar]', (b) => b.textContent);
    await pagina.close();
    assert.match(copiado, /^[0-9a-f]{64}$/);
    assert.equal(boton, "Copiado");
  });
});

test("un boton deshabilitado no navega", async () => {
  await conServidor(sitio({ version: false }), async (url) => {
    const pagina = await navegador.newPage();
    await pagina.setViewport({ width: 1280, height: 800 });
    await pagina.goto(url, { waitUntil: "networkidle0" });
    const evento = await pagina.$eval('[data-plataforma="android"] [data-boton]', (b) => getComputedStyle(b).pointerEvents);
    await pagina.close();
    assert.equal(evento, "none");
  });
});
