import { createHash } from "node:crypto";
import { readFileSync, statSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const ARCHIVOS = { android: "AgroGestion.apk", windows: "AgroGestion_windows.zip" };

const [carpeta = "descargas"] = process.argv.slice(2);
const pubspec = readFileSync("pubspec.yaml", "utf8");
const version = pubspec.match(/^version:\s*([\d.]+)/m)?.[1];
if (!version) throw new Error("No se encontró la versión en pubspec.yaml");

const salida = {};
for (const [plataforma, archivo] of Object.entries(ARCHIVOS)) {
  const ruta = join(carpeta, archivo);
  salida[plataforma] = {
    archivo,
    version,
    bytes: statSync(ruta).size,
    fecha: new Date().toISOString().slice(0, 10),
    sha256: createHash("sha256").update(readFileSync(ruta)).digest("hex"),
  };
}
writeFileSync(join(carpeta, "version.json"), `${JSON.stringify(salida, null, 2)}\n`);
console.log(JSON.stringify(salida, null, 2));
