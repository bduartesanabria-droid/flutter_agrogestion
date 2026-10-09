import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { generar } from "../scripts/generar_version.mjs";

const carpeta = () => mkdtempSync(join(tmpdir(), "version-"));
const sha = (datos) => createHash("sha256").update(datos).digest("hex");

test("describe cada archivo con su tamano real y su huella", () => {
  const dir = carpeta();
  writeFileSync(join(dir, "AgroGestion.apk"), "contenido-apk");
  writeFileSync(join(dir, "AgroGestion_windows.zip"), "contenido-zip-mas-largo");
  const salida = generar(dir, "1.2.3", "2026-10-09");
  assert.deepEqual(salida.android, {
    archivo: "AgroGestion.apk",
    version: "1.2.3",
    bytes: 13,
    fecha: "2026-10-09",
    sha256: sha("contenido-apk"),
  });
  assert.equal(salida.windows.bytes, 23);
  assert.equal(salida.windows.sha256, sha("contenido-zip-mas-largo"));
});

test("escribe version.json en la carpeta", () => {
  const dir = carpeta();
  writeFileSync(join(dir, "AgroGestion.apk"), "x");
  generar(dir, "0.1.0", "2026-01-01");
  const guardado = JSON.parse(readFileSync(join(dir, "version.json"), "utf8"));
  assert.equal(guardado.android.version, "0.1.0");
});

test("si falta una plataforma no la inventa", () => {
  const dir = carpeta();
  writeFileSync(join(dir, "AgroGestion.apk"), "x");
  const salida = generar(dir, "1.0.0", "2026-01-01");
  assert.ok(salida.android);
  assert.equal(salida.windows, undefined);
});

test("sin archivos deja un version.json vacio", () => {
  const dir = carpeta();
  assert.deepEqual(generar(dir, "1.0.0", "2026-01-01"), {});
});
