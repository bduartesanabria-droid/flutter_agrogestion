const MB = 1024 * 1024;

function mostrarNoDisponible(tarjeta) {
  tarjeta.querySelector("[data-meta]").textContent = "Descarga no disponible por ahora";
  tarjeta.querySelector("[data-estado]").textContent = "Vuelva a intentarlo más tarde.";
}

function llenarTarjeta(tarjeta, datos) {
  if (!datos || !(datos.bytes > 0) || !datos.archivo) return mostrarNoDisponible(tarjeta);
  const boton = tarjeta.querySelector("[data-boton]");
  tarjeta.querySelector("[data-meta]").textContent =
    `Versión ${datos.version} · ${(datos.bytes / MB).toFixed(1)} MB · ${datos.fecha}`;
  boton.href = `descargas/${encodeURIComponent(datos.archivo)}`;
  boton.setAttribute("aria-disabled", "false");
  boton.classList.replace("btn-secondary", "btn-primary");
  if (datos.sha256) {
    tarjeta.querySelector("[data-hash-valor]").textContent = datos.sha256;
    tarjeta.querySelector("[data-hash]").hidden = false;
  }
}

function activarCopiar() {
  document.querySelectorAll("[data-copiar]").forEach((boton) => {
    boton.addEventListener("click", async () => {
      const valor = boton.closest("[data-hash]").querySelector("[data-hash-valor]");
      const texto = boton.textContent;
      try {
        await navigator.clipboard.writeText(valor.textContent);
        boton.textContent = "Copiado";
      } catch {
        getSelection().selectAllChildren(valor);
        boton.textContent = "Seleccionado";
      }
      setTimeout(() => (boton.textContent = texto), 2000);
    });
  });
}

async function cargarVersiones() {
  const tarjetas = document.querySelectorAll("[data-plataforma]");
  try {
    const respuesta = await fetch("descargas/version.json", { cache: "no-cache" });
    if (!respuesta.ok) throw new Error("sin version.json");
    const datos = await respuesta.json();
    tarjetas.forEach((t) => llenarTarjeta(t, datos[t.dataset.plataforma]));
  } catch {
    tarjetas.forEach(mostrarNoDisponible);
  }
}

activarCopiar();
cargarVersiones();
