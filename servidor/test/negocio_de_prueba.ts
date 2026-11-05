import { randomUUID } from 'node:crypto';

// Un negocio para subir en las pruebas del cobro (entregas 24 y 32).

export interface Persona {
  usuarioId: string;
  llave: string;
}

/** Un negocio con una venta hecha el día indicado. */
export function negocio(nombre: string, duenoId: string, creadoEn: string) {
  const efectivo = randomUUID();
  const venta = randomUUID();
  return {
    empresa: {
      id: randomUUID(),
      nombre,
      tipo_negocio: 'bodega',
      modo: 'simple',
      pais: 'PE',
      moneda: 'PEN',
      hora_cierre_minutos: 1260,
      creado_en: creadoEn,
    },
    cuentas: [
      {
        id: efectivo,
        tipo: 'efectivo',
        nombre: 'Efectivo',
        orden: 0,
        saldo_inicial_centimos: 100000,
        fecha_saldo_inicial: creadoEn,
      },
    ],
    categorias: [
      {
        id: venta,
        nombre: 'Venta del día',
        tipo_movimiento: 'ingreso',
        orden: 0,
        activa: true,
      },
    ],
    movimientos: [
      {
        id: randomUUID(),
        tipo: 'ingreso',
        cuenta_id: efectivo,
        monto_centimos: 35000,
        fecha_movimiento: creadoEn,
        estado_pago: 'pagado',
        monto_pagado_centimos: 35000,
        fecha_pago: creadoEn,
        categoria_id: venta,
        nivel_confianza: 'd',
        fuente: 'voz',
        autor_id: duenoId,
        estado: 'vigente',
        creado_en: creadoEn,
      },
    ],
  };
}

