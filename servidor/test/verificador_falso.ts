import type { Verificador } from '../src/cuenta/verificador.js';

/** «123456» entra, «000000» venció, cualquier otro es incorrecto. */
export function verificadorFalso(): Verificador & { enviados: string[] } {
  const enviados: string[] = [];
  return {
    enviados,
    async enviar(celular) {
      enviados.push(celular);
      return 'enviado';
    },
    async comprobar(_celular, codigo) {
      if (codigo === '123456') return 'aprobado';
      if (codigo === '000000') return 'vencido';
      return 'incorrecto';
    },
  };
}
