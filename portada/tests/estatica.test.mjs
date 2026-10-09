import assert from "node:assert/strict";
import { existsSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";
import { test } from "node:test";
import { RAIZ, dom, leer } from "./ayudas.mjs";

const PAGINAS = ["index.html", "privacidad.html"];
const EMOJI = /[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]/u;

function archivosDeTexto(carpeta = RAIZ, acumulado = []) {
  for (const nombre of readdirSync(carpeta)) {
    if (["node_modules", ".git", "descargas", "fonts"].includes(nombre)) continue;
    const ruta = join(carpeta, nombre);
    if (statSync(ruta).isDirectory()) archivosDeTexto(ruta, acumulado);
    else if (/\.(html|css|js|mjs|json|txt|xml|svg|md|yml)$/.test(nombre) && nombre !== "package-lock.json") {
      acumulado.push(ruta);
    }
  }
  return acumulado;
}

for (const pagina of PAGINAS) {
  const documento = dom(pagina);

  test(`${pagina}: un solo h1 y el idioma declarado`, () => {
    assert.equal(documento.querySelectorAll("h1").length, 1);
    assert.equal(documento.documentElement.lang, "es");
  });

  test(`${pagina}: sin estilos ni scripts incrustados, sin atributos style`, () => {
    assert.equal(documento.querySelectorAll("style").length, 0);
    assert.equal(documento.querySelectorAll("[style]").length, 0);
    const incrustados = [...documento.querySelectorAll("script:not([src])")].filter(
      (s) => s.type !== "application/ld+json",
    );
    assert.equal(incrustados.length, 0);
  });

  test(`${pagina}: nada se carga de dominios externos`, () => {
    for (const el of documento.querySelectorAll("link[href], script[src], img[src]")) {
      const destino = el.getAttribute("href") ?? el.getAttribute("src");
      const esMetadato = el.rel === "canonical";
      assert.ok(esMetadato || !/^(https?:)?\/\//.test(destino), `externo: ${destino}`);
    }
  });

  test(`${pagina}: las imagenes tienen alt, ancho y alto`, () => {
    for (const img of documento.querySelectorAll("img")) {
      assert.ok(img.getAttribute("alt")?.length > 5, `sin alt: ${img.src}`);
      assert.ok(img.getAttribute("width") && img.getAttribute("height"), `sin medidas: ${img.src}`);
    }
  });

  test(`${pagina}: los ids son unicos y los enlaces internos existen`, () => {
    const ids = [...documento.querySelectorAll("[id]")].map((e) => e.id);
    assert.equal(new Set(ids).size, ids.length, "ids repetidos");
    for (const a of documento.querySelectorAll('a[href^="#"]')) {
      const id = a.getAttribute("href").slice(1);
      assert.ok(!id || ids.includes(id), `ancla rota: ${id}`);
    }
  });

  test(`${pagina}: los archivos locales enlazados existen`, () => {
    for (const el of documento.querySelectorAll("link[href], script[src], img[src], a[href]")) {
      const destino = (el.getAttribute("href") ?? el.getAttribute("src")).split("#")[0];
      if (!destino || /^(https?:|mailto:|\/)/.test(destino)) continue;
      assert.ok(existsSync(join(RAIZ, destino)), `no existe: ${destino}`);
    }
  });

  test(`${pagina}: botones y enlaces tienen nombre`, () => {
    for (const el of documento.querySelectorAll("a, button")) {
      const nombre = el.textContent.trim() || el.getAttribute("aria-label");
      assert.ok(nombre, `sin nombre: ${el.outerHTML.slice(0, 80)}`);
    }
  });
}

test("index: cada seccion apunta a su titulo", () => {
  const documento = dom("index.html");
  for (const seccion of documento.querySelectorAll("section")) {
    const id = seccion.getAttribute("aria-labelledby");
    assert.ok(id && documento.getElementById(id), "seccion sin titulo asociado");
  }
});

test("index: el menu es corto y la entrada a la app es el boton principal", () => {
  const documento = dom("index.html");
  assert.ok(documento.querySelectorAll(".nav-links a").length <= 3);
  const entrar = documento.querySelector(".nav-cta");
  assert.equal(entrar.getAttribute("href"), "/app/");
});

test("index: las tres acciones principales estan presentes", () => {
  const documento = dom("index.html");
  assert.ok(documento.querySelector('.hero a[href="/app/"]'));
  assert.ok(documento.querySelector('.hero a[href="#descargas"]'));
  assert.equal(documento.querySelectorAll("[data-plataforma]").length, 2);
});

test("privacidad: apunta a la API y existe el contenedor", () => {
  const documento = dom("privacidad.html");
  assert.match(documento.querySelector('meta[name="api-base"]').content, /^https:\/\//);
  assert.ok(documento.getElementById("contenido-politica"));
});

test("sin emojis, sin marcadores pendientes y archivos de menos de 700 lineas", () => {
  for (const ruta of archivosDeTexto()) {
    const texto = leer(ruta.slice(RAIZ.length));
    assert.ok(!EMOJI.test(texto), `emoji en ${ruta}`);
    assert.ok(!/\[(CORREO|VERSION)_[A-Z_]+\]/.test(texto), `marcador pendiente en ${ruta}`);
    assert.ok(texto.split("\n").length < 700, `demasiado largo: ${ruta}`);
  }
});

test("los colores viven solo en tokens.css", () => {
  for (const css of ["css/base.css", "css/portada.css"]) {
    const sueltos = leer(css).match(/#[0-9a-fA-F]{3,8}\b/g) ?? [];
    assert.deepEqual(sueltos, [], `colores sueltos en ${css}`);
  }
});

test("la portada pesa poco", () => {
  const bytes = ["index.html", "css/tokens.css", "css/base.css", "css/portada.css", "js/descargas.js"].reduce(
    (suma, ruta) => suma + statSync(join(RAIZ, ruta)).size,
    0,
  );
  assert.ok(bytes < 60_000, `${bytes} bytes`);
});

test("existen los archivos para buscadores e IA", () => {
  for (const ruta of ["robots.txt", "sitemap.xml", "llms.txt", "img/favicon.svg", "img/og.png"]) {
    assert.ok(existsSync(join(RAIZ, ruta)), ruta);
  }
});

test("las tarjetas de un mismo grupo tienen textos de largo parecido", () => {
  const documento = dom("index.html");
  for (const grupo of documento.querySelectorAll(".grid")) {
    const largos = [...grupo.querySelectorAll(":scope > .card p")].map((p) => p.textContent.trim().length);
    if (largos.length < 2) continue;
    const proporcion = Math.max(...largos) / Math.min(...largos);
    assert.ok(proporcion <= 1.3, `textos muy desparejos: ${largos.join(", ")}`);
  }
});
