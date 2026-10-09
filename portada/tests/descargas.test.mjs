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
        [...document.querySelectorAll("[data-plataforma]")].map((t) => {
          const boton = t.querySelector("[data-boton]");
          return [
            t.dataset.plataforma,
            {
              texto: boton.textContent,
              habilitado: boton.getAttribute("aria-disabled") === "false",
              href: boton.getAttribute("href"),
              ayuda: boton.title,
              textoVisible: t.innerText.replace(boton.textContent, "").trim(),
            },
          ];
        }),
      ),
    );
    await pagina.close();
    return datos;
  });
}

test("con los dos archivos cada tarjeta es un icono y un boton que descarga", async () => {
  const datos = await leerTarjetas(sitio());
  assert.equal(datos.android.texto, "Descargar APK");
  assert.equal(datos.windows.texto, "Descargar x64");
  assert.equal(datos.android.habilitado, true);
  assert.equal(datos.android.href, "descargas/AgroGestion.apk");
  assert.equal(datos.windows.href, "descargas/AgroGestion_windows.zip");
  assert.equal(datos.android.ayuda, "Versión 1.4.0 · 3.0 MB");
  assert.equal(datos.windows.ayuda, "Versión 1.4.0 · 5.0 MB");
});

test("la tarjeta no muestra nada mas que el icono y el boton", async () => {
  const datos = await leerTarjetas(sitio());
  for (const plataforma of ["android", "windows"]) {
    assert.equal(datos[plataforma].textoVisible, "", `texto extra en ${plataforma}`);
  }
});

test("sin version.json el boton avisa que no esta disponible y no descarga", async () => {
  const datos = await leerTarjetas(sitio({ version: false }));
  for (const plataforma of ["android", "windows"]) {
    assert.equal(datos[plataforma].texto, "No disponible por ahora");
    assert.equal(datos[plataforma].habilitado, false);
  }
});

test("si solo existe el APK, Windows queda como no disponible", async () => {
  const datos = await leerTarjetas(sitio({ windows: false }));
  assert.equal(datos.android.habilitado, true);
  assert.equal(datos.windows.habilitado, false);
  assert.equal(datos.windows.texto, "No disponible por ahora");
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
