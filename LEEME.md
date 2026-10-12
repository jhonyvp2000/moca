# Cómo empezar con Claude Code

Esta carpeta es el repositorio del proyecto Moca. Por ahora contiene documentos y diseños; el código del prototipo irá en `app/`.

## Primera vez: subir a GitHub

El repositorio privado `moca` ya existe en GitHub. Desde PowerShell:

```powershell
cd F:\JVP\CLAUDECODE\Moca
git init -b main
git add .
git commit -m "Documentación, diseños y plan del prototipo V1"
git remote add origin https://github.com/TU_USUARIO/moca.git
git push -u origin main
```

## Abrir Claude Code

```powershell
cd F:\JVP\CLAUDECODE\Moca
claude
```

No ejecutes `/init`: el `CLAUDE.md` ya está escrito.

## Primer mensaje

```
Lee CLAUDE.md, todo docs/ y diseno/indice.md y diseno/estilo.md.
No programes nada todavía. Resume qué es Moca y qué es el prototipo V1,
y lista dudas o contradicciones que encuentres en los documentos.
```

## Segundo mensaje, cuando hayas contestado sus dudas

```
Propón el plan del prototipo V1 según docs/prototipo-v1.md:
estructura del proyecto Flutter en app/, cómo separas pantallas y datos simulados,
qué paquetes usarías y el orden de construcción en entregas pequeñas
que pueda probar en mi Android. No programes hasta que apruebe el plan.
```

## Después

- Pide una entrega a la vez y pruébala en tu teléfono antes de seguir.
- Al terminar cada entrega: «Haz commit de esta entrega y súbela a GitHub».
- Si algo no se parece al diseño, señala la captura: «compárala con `diseno/capturas/S04-Main.png`».

## Cuando vuelvas a Claude chat

Para análisis, diseño o mockups, vuelve a Claude chat. Antes, haz commit de lo que tengas; Claude chat escribirá en `docs/` y `diseno/`, y después haces otro commit con esos cambios.
