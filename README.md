# 🌌 Neon Catcher

![Engine](https://img.shields.io/badge/Godot-4.6-blue?logo=godotengine&style=flat)
![Platform](https://img.shields.io/badge/Web-HTML5-brightgreen)
![Renderer](https://img.shields.io/badge/Renderer-Compatibility-lightgrey)
![Threads](https://img.shields.io/badge/Threads-Single-orange)
[![GitHub Pages](https://img.shields.io/badge/Play-Live-ff69b4)](https://fuheshka.github.io/Neon-Catcher/)

Neon arcade catcher with dynamic difficulty, combo system, online leaderboards. Tuned for GitHub Pages, single-threaded HTML5 export.

## TL;DR
- Godot 4.6, Compatibility renderer, threads off.
- Catch falling objects, avoid damage, build combos, climb leaderboards.
- Progressive difficulty scaling; neon trail FX; hit-stop feedback.
- Start overlay unlocks audio (web policy); UI recenters on resize; glow auto-disables on low FPS.
- Web build lives in `web_build/`; preset name: `Web`.

## Run
1) Open `project.godot` in Godot 4.6.
2) Main scene: [scenes/main_menu.tscn](scenes/main_menu.tscn).
3) Controls: A/D or arrows; mouse/touch drag horizontally.

## 🎮 Core Gameplay
- **Player:** Horizontal paddle with neon trail. [scripts/player.gd](scripts/player.gd)
  - Speed: 550px/s; tilt on movement; touch drag + keyboard support.
  - Trail: 15-point Line2D, HDR glow, decays when idle.
- **Spawner:** Lane-based wave system. [scripts/spawner.gd](scripts/spawner.gd)
  - 4 lanes; vertical buffer (150px); 1-2 objects per wave.
  - Y jitter for organic feel; weighted random selection.
- **Objects:** [scripts/falling_object.gd](scripts/falling_object.gd)
  - Regular (green): +10 score
  - Bonus (gold): +50 score, +0.25 combo
  - Enemy (red): -1 health

## 📈 Systems

### Difficulty Scaling
[scripts/game_manager.gd](scripts/game_manager.gd#L8-L35)
- Increases every 100 points (+5% speed, caps at 2.0x).
- Penalty on damage (-0.5x), recovers gradually (+0.05/sec).
- Spawner responds to difficulty events.

### Combo System
- Multiplier: +0.25 per bonus catch (max 10.0x).
- Breaks on damage or missing bonuses.
- Audio feedback: [assets/sounds/](assets/sounds/)

### Leaderboards
**Local:** Top 10, JSON persistence. [scripts/LeaderboardManager.gd](scripts/LeaderboardManager.gd)
**Online:** SilentWolf integration. [scripts/OnlineLeaderboard.gd](scripts/OnlineLeaderboard.gd)
- Player profile system with unique IDs.
- Score deduplication (highest score per player).
- Mobile: JavaScriptBridge prompt for nickname entry. [scripts/RegistrationScreen.gd](scripts/RegistrationScreen.gd#L98-L122)

## 🎨 Visual & Audio

### Effects
- **Hit-stop:** 80ms freeze on damage. [scripts/game_manager.gd](scripts/game_manager.gd#L33-L35)
- **Flash:** Red screen flash on hit (0.75 opacity, 0.12s fade).
- **Glow:** WorldEnvironment with auto-disable on low FPS (<45fps).
- **Camera shake:** On game over. [scripts/CameraManager.gd](scripts/CameraManager.gd)

### Audio
- **Music:** Looping track with ducking during SFX. [scripts/MusicManager.gd](scripts/MusicManager.gd)
- **SFX:** Score, hurt, combo_up, combo_break, gameover. [assets/sounds/](assets/sounds/)
- Autoload managers: [scripts/AudioManager.gd](scripts/AudioManager.gd)

## 🌐 Web Specifics
- **Start overlay:** [scenes/ui.tscn](scenes/ui.tscn#L58-L102) (StartOverlay).
  - Required for audio unlock (browser policy).
- **Web helper:** [scripts/WebHelper.gd](scripts/WebHelper.gd) → emits `start_game_requested`.
- **Mobile keyboard:** JavaScript `prompt()` fallback via JavaScriptBridge.
- **Canvas:** KEEP + VIEWPORT; glow disabled on slow devices.
- **COI headers:** [web_build/coi-serviceworker.js](web_build/coi-serviceworker.js) for SharedArrayBuffer.

## 🚀 Export
- Preset `Web` in [export_presets.cfg](export_presets.cfg) → `web_build/index.html`.
- Threads disabled; canvas resize policy = 2.
- Embedded PCK; GDScript encryption optional.
- Head CSS (dark, no borders):
  ```html
  <style>
  html, body { margin:0; padding:0; background:#050814; overflow:hidden; }
  canvas { display:block; margin:0 auto; background:#050814; }
  </style>
  ```

## ⚙️ Configuration

### API Keys (SilentWolf)
- **Dev:** Replace placeholders in [scripts/config.gd](scripts/config.gd) (don't commit).
- **Prod:** GitHub Secrets (`SILENTWOLF_API_KEY`, `SILENTWOLF_GAME_ID`).
- Guide: [SECURE_API_SETUP.md](SECURE_API_SETUP.md)

### Project Settings
- Viewport: 540x960 (portrait mobile-first).
- Stretch mode: `canvas_items`.
- Autoloads: Config, SilentWolf, LeaderboardManager, OnlineLeaderboard, Events, Audio/Music Managers, WebReady.

## 🔄 CI/CD
- Workflow: [.github/workflows/deploy.yml](.github/workflows/deploy.yml)
- Trigger: Push to `main` or manual.
- Steps: Inject secrets → export via `firebelley/godot-export@v5.2.1` → publish `web_build` to Pages.
- Setup guide: [SECURE_API_SETUP.md](SECURE_API_SETUP.md#L37-L80)

## 📱 Mobile Support
- **Touch controls:** Horizontal drag on player. [scripts/player.gd](scripts/player.gd#L100-L130)
- **Virtual keyboard:** "Tap to Type" button triggers browser prompt. [scripts/RegistrationScreen.gd](scripts/RegistrationScreen.gd#L98-L122)
- **Responsive UI:** Anchors preset for all screen sizes.

## 📦 Project Structure
```
scenes/          - UI, game objects, main loop
scripts/         - GDScript logic (managers, player, spawner)
assets/          - Fonts, grid texture, sounds/
addons/          - SilentWolf, AssetPlus plugins
web_build/       - HTML5 export target
```

## 📚 Documentation
- [LEADERBOARD_IMPLEMENTATION.md](documentation/LEADERBOARD_IMPLEMENTATION.md) - Full leaderboard system breakdown
- [SECURE_API_SETUP.md](documentation/SECURE_API_SETUP.md) - SilentWolf credentials management
- [API_KEYS_SETUP.md](documentation/API_KEYS_SETUP.md) - Legacy setup reference
- [SILENTWOLF_SETUP.md](documentation/SILENTWOLF_SETUP.md) - Backend configuration

## 🎯 Key Features
- ✅ Adaptive difficulty (scales with score + damage penalty)
- ✅ Combo multiplier system (max 10x)
- ✅ Dual leaderboards (local + online)
- ✅ Player profile persistence (unique IDs)
- ✅ Mobile-first design (touch + virtual keyboard)
- ✅ Visual polish (trails, hit-stop, camera shake, glow)
- ✅ Audio system (music + SFX with ducking)
- ✅ Web-optimized (single-thread, FPS-aware glow)
- ✅ Secure API key injection (CI/CD)
- ✅ GitHub Pages deployment

## 👤 Author
Daniil Kuviko

