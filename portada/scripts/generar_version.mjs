import { createHash } from "node:crypto";
import { readFileSync, statSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const ARCHIVOS = {
  android: "AgroGestion.apk",
  windows: "AgroGestion_windows.zip",
};

export function describir(carpeta, archivo, version, fecha) {
  const ruta = join(carpeta, archivo);
  return {
    archivo,
    version,
    bytes: statSync(ruta).size,
    fecha,
    sha256: createHash("sha256").update(readFileSync(ruta)).digest("hex"),
  };
}

export function generar(carpeta, version, fecha = new Date().toISOString().slice(0, 10)) {
  const salida = {};
  for (const [plataforma, archivo] of Object.entries(ARCHIVOS)) {
    try {
      salida[plataforma] = describir(carpeta, archivo, version, fecha);
    } catch (error) {
      if (error.code !== "ENOENT") throw error;
    }
  }
  writeFileSync(join(carpeta, "version.json"), `${JSON.stringify(salida, null, 2)}\n`);
  return salida;
}

if (import.meta.url === `file://${process.argv[1].replaceAll("\\", "/")}` || process.argv[1]?.endsWith("generar_version.mjs")) {
  const [carpeta = "descargas", version] = process.argv.slice(2);
  if (!version) {
    console.error("Uso: node scripts/generar_version.mjs <carpeta> <version>");
    process.exit(1);
  }
  console.log(JSON.stringify(generar(carpeta, version), null, 2));
}
