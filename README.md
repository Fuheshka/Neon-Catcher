# 🌌 Cyber-Catcher

![Engine](https://img.shields.io/badge/Godot-4.6-blue?logo=godotengine&style=flat)
![Platform](https://img.shields.io/badge/Web-HTML5-brightgreen)
![Renderer](https://img.shields.io/badge/Renderer-Compatibility-lightgrey)
![Threads](https://img.shields.io/badge/Threads-Single-orange)

Neon arcade catcher tuned for GitHub Pages, single-threaded HTML5 export.

## TL;DR
- Godot 4.6, Compatibility renderer, threads off.
- Start overlay unlocks audio (web policy); UI recenters on resize; glow auto-disables on low FPS.
- Web build lives in `web_build/`; preset name: `Web`.

## Run
1) Open `project.godot` in Godot 4.6.
2) Main scene: [scenes/main_menu.tscn](scenes/main_menu.tscn).
3) Controls: A/D or arrows; mouse/touch drag horizontally.

## Web Bits
- Start overlay: [scenes/ui.tscn](scenes/ui.tscn#L58-L102) (StartOverlay).
- Web manager: [scripts/WebHelper.gd](scripts/WebHelper.gd) → emits `start_game_requested`.
- Canvas: KEEP + VIEWPORT; glow may be disabled on slow browsers.

## Export
- Preset `Web` in [export_presets.cfg](export_presets.cfg) → `web_build/index.html`.
- Threads disabled; canvas resize policy = 2.
- Optional head CSS (dark, no borders):
  ```html
  <style>
  html, body { margin:0; padding:0; background:#050814; overflow:hidden; }
  canvas { display:block; margin:0 auto; background:#050814; }
  </style>
  ```

## CI/CD
- Workflow: [scripts/.github/workflows/deploy.yml](scripts/.github/workflows/deploy.yml)
- On push to `main` or manual; exports via `firebelley/godot-export@v5.2.1`, publishes `web_build` to Pages.

## Author
- Daniil Kuviko

