import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import type { Fila } from '../src/pregunta/hechos.js';
import { soles } from '../src/pregunta/hechos.js';
import { cifrasDelPeriodo, type CifrasDelPeriodo } from '../src/pregunta/periodo.js';

/**
 * Entrega 97: Informes (en el teléfono) y «Pregúntale a Moca» (aquí) dicen
 * las mismas cifras de un periodo. El teléfono las escribe en demo.json
 * (app/test/datos/paridad_servidor_test.dart).
 */
const demo = JSON.parse(
  readFileSync(new URL('./paridad/demo.json', import.meta.url), 'utf8'),
) as {
  datos: Fila;
  momentos: { ahora: string }[];
  periodos: { desde: string; hasta: string; centimos: Record<string, number> }[];
};

describe('Los periodos de Informes, iguales en el servidor (entrega 97)', () => {
  const ahora = new Date(demo.momentos[0]!.ahora);
  for (const p of demo.periodos) {
    it(`del ${p.desde} al ${p.hasta}`, () => {
      const r = cifrasDelPeriodo(demo.datos, p.desde, p.hasta, ahora) as CifrasDelPeriodo;
      const c = p.centimos;
      expect({
        vendiste: r.vendiste,
        deEsoAlFiado: r.deEsoAlFiado,
        teEntro: r.teEntro,
        salio: r.salio,
        compraste: r.compraste,
        deEsoAlCredito: r.deEsoAlCredito,
        retirasteParaTi: r.retirasteParaTi,
        pusisteDeTuBolsillo: r.pusisteDeTuBolsillo,
        tePagaronDeFiados: r.tePagaronDeFiados,
        pagasteDeLoQueDebias: r.pagasteDeLoQueDebias,
      }).toEqual({
        vendiste: soles(c.vendiste!),
        deEsoAlFiado: soles(c.alFiado!),
        teEntro: soles(c.entro!),
        salio: soles(c.salio!),
        compraste: soles(c.compraste!),
        deEsoAlCredito: soles(c.alCredito!),
        retirasteParaTi: soles(c.retiros!),
        pusisteDeTuBolsillo: soles(c.aportes!),
        // Entrega 98: «Debo» y «Me deben».
        tePagaronDeFiados: soles(c.tePagaron!),
        pagasteDeLoQueDebias: soles(c.pagaste!),
      });
    });
  }
});
