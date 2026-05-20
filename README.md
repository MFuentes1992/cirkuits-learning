# Cirkuits Learning - iOS Metal Game

A speech-recognition word-matching game for iOS using Metal GPU rendering.

## Documentation

This codebase includes comprehensive documentation:

### 1. **CODEBASE_ANALYSIS.md** (Main Reference)
   - **Purpose**: Complete technical breakdown of every file and component
   - **Contents**:
     - Project overview and folder structure
     - Every class, struct, protocol, enum explained
     - Game loop logic and flow
     - Word rendering pipeline
     - Speech recognition integration
     - HUD and UI elements
     - Shader details
     - Known issues and TODOs
     - File responsibility table
   - **Use When**: You need to understand how a specific component works

### 2. **QUICK_REFERENCE.md** (Developer Cheat Sheet)
   - **Purpose**: Quick lookup for common tasks and patterns
   - **Contents**:
     - Entry points and game start flow
     - Key data structures
     - Game loop flow
     - Speech recognition flow
     - Rendering pipeline
     - Combo/streak system
     - UI button actions
     - File dependency graph
     - Important functions
     - Configuration customization
     - Common modifications
     - Debugging tips
   - **Use When**: You need a quick answer or want to modify something

### 3. **ARCHITECTURE_OVERVIEW.md** (System Design)
   - **Purpose**: High-level architecture and design patterns
   - **Contents**:
     - Architectural layers (UI, Core, Logic, Input, Rendering, Data)
     - Data flow diagrams
     - State machine
     - Game loop sequence
     - Component interactions
     - Rendering pipeline architecture
     - Class responsibilities
     - Design patterns used
     - Performance characteristics
     - Extension points
     - Testing strategy
   - **Use When**: You need to understand overall system design or add new features

---

## Quick Start

### Running the Project:
1. Open `cirkuits-learning.xcodeproj` in Xcode
2. Select a device or simulator (requires Metal support)
3. Build and run (Cmd+R)

### First Game:
1. Tap "Play" button
2. Wait for 3-second countdown
3. Speak the word displayed on screen
4. Score increases on correct match
5. Game ends after 59 seconds

---

## Architecture at a Glance

```
User Input (Speech + Gestures)
           ↓
SpeechRecognizer → GameState
                       ↓
                    ↙─────────╲
                   /          \
           IgniterScene    HudController
          (Game Logic)     (UI Updates)
                   \          /
                    ╲─────────╱
                        ↓
                  WordRenderer
                        ↓
                  Metal GPU Rendering
```

---

## Key Components

| Component | Purpose | Location |
|-----------|---------|----------|
| **ViewController** | MTKView setup | ViewController.swift |
| **Renderer** | Main render loop | Renderer.swift |
| **GameState** | Central state | Repository/GameState.swift |
| **IgniterScene** | Game logic | Scenes/IgniterScene.swift |
| **WordRenderer** | 3D text rendering | Components/WordRenderer.swift |
| **SpeechRecognizer** | Voice input | Structs/SpeechRecognizer.swift |
| **HudController** | UI management | Structs/HudController.swift |

---

## Game Flow

1. **Stop State** → Player taps Play button
2. **Initializing** → 3-second countdown
3. **Running** → Main game loop
   - Word displays on screen
   - Player speaks the word
   - Game compares speech with word
   - On match: score increases, move to next word
   - On timeout/mismatch: reset combo, move to next word
4. **Stop State** → Game ends (59 seconds or timeout)

---

## Scoring System

- **Base**: 1 point per correct answer
- **Combo**: Every 4 correct answers = 50% score multiplier
- **Streak**: Visual gauge shows combo level (0-3)

---

## Known Issues

See **CODEBASE_ANALYSIS.md** for complete list:
- Timer continues after game ends (TODO)
- Speech recognition may update on partial results
- Several unused features (camera movement, pause)
- Multiple dead code files (MenuScene, TextureScene)

---

## Configuration

### Game Duration:
Edit in `Scenes/SceneManager.swift`:
```swift
LevelConfig(..., levelDuration: 59, ...)
```

### Word Display Time:
```swift
LevelConfig(timeToLive: 2.0, ...)
```

### Player Response Time:
```swift
LevelConfig(timeToAnswer: 2.0, ...)
```

### Camera Position:
Edit in `Scenes/IgniterScene.swift`:
```swift
eye: SIMD3<Float>(0, 0, 100)  // Adjust Z to move camera
```

---

## Adding Content

### Add a Word:
1. Open `Scenes/IgniterScene.swift`
2. Find `wordBank` property
3. Add string: `"newword"`

### Add a Level:
1. Create new Scene class implementing `SceneProtocol`
2. Add to `SceneManager.scenes` dictionary
3. Call `sceneManager.setCurrentScene(sceneName: "MyLevel")`

---

## Files Overview

### Entry Points:
- `ViewController.swift` - App UI setup
- `Renderer.swift` - Main render loop

### Game Logic:
- `Repository/GameState.swift` - All game data
- `Scenes/IgniterScene.swift` - Main game loop
- `Structs/SpeechRecognizer.swift` - Voice input

### Rendering:
- `Components/WordRenderer.swift` - Text rendering
- `Components/WordLayoutManager.swift` - Letter positioning
- `Components/Letter.swift` - Single letter loading
- `Shaders/Shader_Obj.metal` - GPU shaders

### UI:
- `Structs/HudController.swift` - HUD management
- `Structs/ComboGauge.swift` - Combo visualization

### Config:
- `Structs/LevelConfig.swift` - Level parameters
- `Structs/WordLayoutConfig.swift` - Layout parameters

### Utilities:
- `Utils/TimeController.swift` - Frame timing
- `Utils/ObjLoader.swift` - 3D model loading
- `Utils/CameraUtils.swift` - Matrix math
- `Extensions/Extensions.swift` - Helper functions

---

## Development Notes

### Metal Rendering:
- Uses instance drawing (one draw call per letter)
- Simple Blinn-Phong lighting in fragment shader
- Uniforms uploaded per letter

### Speech Recognition:
- Async callback from Speech Framework
- Partial results during speaking
- Updates GameState.CapturedAnswer in real-time

### Game Loop:
- 60 FPS target (MTKView standard)
- Frame delta approximated as Int (0 or 1 second)
- Simple timer-based game logic

### Performance:
- GPU: ~10-20 draw calls per frame
- CPU: < 2ms per frame
- Memory: ~10-20 MB active

---

## Testing Checklist

- [ ] Speech recognition captures voice
- [ ] Word comparison works (case-insensitive)
- [ ] Score increments correctly
- [ ] Combo gauge updates visually
- [ ] Timer counts down
- [ ] Game ends at 59 seconds
- [ ] Buttons respond to touch
- [ ] Microphone mute/unmute works

---

## References

For detailed information, see:
- **CODEBASE_ANALYSIS.md** - Component details
- **QUICK_REFERENCE.md** - Code snippets and modifications
- **ARCHITECTURE_OVERVIEW.md** - System design

---

## License

Private project for Cirkuits Learning

---

## Contact

Marco Fuentes Jiménez

---

**Last Updated**: March 2025
**Codebase Version**: 1.0
**Total Files**: 38 Swift files + 3 Metal shaders + assets
**Lines of Code**: ~2500 (excluding comments)

