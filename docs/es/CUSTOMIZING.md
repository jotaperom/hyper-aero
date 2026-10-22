# Personalizar

[← Volver al README](../../README.es.md) · [English](../en/CUSTOMIZING.md)

## La regla de oro: `user.lua`

Poné tus cambios de Hyprland en **`~/.config/hypr/user.lua`** (`SUPER + F12` lo abre). Se carga de último, así que le gana a todo lo demás, y **el instalador nunca lo sobrescribe** cuando actualizás. Los cambios hechos directamente en `hyprland.lua` se pierden con el próximo `./install.sh`.

Después de guardar, aplicalo con `hyprctl reload`. Si algo se rompe, `hyprctl configerrors` te dice la línea.

### Ejemplos

```lua
hl.config({
    general = { gaps_in = 4, gaps_out = 8 },
    decoration = { rounding = 8 },
    input = { kb_layout = "es", natural_scroll = true, touchpad = { natural_scroll = true } },
})
```

### Atajos

Agregá atajos nuevos en `user.lua`:

```lua
hl.bind("SUPER + O", hl.dsp.exec_cmd("obsidian"))
hl.bind("SUPER + SHIFT + Return", hl.dsp.exec_cmd("kitty --class aero-float"))
```

Usá una combinación que no esté ocupada (ver [Atajos](KEYBINDS.md)).

### Apps al iniciar

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("nextcloud --background")
end)
```

## Navegador y administrador de archivos

El instalador los detecta. Para cambiarlos después, corré `./install.sh` otra vez (conserva tus notas, temas, acomodo y `user.lua`), o poné tus propios atajos en `user.lua`.

## Temas y colores

- `SUPER + G`: carrusel de temas.
- **Estudio de temas**: abrilo desde el lanzador (`SUPER + R`). Ahí podés:
  - elegir cualquier color de acento;
  - tomar una imagen tuya y convertirla en fondo animado, sumando capas (burbujas, ondas, destellos, bokeh, rayos, cáusticas, pétalos, estrellas, destello de lente, cuadrícula) con su cantidad y velocidad;
  - guardar el resultado como tema propio, que después aparece en el carrusel.

Tus temas viven en `~/.config/hyper-aero/studio/themes.json`; tus fondos en `~/.config/hyper-aero/wallpapers/`.

## Ubicación (día / noche y clima)

El ciclo día/noche usa tu latitud y longitud:

```bash
aero-location 19.43 -99.13
```

(Buscá «coordenadas de *tu ciudad*» para encontrarlas. Sur y oeste son negativos.)

Los widgets de clima usan la ciudad que esté en `~/.config/hyper-aero/weather-location`. Dejalo vacío para que wttr.in la adivine por tu conexión:

```bash
echo "Ciudad de México" > ~/.config/hyper-aero/weather-location
```

## Perfil de rendimiento

`SUPER + F2` o `aero-profile ligero|equilibrado|completo`. Ver [Rendimiento](PERFORMANCE.md).

El perfil escribe `~/.config/hypr/aero-profile.lua` (desenfoque, sombras, animaciones). Lo que pongás en `user.lua` igual le gana.

## Piel del teléfono

`SUPER + X` → **PIEL**. Ocho pieles; la elección queda en `~/.config/hyper-aero/phone-skin`.

## Escritorio

- `SUPER + ALT + D` abre el editor: agregá widgets desde la bandeja, arrastralos en la cuadrícula y cambiales el tamaño desde la esquina.
- Clic derecho sobre un widget para ver sus opciones.
- El acomodo se guarda en `~/.config/hyper-aero/desk/layout.json`.

## Terminal

- `CTRL + SHIFT + A`, luego `M` / `L`: más o menos transparencia.
- Poné `AERO_NO_BANNER=1` en la configuración de tu shell para ocultar el banner de inicio.
- El prompt es [Starship](https://starship.rs): `~/.config/starship.toml`.

## Pantallas

`SUPER + P` cubre casi todo. El panel escribe sus reglas en `~/.config/hypr/aero-displays.lua`; no edités ese archivo, se vuelve a generar.

## Mapa de archivos

| Ruta | Qué es |
|---|---|
| `~/.config/hypr/hyprland.lua` | Configuración principal de Hyprland (se sobrescribe al actualizar) |
| `~/.config/hypr/user.lua` | **Tus** cambios (se conservan) |
| `~/.config/hyper-aero/scripts/` | Todos los scripts de ayuda |
| `~/.config/hyper-aero/theme/` | Archivos de tema para cada modo y acento |
| `~/.config/hyper-aero/wallpapers/` | Fondos |
| `~/.config/quickshell/aero-*` | Teléfono, escritorio, estudio, carrusel, pantallas, transiciones |
| `~/.config/eww/` | TELEMETRY HUD |
| `~/.config/waybar/` | Barra |
| `~/.local/share/hyper-aero/` | Registros de instalación y respaldos |
