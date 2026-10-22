# Rendimiento y requisitos

[← Volver al README](../../README.es.md) · [English](../en/PERFORMANCE.md)

## Requisitos

|  | Mínimo | Recomendado |
|---|---|---|
| Sistema | Arch Linux o basada en Arch (`pacman`) | Arch Linux al día |
| Hyprland | 0.56 (configuración en Lua) | la más reciente |
| CPU | 4 hilos, x86_64 | 8 hilos o más |
| RAM | 8 GB | 16 GB |
| GPU | cualquiera con drivers de Wayland funcionando | gráficos integrados Intel/AMD recientes, o una GPU dedicada |
| Disco | 1 GB libre | 2 GB libres |
| Pantalla | 1366 × 768 (algunos paneles quedan justos) | 1920 × 1080 o más |
| Perfil | *Ligero* | *Equilibrado* o *Completo* |

Notas:

- **NVIDIA como única GPU** funciona con el driver propietario o el abierto, pero Hyprland en NVIDIA necesita configuración extra: ver la [wiki de Hyprland](https://wiki.hypr.land/Nvidia/).
- **Máquinas virtuales** sin aceleración 3D no están soportadas: el desenfoque y el fondo animado pasan a dibujarse con la CPU y todo se pone muy lento.
- Con **batería**, el fondo animado se pausa solo por debajo del 50 %.

## En qué se van los recursos

Medido en la laptop del autor (CPU de laptop de 12 hilos, gráficos Intel integrados, 1080p a 144 Hz) con todo encendido, antes de las optimizaciones de esta versión. El `%CPU` es por núcleo, como lo muestra `top`.

| Componente | CPU | Qué es |
|---|---|---|
| Hyprland | 8–15 % | Desenfoque, sombras, brillo y animaciones |
| mpvpaper | 5–10 % | Decodificar el video del fondo animado |
| Escritorio (Quickshell) | 2.5–5 % | Widgets |
| cava | 2.5–5 % | Visualizador de audio |
| Todo el escritorio | ~2 GB de RAM | Incluyendo todos los servicios en segundo plano |

Los perfiles de abajo atacan justamente esos costos.

## Perfiles

Cambialo cuando querás con `SUPER + F2`, o desde la terminal:

```bash
aero-profile               # ver el perfil actual
aero-profile list
aero-profile ligero        # o: equilibrado, completo
```

El cambio se aplica al instante, sin cerrar sesión.

|  | Completo | Equilibrado | Ligero |
|---|---|---|---|
| Fondo | animado | animado | imagen fija |
| El fondo se pausa cuando | hay una ventana en pantalla completa | las ventanas tapan la pantalla | — |
| Desenfoque | fuerte (3 pasadas) | medio (2 pasadas) | suave (1 pasada) |
| Sombras | grandes | pequeñas | apagadas |
| Brillo de ventana | sí | no | no |
| Borde animado | sí | no | no |
| Ventanas inactivas | algo transparentes | casi opacas | opacas |
| Animación de escritorios | deslizar + desvanecer | deslizar + desvanecer | desvanecer |
| Visualizador | 24 fps | 15 fps | apagado |
| Refresco de widgets | 30 fps | 20 fps | 12 fps |
| Transición de tema / día-noche | sí | sí | no |
| Teléfono y transiciones en memoria | sí | sí | no (se abren cuando los pedís) |
| Recomendado para | 8+ hilos, GPU dedicada o integrada potente | la mayoría de compus | 4 hilos, 8 GB, GPUs viejas, batería |

Qué significa «en memoria»: en *Completo* y *Equilibrado* el teléfono NEXUS y la capa de transiciones se quedan cargados para aparecer al instante. En *Ligero* arrancan cuando los abrís (tardan un poquito) y si no, no usan memoria.

## Cosas que siempre ayudan

- El **fondo animado también se pausa con batería** por debajo del 50 %, y mientras corre el protector de pantalla.
- `SUPER + SHIFT + D` pausa el fondo a mano; queda pausado hasta que lo volvás a presionar.
- El **visualizador** solo corre mientras suena música.
- Quitá los widgets que no usés (`SUPER + ALT + D`). **LYRICS**, **GIF** y **SPECTRA** son los más pesados.
- `SUPER + D` oculta todo el escritorio.
- En una **laptop con dos GPUs**, la integrada maneja la pantalla de la laptop; la dedicada solo se usa con un monitor externo conectado a ella.

## Revisarlo vos

```bash
top -o %CPU
```

Buscá `Hyprland`, `mpvpaper`, `qs`, `eww` y `cava`. Si alguno se queda alto con el escritorio sin usar, mirá [Solución de problemas](TROUBLESHOOTING.md#se-siente-lento).
