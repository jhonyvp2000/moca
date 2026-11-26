-- Uso real de los pilotos (26-11-2026). Solo lee: no cambia nada.
-- No muestra nombres, celulares ni montos: cada negocio sale como N1, N2…
-- Cómo correrla: en Render, servicio moca-servidor → Shell:
--   npm run uso-pilotos
-- y copiar el resultado completo a Claude Code. (También corre con psql.)

BEGIN READ ONLY;
SET LOCAL app.admin = 'si';

\echo '== 1. Negocios: cuántos hay y cuántos están vivos =='
WITH n AS (
  SELECT e.id, e.creado_en,
         (SELECT max(m.creado_en) FROM movimientos m WHERE m.empresa_id = e.id) AS ultimo_registro,
         (SELECT count(*) FROM movimientos m WHERE m.empresa_id = e.id AND m.estado = 'vigente') AS registros
  FROM empresas e
)
SELECT count(*) AS negocios,
       count(*) FILTER (WHERE registros > 0) AS con_registros,
       count(*) FILTER (WHERE ultimo_registro >= now() - interval '7 days') AS anotaron_ultimos_7_dias,
       count(*) FILTER (WHERE ultimo_registro >= now() - interval '30 days') AS anotaron_ultimos_30_dias,
       count(*) FILTER (WHERE registros >= 20) AS con_20_registros_o_mas
FROM n;

\echo '== 2. Cada negocio, sin nombre: antigüedad y constancia (últimos 30 días) =='
WITH n AS (
  SELECT e.id, e.creado_en, row_number() OVER (ORDER BY e.creado_en) AS orden
  FROM empresas e
)
SELECT 'N' || n.orden AS negocio,
       (now()::date - n.creado_en::date) AS dias_con_moca,
       count(m.id) FILTER (WHERE m.estado = 'vigente') AS registros_total,
       -- Solo lo vigente, como el total: lo deshecho no cuenta.
       count(m.id) FILTER (WHERE m.estado = 'vigente'
         AND m.creado_en >= now() - interval '30 days') AS registros_30d,
       count(DISTINCT (m.creado_en AT TIME ZONE 'America/Lima')::date)
         FILTER (WHERE m.creado_en >= now() - interval '30 days') AS dias_que_anoto_30d,
       (now()::date - max(m.creado_en)::date) AS dias_sin_anotar,
       count(DISTINCT m.autor_id) AS personas_que_anotan
FROM n LEFT JOIN movimientos m ON m.empresa_id = n.id
GROUP BY n.orden, n.creado_en
ORDER BY registros_30d DESC, n.orden;

\echo '== 3. Cómo anotan: voz, escrito, foto o QR (últimos 30 días) =='
SELECT fuente, count(*) AS registros,
       count(DISTINCT empresa_id) AS negocios,
       round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS porcentaje
FROM movimientos
WHERE creado_en >= now() - interval '30 days' AND estado = 'vigente'
GROUP BY fuente ORDER BY registros DESC;

\echo '== 4. Qué anotan (últimos 30 días) =='
SELECT tipo,
       CASE WHEN abona_a IS NOT NULL THEN 'pago en parte'
            WHEN estado_pago <> 'pagado' THEN 'se debe'
            ELSE 'pagado' END AS como,
       count(*) AS registros, count(DISTINCT empresa_id) AS negocios
FROM movimientos
WHERE creado_en >= now() - interval '30 days' AND estado = 'vigente'
GROUP BY 1, 2 ORDER BY registros DESC;

\echo '== 5. Fiados: cuántos negocios los usan =='
SELECT count(DISTINCT empresa_id) FILTER (WHERE tipo = 'ingreso' AND contraparte_id IS NOT NULL) AS negocios_con_ventas_con_cliente,
       count(DISTINCT empresa_id) FILTER (WHERE tipo = 'ingreso' AND estado_pago <> 'pagado') AS negocios_con_fiado_abierto,
       count(DISTINCT empresa_id) FILTER (WHERE tipo = 'egreso' AND estado_pago <> 'pagado') AS negocios_con_deuda_abierta,
       count(DISTINCT empresa_id) FILTER (WHERE abona_a IS NOT NULL) AS negocios_con_pagos_en_partes
FROM movimientos WHERE estado = 'vigente';

\echo '== 6. Qué pantallas y funciones usan (eventos, últimos 30 días) =='
SELECT nombre, count(*) AS veces,
       count(DISTINCT empresa_id) AS negocios,
       count(DISTINCT (empresa_id, (fecha AT TIME ZONE 'America/Lima')::date)) AS dias_negocio
FROM eventos_uso
WHERE fecha >= now() - interval '30 days'
GROUP BY nombre ORDER BY negocios DESC, veces DESC;

\echo '== 7. Secciones y avisos que abren (últimos 30 días) =='
SELECT nombre, coalesce(datos->>'seccion', datos->>'tipo', datos->>'modo', '—') AS cual,
       count(*) AS veces, count(DISTINCT empresa_id) AS negocios
FROM eventos_uso
WHERE fecha >= now() - interval '30 days'
  AND nombre IN ('seccionAbierta', 'avisoTocado', 'ventaGuardada', 'videoAbierto')
GROUP BY 1, 2 ORDER BY veces DESC LIMIT 40;

\echo '== 8. Cuánto tardan en anotar la venta (segundos, mediana) =='
SELECT coalesce(datos->>'modo', '—') AS modo, count(*) AS veces,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY (datos->>'segundos')::numeric) AS mediana_seg
FROM eventos_uso
WHERE nombre = 'ventaGuardada' AND datos ? 'segundos'
  AND fecha >= now() - interval '30 days'
GROUP BY 1 ORDER BY veces DESC;

\echo '== 9. Días que abren Moca por semana (últimas 4 semanas) =='
WITH d AS (
  SELECT empresa_id, date_trunc('week', fecha AT TIME ZONE 'America/Lima')::date AS semana,
         count(DISTINCT (fecha AT TIME ZONE 'America/Lima')::date) AS dias
  FROM eventos_uso
  WHERE nombre = 'appAbierta' AND fecha >= now() - interval '28 days'
  GROUP BY 1, 2
)
SELECT semana, count(*) AS negocios_que_abrieron,
       round(avg(dias), 1) AS dias_promedio,
       count(*) FILTER (WHERE dias >= 5) AS abrieron_5_dias_o_mas
FROM d GROUP BY semana ORDER BY semana;

\echo '== 10. Pregúntale a Moca =='
SELECT count(*) AS preguntas, count(DISTINCT empresa_id) AS negocios,
       count(*) FILTER (WHERE resultado = 'respondida') AS respondidas,
       count(DISTINCT (fecha AT TIME ZONE 'America/Lima')::date) AS dias_con_preguntas,
       min(fecha)::date AS desde
FROM preguntas;

\echo '== 11. Arqueos y equipos =='
SELECT (SELECT count(*) FROM arqueos) AS arqueos,
       (SELECT count(DISTINCT empresa_id) FROM arqueos) AS negocios_con_arqueo,
       (SELECT count(*) FROM (SELECT empresa_id FROM membresias GROUP BY empresa_id HAVING count(*) > 1) x) AS negocios_con_equipo;

ROLLBACK;
