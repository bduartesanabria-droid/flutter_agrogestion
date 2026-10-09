const base = document.querySelector('meta[name="api-base"]').content;

const bloques = [
  ["datos_que_usamos", "datos"],
  ["para_que", "para-que"],
  ["sus_derechos", "derechos"],
];

function llenarLista(id, items) {
  const lista = document.getElementById(id);
  lista.replaceChildren(
    ...items.map((texto) => Object.assign(document.createElement("li"), { textContent: texto })),
  );
}

async function cargarPolitica() {
  const estado = document.getElementById("estado");
  try {
    const respuesta = await fetch(`${base}/politica`);
    if (!respuesta.ok) throw new Error("sin politica");
    const politica = await respuesta.json();
    bloques.forEach(([campo, id]) => llenarLista(id, politica[campo] ?? []));
    document.getElementById("version").textContent = `Versión ${politica.version} · ${politica.estado}`;
    document.getElementById("contenido-politica").hidden = false;
    estado.hidden = true;
  } catch {
    estado.textContent = "No pudimos cargar la política en este momento. Intente de nuevo más tarde.";
  }
}

cargarPolitica();
