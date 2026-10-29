import 'package:flutter/material.dart';

import '../../dominio/modelos.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// El desglose de «Tienes hoy»: una columna por cuenta y, con más de tres,
/// en filas de tres. Igual en el Inicio y en el de la primera semana.
class DesgloseDeCuentas extends StatelessWidget {
  const DesgloseDeCuentas({
    super.key,
    required this.saldos,
    required this.formato,
  });

  final Map<TipoCuenta, int> saldos;

  /// Cómo se muestra cada monto (en el Inicio se pueden ocultar).
  final String Function(int centimos) formato;

  static List<List<TipoCuenta?>> _enFilas(List<TipoCuenta> cuentas) => [
    for (var i = 0; i < cuentas.length; i += 3)
      [for (var j = i; j < i + 3; j++) j < cuentas.length ? cuentas[j] : null],
  ];

  @override
  Widget build(BuildContext context) {
    final cuentas = saldos.isEmpty ? TipoCuenta.basicas : saldos.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (f, fila) in _enFilas(cuentas).indexed) ...[
          if (f > 0) const SizedBox(height: 8),
          Row(
            children: [
              for (final cuenta in fila)
                Expanded(
                  child: cuenta == null
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Textos.nombreCuenta(cuenta),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Tipografia.secundario,
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                formato(saldos[cuenta] ?? 0),
                                maxLines: 1,
                                style: Tipografia.cifra(
                                  Tipografia.textoFuerte.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
