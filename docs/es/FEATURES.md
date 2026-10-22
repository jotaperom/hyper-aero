# Funciones

[← Volver al README](../../README.es.md) · [English](../en/FEATURES.md)

## Temas y fondos

![Fondos](../../assets/screenshots/wallpapers.jpg)

- **Cuatro temas incluidos**, cada uno con su fondo animado:
  - **Azul**: cielo sobre colinas verdes, burbujas y ondas de luz.
  - **Rojo**: atardecer coral sobre el mar, luces bokeh.
  - **Verde**: laguna submarina, cáusticas y rayos de luz.
  - **Negro**: ondas de cromo; plateado de día, una cuadrícula oscura de noche.
- **Versión de día y de noche** de cada tema. Todo el escritorio (barra, HUD, teléfono, terminal, notificaciones, apps GTK, rofi) sigue el modo.
- **Estudio de temas** (desde el lanzador de apps o el teléfono):
  - Elegí cualquier color de acento; todos los componentes se vuelven a teñir.
  - Convertí cualquier imagen tuya en un fondo animado con capas: burbujas, ondas, destellos, bokeh, rayos de luz, cáusticas, pétalos, estrellas, destello de lente y cuadrícula.
  - Guardá tus propios temas. La vista previa muestra tu fondo elegido en todas las pestañas.
- **Carrusel de temas** (`SUPER + G`): deslizá o usá las flechas para cambiar de tema; el fondo cambia junto con el tema.
- **Transiciones de vidrio** al cambiar de tema o de modo día/noche (apagadas en el perfil *Ligero*).

## Día / noche: NIGHT DECK

- Automático por defecto: cambia con la salida y la puesta del sol de tu zona.
- `SUPER + T`: cambiar a mano; se queda así hasta la próxima salida o puesta del sol, y luego vuelve el modo automático.
- `SUPER + ALT + T`: cancelar el cambio manual y volver a automático.
- `SUPER + SHIFT + T`: luz cálida (filtro de luz azul con `hyprsunset`).
- La ubicación se configura al instalar. Para cambiarla: `aero-location LAT LON` (ver [Personalizar](CUSTOMIZING.md)).

## Teléfono NEXUS

Un centro de control con forma de teléfono que entra desde el costado.

| Teclas | Página |
|---|---|
| `SUPER + R` | Apps (buscar, favoritas, ejecutar comandos, cambiar de ventana; `CTRL + TAB` pasa entre ellas) |
| `SUPER + X` | Control: volumen, brillo, Wi-Fi, Bluetooth, modo noche, luz cálida, no molestar, apagar |
| `SUPER + W` | Wi-Fi |
| `SUPER + A` | Bluetooth |
| `SUPER + I` | Hoy: reloj, saludo, clima, minicalendario, reproductor, nota rápida |

Ocho pieles (iPhone, flip, Aqua, visor, slider, holo, PDA, orbit): abrí la página de control (`SUPER + X`) y tocá **PIEL**. El botón **TEMAS** de ahí abre el carrusel de temas.

## Widgets de escritorio

`SUPER + D` muestra u oculta los widgets; `SUPER + ALT + D` abre la cuadrícula de edición. Clic derecho sobre un widget para ver su menú.

| Widget | Qué hace |
|---|---|
| CHRONO | Reloj y fecha |
| PULSE-X | Reproductor (cualquier reproductor MPRIS: Spotify, navegadores, mpv…) |
| SKY ARC | Posición del sol y la luna en tu ubicación |
| ATMOS | Clima (wttr.in) |
| SYSTEM | CPU, RAM y disco |
| TASKS | Lista de pendientes |
| CALENDAR | Mes actual |
| NOTES | Nota rápida |
| SPECTRA | Visualizador de audio (cava) |
| PILOT | Tu tarjeta de usuario |
| DOCK | Accesos directos a apps |
| LYRICS | Letra sincronizada de la canción que suena (lrclib.net) |
| GIF | Cualquier imagen animada |

Arrastrá una ventana con `SUPER + clic izquierdo` hasta el borde de la pantalla para mandarla a otro escritorio.

## TELEMETRY HUD

Un panel de eww con CPU (carga, frecuencia, temperatura), GPU integrada y dedicada (si hay), RAM, disco, batería, red y tiempo encendido. `SUPER + H` alterna entre completo y delgado.

## Pantallas: `SUPER + P`

Un panel como el de Windows:

- **Solo laptop**, **Duplicar**, **Extender**, **Solo monitor**.
- Arrastrá las pantallas para que coincidan con dónde están físicamente.
- Al conectar o desconectar un monitor, cambia solo.
- **Tamaño en la laptop** y **tamaño en el monitor**: de 100 % a 200 % para cada pantalla.

## Herramientas de todos los días

- **AEROBAR** (Waybar): escritorios, reloj, música, red, Bluetooth, batería. `SUPER + SHIFT + B` la oculta.
- **SIGNAL** (swaync): centro de notificaciones, `SUPER + N`; no molestar, `SUPER + SHIFT + N`.
- **AIRLOCK** (hyprlock): pantalla de bloqueo, `SUPER + L`.
- **Protector de pantalla** a los 2 minutos sin uso, baja el brillo a los 4 y bloquea a los 5 (hypridle).
- **ALT + TAB** con vistas previas de las ventanas; **SUPER + TAB** vista de escritorios.
- **Capturas** en `~/Imágenes/Capturas` (o tu carpeta de imágenes): región `SUPER + SHIFT + S`, pantalla `Impr`, ventana `SUPER + Impr`.
- **Grabación de pantalla** (wf-recorder): `SUPER + ALT + R` pantalla completa, `SUPER + ALT + SHIFT + R` región; repetí para detener.
- **Terminal DECK** (kitty) con un banner de inicio y un prompt de Starship a juego.
- **Indicador en pantalla** para las teclas de volumen y brillo.

## Opcional

- **Pantalla de inicio de sesión** (greetd + ReGreet) con el mismo estilo, en versión de día y de noche: `./install.sh --with-login`.
- **Sesión para dos tarjetas gráficas**: para laptops cuyo puerto HDMI está conectado a la GPU dedicada. Agrega una sesión *HYPER·AERO* que permite a Hyprland usarla cuando conectás un monitor externo: `./install.sh --with-gpu-session`.
