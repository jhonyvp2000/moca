import 'package:flutter/material.dart';

import 'categorias.dart';

/// Un icono por categoría (Perú). Las que el dueño agrega llevan el genérico.
IconData iconoDeCategoria(String? nombre) => switch (nombre) {
  categoriaVentaDelDia => Icons.storefront_rounded,
  categoriaCobroDeFiado => Icons.handshake_rounded,
  'Otro ingreso' || 'Ingreso ocasional' => Icons.add_card_rounded,
  'Alquiler' => Icons.home_rounded,
  'Servicios (luz, agua, internet, teléfono)' => Icons.bolt_rounded,
  'Sueldos del personal' => Icons.groups_rounded,
  'Movilidad del negocio' => Icons.local_taxi_rounded,
  'Flete' => Icons.local_shipping_rounded,
  'Publicidad' => Icons.campaign_rounded,
  'Contador o gestoría' => Icons.calculate_rounded,
  'Mantenimiento y reparaciones' ||
  'Herramientas y repuestos' ||
  'Herramientas y equipos' ||
  'Repuestos' => Icons.build_rounded,
  'Impuestos y trámites' => Icons.account_balance_rounded,
  'Mercadería' ||
  'Productos e insumos' ||
  'Materiales' => Icons.inventory_2_rounded,
  'Insumos de cocina' || 'Insumos de panadería' => Icons.restaurant_rounded,
  'Bebidas' => Icons.local_drink_rounded,
  'Gas' => Icons.local_fire_department_rounded,
  'Bolsas y envases' || 'Descartables' => Icons.shopping_bag_rounded,
  'Medicamentos y productos' => Icons.medication_rounded,
  _ when nombre == categoriaCombustible => Icons.local_gas_station_rounded,
  _ when nombre == categoriaCuotaDePrestamo => Icons.request_quote_rounded,
  _ => Icons.label_rounded,
};
