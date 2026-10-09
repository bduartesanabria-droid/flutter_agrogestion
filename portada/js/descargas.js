const MB = 1024 * 1024;

function mostrarNoDisponible(tarjeta) {
  tarjeta.querySelector("[data-boton]").textContent = "No disponible por ahora";
}

function llenarTarjeta(tarjeta, datos) {
  if (!datos || !(datos.bytes > 0) || !datos.archivo) return mostrarNoDisponible(tarjeta);
  const boton = tarjeta.querySelector("[data-boton]");
  boton.href = `descargas/${encodeURIComponent(datos.archivo)}`;
  boton.title = `Versión ${datos.version} · ${(datos.bytes / MB).toFixed(1)} MB`;
  boton.setAttribute("aria-disabled", "false");
  boton.classList.replace("btn-secondary", "btn-primary");
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

cargarVersiones();
