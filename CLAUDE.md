# Cirkuits Learning

iOS educational word game — players see 3D-rendered words and respond via speech recognition. Tracks scores, combos, and streaks.

## Tech Stack

- Swift / Metal (GPU rendering) / iOS Speech Framework (voice input)
- UIKit, no external dependencies — pure Apple frameworks
- ~2,600 lines of Swift, Xcode build system, iOS 13+

## Architecture

Layered architecture with clear separation:

| Layer | Key Files |
|---|---|
| Entry | `AppDelegate` → `SceneDelegate` → `ViewController` → `Renderer` |
| Scene Management | `SceneManager` orchestrates `CountDownScene` → `IgniterScene` → `GameOverScene` |
| Game Logic | `IgniterScene` — core game loop, scoring, word cycling, state machine |
| State | `GameState` (Repository/) — single source of truth |
| Input | `SpeechRecognizer` (Structs/) — async speech-to-text |
| Rendering | `WordRenderer` → `WordLayoutManager` → `Letter` → Metal shaders |
| UI/HUD | `HudController`, `ComboGauge` (Structs/) |

## Directory Layout

- `Scenes/` — Game scenes implementing `SceneProtocol`
- `Components/` — Rendering: `WordRenderer`, `WordLayoutManager`, `Letter`, `Camera`
- `Repository/` — `GameState` central state container
- `Structs/` — Data structures, speech recognizer, HUD, configs
- `Protocols/` — `SceneProtocol`, `CameraProtocol`, `Renderable`
- `Enums/` — `GameEnums` (PlayState, MicrophoneState, GameScenes)
- `Utils/` — `ObjLoader`, `TimeController`, `CameraUtils`
- `Shaders/` — Metal shaders (`Shader_Obj.metal` is the active one)
- `3DAssets.xcassets/` — 26 OBJ letter models (a-z)

## Game Flow

1. CountDown (3s) → IgniterScene (timed game) → GameOver
2. State machine: `STOP → INITIALIZING → RUNNING → PAUSE → STOP`
3. Each frame at 60fps: display word → capture speech → compare → update score/combo
4. Words cycle every ~2s; every 4 correct answers triggers 1.5x combo multiplier

## Key Patterns

- Protocol-based scenes (`SceneProtocol`)
- Metal render loop via `Renderer.draw(in:)` (MTKViewDelegate)
- Blinn-Phong lighting in `Shader_Obj.metal`
- OBJ model loading via custom `ObjLoader`
- Async/await speech recognition with closure callbacks
- `GameState` passed to all components (not a true singleton)

## Conventions

- All source files live under `cirkuits-learning/`
- No package manager (no SPM, CocoaPods, etc.)
- Permissions: microphone + speech recognition (declared in Info.plist)
