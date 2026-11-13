// Lo específico de Perú del celular. Vive aparte para sumar otros países.

/** Nueve dígitos que empiezan con 9: un celular de Perú. */
export function esCelularPeru(digitos: string): boolean {
  return /^9\d{8}$/.test(digitos);
}

/** El formato internacional que usa Twilio: +51987654321. */
export function aInternacional(digitos: string): string {
  return `+51${digitos}`;
}
