import type { Verificador } from '../src/cuenta/verificador.js';

/** «123456» entra, «000000» venció, cualquier otro es incorrecto. */
export function verificadorFalso(): Verificador & {
  enviados: string[];
  marcas: (string | undefined)[];
} {
  const enviados: string[] = [];
  const marcas: (string | undefined)[] = [];
  return {
    enviados,
    marcas,
    async enviar(celular, marcaApp) {
      enviados.push(celular);
      marcas.push(marcaApp);
      return 'enviado';
    },
    async comprobar(_celular, codigo) {
      if (codigo === '123456') return 'aprobado';
      if (codigo === '000000') return 'vencido';
      return 'incorrecto';
    },
  };
}
