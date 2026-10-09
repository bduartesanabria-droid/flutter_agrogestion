import assert from "node:assert/strict";
import { after, before, test } from "node:test";
import { servir } from "../scripts/servir.mjs";
import { ANCHOS, RAIZ, abrirNavegador } from "./ayudas.mjs";

let navegador;
let servidor;
let url;

before(async () => {
  navegador = await abrirNavegador();
  ({ servidor, url } = await servir(0, RAIZ));
});

after(async () => {
  await navegador.close();
  servidor.close();
});

async function abrir(ancho, { zoom = false, alto = 844, ruta = "/" } = {}) {
  const pagina = await navegador.newPage();
  await pagina.setViewport({ width: ancho, height: alto });
  await pagina.goto(`${url}${ruta}`, { waitUntil: "networkidle0" });
  if (zoom) await pagina.addStyleTag({ content: "html{font-size:200% !important}" });
  await pagina.evaluate(() => document.fonts.ready);
  return pagina;
}

const medirDesborde = () => {
  const ancho = document.documentElement.clientWidth;
  const culpables = [];
  document.querySelectorAll("body *").forEach((el) => {
    const r = el.getBoundingClientRect();
    if (r.width && r.right > ancho + 1 && !el.closest(".phones, .hero")) culpables.push(el.tagName + "." + el.className);
  });
  const recortados = [...document.querySelectorAll("body *")]
    .filter((el) => {
      const estilo = getComputedStyle(el);
      return estilo.overflowX === "hidden" && el.scrollWidth > el.clientWidth + 1 && !el.matches(".hero, .phone, body");
    })
    .map((el) => el.tagName + "." + el.className);
  return { desborde: document.documentElement.scrollWidth - ancho, culpables, recortados };
};

for (const ancho of ANCHOS) {
  test(`${ancho} px: sin desborde horizontal ni texto recortado`, async () => {
    const pagina = await abrir(ancho);
    const resultado = await pagina.evaluate(medirDesborde);
    await pagina.close();
    assert.ok(resultado.desborde <= 0, `la pagina se sale ${resultado.desborde} px`);
    assert.deepEqual(resultado.culpables, []);
    assert.deepEqual(resultado.recortados, []);
  });

  test(`${ancho} px con texto al 200%: sin desborde horizontal`, async () => {
    const pagina = await abrir(ancho, { zoom: true });
    const resultado = await pagina.evaluate(medirDesborde);
    await pagina.close();
    assert.ok(resultado.desborde <= 0, `la pagina se sale ${resultado.desborde} px`);
    assert.deepEqual(resultado.recortados, []);
  });

  test(`${ancho} px: las tarjetas de una misma fila miden lo mismo`, async () => {
    const pagina = await abrir(ancho);
    const filas = await pagina.evaluate(() => {
      const informe = [];
      document.querySelectorAll(".grid").forEach((grid) => {
        const porFila = new Map();
        [...grid.children].forEach((hijo) => {
          const r = hijo.getBoundingClientRect();
          const clave = Math.round(r.top);
          porFila.set(clave, [...(porFila.get(clave) ?? []), { alto: r.height, ancho: r.width }]);
        });
        porFila.forEach((items) => {
          const altos = items.map((i) => i.alto);
          const anchos = items.map((i) => i.ancho);
          informe.push({
            dAlto: Math.max(...altos) - Math.min(...altos),
            dAncho: Math.max(...anchos) - Math.min(...anchos),
          });
        });
      });
      return informe;
    });
    await pagina.close();
    assert.ok(filas.length > 0);
    for (const fila of filas) {
      assert.ok(fila.dAlto <= 1, `alturas distintas: ${fila.dAlto}`);
      assert.ok(fila.dAncho <= 1, `anchos distintos: ${fila.dAncho}`);
    }
  });
}

test("en el celular se ven las dos acciones principales sin desplazarse", async () => {
  const pagina = await abrir(390, { alto: 844 });
  const visibles = await pagina.evaluate(() =>
    [".hero a[href='/app/']", ".hero a[href='#descargas']", ".nav-cta"].map((s) => {
      const r = document.querySelector(s).getBoundingClientRect();
      return { s, dentro: r.top >= 0 && r.bottom <= window.innerHeight };
    }),
  );
  await pagina.close();
  for (const v of visibles) assert.ok(v.dentro, `fuera de la primera pantalla: ${v.s}`);
});

test("el menu del celular queda en marca y boton, sin hamburguesa", async () => {
  const pagina = await abrir(390);
  const resultado = await pagina.evaluate(() => ({
    enlaces: getComputedStyle(document.querySelector(".nav-bar nav")).display,
    interactivos: [...document.querySelectorAll(".site-header a, .site-header button")].filter((e) => e.offsetParent).length,
  }));
  await pagina.close();
  assert.equal(resultado.enlaces, "none");
  assert.ok(resultado.interactivos <= 2, `${resultado.interactivos} elementos en la barra`);
});

test("en escritorio la barra tiene marca, dos enlaces y el boton de entrar", async () => {
  const pagina = await abrir(1280);
  const total = await pagina.evaluate(
    () => [...document.querySelectorAll(".site-header a")].filter((e) => e.offsetParent).length,
  );
  await pagina.close();
  assert.equal(total, 4);
});

