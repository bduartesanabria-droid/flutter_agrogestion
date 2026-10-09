import { cpSync, existsSync, mkdtempSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { JSDOM } from "jsdom";
import puppeteer from "puppeteer-core";
import { servir } from "../scripts/servir.mjs";

export const RAIZ = fileURLToPath(new URL("..", import.meta.url));
export const leer = (ruta) => readFileSync(join(RAIZ, ruta), "utf8");
export const dom = (ruta) => new JSDOM(leer(ruta)).window.document;

export const ANCHOS = [320, 360, 390, 820, 1280];

const CANDIDATOS = [
  process.env.CHROME_PATH,
  "/usr/bin/google-chrome",
  "/usr/bin/chromium",
  "C:/Program Files/Google/Chrome/Application/chrome.exe",
  "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
].filter(Boolean);

export async function abrirNavegador() {
  const executablePath = CANDIDATOS.find((ruta) => existsSync(ruta));
  if (!executablePath) throw new Error("No se encontro Chrome. Defina CHROME_PATH.");
  return puppeteer.launch({ executablePath, headless: true, args: ["--no-sandbox"] });
}

export function copiarProyecto() {
  const destino = mkdtempSync(join(tmpdir(), "portada-"));
  cpSync(RAIZ, destino, {
    recursive: true,
    filter: (origen) => !/node_modules|\.git([\\/]|$)/.test(origen),
  });
  return destino;
}

export async function conServidor(raiz, trabajo) {
  const { servidor, url } = await servir(0, raiz);
  try {
    return await trabajo(url);
  } finally {
    servidor.close();
  }
}

export function luminancia(hex) {
  const [r, g, b] = [1, 3, 5]
    .map((i) => parseInt(hex.slice(i, i + 2), 16) / 255)
    .map((c) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4));
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

export function contraste(a, b) {
  const [alta, baja] = [luminancia(a), luminancia(b)].sort((x, y) => y - x);
  return (alta + 0.05) / (baja + 0.05);
}

export function tokens() {
  const salida = {};
  for (const [, nombre, valor] of leer("css/tokens.css").matchAll(/--([\w-]+):\s*(#[0-9a-fA-F]{6})\s*;/g)) {
    salida[nombre] = valor;
  }
  return salida;
}
