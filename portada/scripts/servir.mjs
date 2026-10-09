import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { fileURLToPath } from "node:url";

const TIPOS = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json",
  ".svg": "image/svg+xml",
  ".webp": "image/webp",
  ".png": "image/png",
  ".woff2": "font/woff2",
  ".txt": "text/plain; charset=utf-8",
  ".xml": "application/xml",
  ".apk": "application/vnd.android.package-archive",
  ".zip": "application/zip",
};

const RAIZ = fileURLToPath(new URL("..", import.meta.url));

export function servir(puerto = 0, raiz = RAIZ) {
  const servidor = createServer(async (req, res) => {
    const ruta = decodeURIComponent(new URL(req.url, "http://x").pathname);
    const archivo = normalize(join(raiz, ruta.endsWith("/") ? `${ruta}index.html` : ruta));
    if (!archivo.startsWith(normalize(raiz))) {
      res.writeHead(403).end();
      return;
    }
    try {
      const datos = await readFile(archivo);
      res.writeHead(200, { "Content-Type": TIPOS[extname(archivo)] ?? "application/octet-stream" });
      res.end(datos);
    } catch {
      res.writeHead(404).end("No encontrado");
    }
  });
  return new Promise((resolver) =>
    servidor.listen(puerto, "127.0.0.1", () => resolver({ servidor, url: `http://127.0.0.1:${servidor.address().port}` })),
  );
}

if (process.argv[1]?.endsWith("servir.mjs")) {
  const { url } = await servir(Number(process.env.PORT ?? 4173));
  console.log(`Portada en ${url}`);
}