test("el teclado llega primero al enlace de saltar y el foco se ve", async () => {
  const pagina = await abrir(1280);
  await pagina.keyboard.press("Tab");
  const foco = await pagina.evaluate(() => {
    const activo = document.activeElement;
    return { clase: activo.className, contorno: getComputedStyle(activo).outlineStyle, arriba: activo.getBoundingClientRect().top };
  });
  await pagina.close();
  assert.equal(foco.clase, "skip-link");
  assert.notEqual(foco.contorno, "none");
  assert.ok(foco.arriba >= 0, "el enlace de saltar sigue fuera de pantalla con el foco");
});

test("las preguntas frecuentes se abren y cierran", async () => {
  const pagina = await abrir(390);
  const resultado = await pagina.evaluate(() => {
    const d = document.querySelector(".faq");
    d.querySelector("summary").click();
    const abierta = d.open;
    d.querySelector("summary").click();
    return { abierta, cerrada: !d.open };
  });
  await pagina.close();
  assert.deepEqual(resultado, { abierta: true, cerrada: true });
});

test("las fuentes propias se cargan y el fondo es el verde menta de la app", async () => {
  const pagina = await abrir(1280);
  const resultado = await pagina.evaluate(() => ({
    fuente: document.fonts.check('700 16px "Plus Jakarta Sans"'),
    familia: getComputedStyle(document.querySelector("h1")).fontFamily,
    fondoAlterno: getComputedStyle(document.querySelector(".section-alt")).backgroundColor,
  }));
  await pagina.close();
  assert.ok(resultado.fuente);
  assert.match(resultado.familia, /Plus Jakarta Sans/);
  assert.equal(resultado.fondoAlterno, "rgb(233, 251, 239)");
});

test("la pagina de privacidad muestra la politica que entrega la API", async () => {
  const pagina = await navegador.newPage();
  await pagina.setViewport({ width: 390, height: 844 });
  await pagina.setRequestInterception(true);
  pagina.on("request", (peticion) => {
    if (peticion.url().endsWith("/politica")) {
      peticion.respond({
        status: 200,
        contentType: "application/json",
        headers: { "access-control-allow-origin": "*" },
        body: JSON.stringify({
          version: "2026-09",
          estado: "borrador",
          datos_que_usamos: ["Su nombre y correo."],
          para_que: ["Llevar la gestión de su finca."],
          sus_derechos: ["Conocer y corregir sus datos."],
        }),
      });
    } else peticion.continue();
  });
  await pagina.goto(`${url}/privacidad.html`, { waitUntil: "networkidle0" });
  const texto = await pagina.evaluate(() => document.body.innerText);
  const desborde = await pagina.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
  await pagina.close();
  assert.match(texto, /Su nombre y correo\./);
  assert.match(texto, /Versión 2026-09 · borrador/);
  assert.ok(desborde <= 0);
});

test("si la API no responde, privacidad lo dice sin inventar texto legal", async () => {
  const pagina = await navegador.newPage();
  await pagina.setRequestInterception(true);
  pagina.on("request", (peticion) => (peticion.url().endsWith("/politica") ? peticion.abort() : peticion.continue()));
  await pagina.goto(`${url}/privacidad.html`, { waitUntil: "networkidle0" });
  const estado = await pagina.evaluate(() => document.getElementById("estado").textContent);
  const oculto = await pagina.evaluate(() => document.getElementById("contenido-politica").hidden);
  await pagina.close();
  assert.match(estado, /No pudimos cargar la política/);
  assert.equal(oculto, true);
});

test("los botones de las tarjetas de descarga quedan alineados", async () => {
  for (const ancho of [1000, 1280]) {
    const pagina = await abrir(ancho);
    const arriba = await pagina.evaluate(() =>
      [...document.querySelectorAll(".download-card .btn")].map((b) => Math.round(b.getBoundingClientRect().top)),
    );
    await pagina.close();
    assert.equal(new Set(arriba).size, 1, `botones desalineados a ${ancho} px: ${arriba}`);
  }
});

test("el menu es una pastilla flotante que sigue visible al bajar la pagina", async () => {
  for (const ancho of [390, 1280]) {
    const pagina = await abrir(ancho);
    await pagina.evaluate(() => window.scrollTo(0, 1800));
    const datos = await pagina.evaluate(() => {
      const barra = document.querySelector(".nav-bar").getBoundingClientRect();
      const boton = document.querySelector(".nav-cta").getBoundingClientRect();
      return { arriba: barra.top, boton: boton.top, redondeo: getComputedStyle(document.querySelector(".nav-bar")).borderRadius };
    });
    await pagina.close();
    assert.ok(datos.arriba >= 0 && datos.arriba <= 24, `la barra no queda arriba a ${ancho} px: ${datos.arriba}`);
    assert.ok(datos.boton >= 0 && datos.boton <= 90, `el boton se sale a ${ancho} px`);
    assert.notEqual(datos.redondeo, "0px");
  }
});

test("la barra no tapa el titulo de la portada", async () => {
  for (const ancho of [390, 1280]) {
    const pagina = await abrir(ancho);
    const sobreponen = await pagina.evaluate(() => {
      const barra = document.querySelector(".nav-bar").getBoundingClientRect();
      const titulo = document.querySelector("h1").getBoundingClientRect();
      return barra.bottom > titulo.top;
    });
    await pagina.close();
    assert.equal(sobreponen, false, `la barra tapa el titulo a ${ancho} px`);
  }
});
