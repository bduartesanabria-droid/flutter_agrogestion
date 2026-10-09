import assert from "node:assert/strict";
import { test } from "node:test";
import { contraste, tokens } from "./ayudas.mjs";

const t = tokens();

const PARES_TEXTO = [
  ["text", "surface-lowest"],
  ["text", "surface"],
  ["text-soft", "surface-lowest"],
  ["text-soft", "surface"],
  ["text-soft", "surface-low"],
  ["text-soft", "hero-from"],
  ["ink", "surface-lowest"],
  ["ink", "hero-from"],
  ["ink", "brand-soft"],
  ["brand", "surface-lowest"],
  ["brand", "surface"],
  ["brand", "surface-low"],
  ["on-brand", "brand"],
  ["on-brand", "brand-hover"],
  ["amber-ink", "amber-soft"],
];

for (const [texto, fondo] of PARES_TEXTO) {
  test(`contraste AA: ${texto} sobre ${fondo}`, () => {
    const valor = contraste(t[texto], t[fondo]);
    assert.ok(valor >= 4.5, `${valor.toFixed(2)}:1 (${t[texto]} sobre ${t[fondo]})`);
  });
}

test("el gris de detalles no se usa como texto y los verdes vivos son solo decorativos", () => {
  assert.ok(contraste(t.outline, t.surface) < 4.5, "si outline ya cumple, puede usarse como texto");
  assert.ok(contraste(t["brand-bright"], t["surface-lowest"]) < 4.5, "brand-bright es solo decorativo");
});
