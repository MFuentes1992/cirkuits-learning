# Cirkuits Learning - Architecture Overview

## HIGH-LEVEL DESIGN

This is a **speech-recognition word-matching game** for iOS using Metal (GPU) rendering.

### Core Concept:
- Player sees a word rendered in 3D
- Player speaks the word aloud
- Game checks if speech matches current word
- On match: score increases, move to next word
- On timeout/mismatch: reset combo, move to next word

### Target Platform:
- iOS 13+
- Metal GPU support required
- Microphone + Speech framework required

---

## ARCHITECTURAL LAYERS

### 1. UI Layer (ViewController + HudController)
- **ViewController**: UIViewController managing MTKView
- **HudController**: UIKit-based HUD (buttons, labels, combo gauge)
- **ComboGauge**: Custom UIView for combo visualization

**Responsibilities:**
- Capture user gestures
- Render UI elements
- Start/pause/mute controls

### 2. Application Core (Renderer)
- Manages render loop
- Coordinates between game logic and rendering
- Updates timers each frame
- Calls HudController to refresh UI

**Responsibilities:**
- Frame timing
- Command buffer creation & encoding
- Delegation to scene

### 3. Game Logic Layer (Scenes)
- **SceneManager**: Scene switcher, configuration loader
- **IgniterScene**: Main game loop, scoring, word cycling
- **MenuScene**: Stub for future menu
- **TextureScene**: PoC for texture rendering

**Responsibilities:**
- Game state machine
- Scoring logic
- Word management
- Combo/streak tracking

### 4. Input Layer (SpeechRecognizer)
- Async microphone input capture
- Speech-to-text conversion (iOS framework)
- GameState updates on new transcription

**Responsibilities:**
- Audio capture
- Speech recognition
- Async callback handling

### 5. Rendering Layer (WordRenderer + Components)
- **WordRenderer**: Orchestrates letter rendering
- **WordLayoutManager**: Positions letters, handles animations
- **Letter**: Loads 3D OBJ models for characters
- **Camera**: View/projection matrices

**Responsibilities:**
- 3D geometry layout
- Matrix math
- GPU command encoding
- Metal shaders

### 6. Data Layer (GameState)
- Central game state repository
- All properties accessible as getters/setters
- Single source of truth

**Responsibilities:**
- State management only (no logic)
- Read/write access to game data

---

## DATA FLOW DIAGRAM

```
┌─────────────────────────────────────────────────────────────┐
│ iOS System (Microphone, AVAudioEngine, Speech Framework)    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
       ┌───────────────────────────────┐
       │ SpeechRecognizer              │
       │ (async callback)              │
       └─────────┬─────────────────────┘
                 │ transcription
                 ▼
       ┌───────────────────────────────┐
       │ GameState (Repository)        │
       │ CapturedAnswer                │
       │ IsAnswering                   │
       │ CorrectAnswer                 │
       │ Score, Streak                 │
       │ CurrentState                  │
       └─────────┬─────────────────────┘
                 │
       ┌─────────┴──────────────┐
       │                        │
       ▼                        ▼
┌─────────────────┐   ┌──────────────────┐
│ IgniterScene    │   │ HudController    │
│ (Game Loop)     │   │ (UI Updates)     │
│ ├─ Logic        │   │ ├─ Timer Label   │
│ ├─ Scoring      │   │ ├─ Score Label   │
│ ├─ Combo Tracking   │ ├─ Combo Gauge   │
│ └─ Word Cycling │   │ └─ Buttons       │
└────────┬────────┘   └──────────────────┘
         │
         │ render command
         ▼
   ┌─────────────────────┐
   │ WordRenderer        │
   │ ├─ Uniforms upload  │
   │ └─ Draw calls       │
   └────────┬────────────┘
            │
            ▼
   ┌────────────────────────┐
   │ WordLayoutManager      │
   │ ├─ Letter positioning  │
   │ ├─ Animation logic     │
   │ └─ Transform matrices  │
   └────────┬───────────────┘
            │
            ▼
   ┌────────────────────────┐
   │ Letter (Per Character) │
   │ ├─ Load OBJ mesh       │
   │ ├─ Store bounding box  │
   │ └─ Transform matrix    │
   └────────┬───────────────┘
            │
            ▼
   ┌────────────────────────┐
   │ ObjLoader              │
   │ ├─ Parse OBJ format    │
   │ └─ Create Metal buffers│
   └────────┬───────────────┘
            │
            ▼
   ┌────────────────────────┐
   │ Metal GPU              │
   │ ├─ Vertex Shader       │
   │ │  ├─ Position transform
   │ │  └─ Normal transform  │
   │ ├─ Fragment Shader      │
   │ │  ├─ Lighting calc     │
   │ │  └─ Color output      │
   │ └─ Frame Buffer         │
   └────────────────────────┘
```

---

## STATE MACHINE

### Game State Enum (PlayState):
```
                    ┌──────────┐
                    │   STOP   │
                    │ (Initial)│
                    └────┬─────┘
                         │ [Play Button]
                         ▼
                 ┌──────────────────┐
                 │  INITIALIZING    │
                 │ (Countdown 3s)   │
                 └────────┬─────────┘
                          │ [Timer expires]
                          ▼
               ┌────────────────────┐
               │     RUNNING        │
               │ (Active Gameplay)  │
               └────┬──────┬────────┘
                    │      │
                    │      └─[Pause Button]──┐
                    │                        │
                    │                        ▼
                    │                  ┌──────────┐
                    │                  │  PAUSE   │
                    │                  └────┬─────┘
                    │                       │ [Resume]
                    │                       └─────┐
                    │                             │
                    └─────────────┬───────────────┘
                                  │
                                  │ [Game Duration Expires]
                                  ▼
                           ┌──────────┐
                           │   STOP   │
                           │(Game Over)│
                           └──────────┘
```

---

## GAME LOOP SEQUENCE

### Each Frame:
```
1. Renderer.draw() called by MTKView
   └─ Triggered by device display refresh (60 FPS typical)

2. TimeController.update()
   └─ Calculate frame delta

3. SceneManager.encode() → IgniterScene.encode()
   ├─ If state == .running:
   │  ├─ Accumulate wordTimeToLive
   │  ├─ Check if word timeout
   │  ├─ If isAnswering:
   │  │  ├─ Compare currentAnswer with currentWord
   │  │  ├─ If match: nextFoo(reward), streakChain++
   │  │  ├─ If timeout: nextFoo(0), streakChain=0
   │  │  └─ Update CorrectAnswer flag
   │  ├─ Apply combo multiplier
   │  ├─ Check game duration
   │  └─ Call WordRenderer.render()
   └─ Encode Metal commands

4. Metal Render Encoding
   ├─ Set pipeline state
   ├─ For each letter:
   │  ├─ Upload Uniforms (MVP matrices)
   │  ├─ Set vertex buffer
   │  └─ Draw indexed primitives
   └─ GPU executes shaders

5. HudController.updateHud()
   ├─ Update timer display
   ├─ Update score display
   ├─ Update countdown (if initializing)
   └─ Update combo gauge

6. GPU Rendering
   ├─ obj_vertex_shader: transform geometry
   ├─ obj_fragment_shader: calculate lighting
   └─ Write to frame buffer

7. Display
   └─ Present rendered frame to screen
```

---

## COMPONENT INTERACTIONS

### Word Display Pipeline:
```
IgniterScene.nextFoo()
  ↓
WordRenderer.CurrentFoo = word
  ↓
WordLayoutManager.setWord(word)
  ├─ Create Letter objects
  │  └─ Each loads OBJ from assets
  ├─ Calculate transforms
  └─ Determine animation needed
  ↓
WordRenderer.render()
  ├─ Get transforms from WordLayoutManager
  ├─ Upload to Uniforms buffer
  ├─ For each letter, draw with instance ID
  └─ GPU renders with shaders
```

### Score Update Pipeline:
```
IgniterScene detects correct answer
  ↓
streakChain += 1
score += reward
  ↓
Every 4 correct:
  score *= 1.5
  streakChain = 0
  ↓
GameState.Score = Int(score)
GameState.Streak = streakChain
  ↓
HudController.updateScoreDisplay()
  ├─ Format as "XXX"
  └─ Update label text
```

### Speech Recognition Pipeline:
```
User speaks
  ↓
Microphone → AVAudioEngine
  ↓
Speech Framework processes audio
  ↓
Recognition callback fires (async)
  ↓
SpeechRecognizer updates GameState
  GameState.CapturedAnswer = transcription
  GameState.IsAnswering = true
  ↓
IgniterScene.encode() reads GameState
  ├─ Compare answer with current word
  ├─ Update CorrectAnswer flag
  └─ Next frame handles logic
```

---

## RENDERING PIPELINE ARCHITECTURE

### Metal Setup:
```
Device: MTLDevice (GPU)
  ↓
Command Queue: MTLCommandQueue
  ├─ One queue for command buffers
  └─ Buffers executed in order
  ↓
Each Frame:
  ├─ Create MTLCommandBuffer
  ├─ Create MTLRenderCommandEncoder
  │  ├─ Set RenderPipelineState (shaders)
  │  ├─ Set vertex/index buffers
  │  ├─ Upload Uniforms to buffer[1]
  │  └─ Draw calls
  ├─ End encoding
  └─ Present to screen
```

### Letter Rendering (Instance Drawing):
```
For Word "HELLO":

Letter H:
  Uniforms[0]: Model = (position H)
  Draw 1 instance

Letter E:
  Uniforms[1]: Model = (position E)
  Draw 1 instance (baseInstance=1)

Letter L (x2):
  Uniforms[2]: Model = (position L1)
  Uniforms[3]: Model = (position L2)
  Draw 2 instances (baseInstance=2)

Letter O:
  Uniforms[4]: Model = (position O)
  Draw 1 instance (baseInstance=4)
```

**Result**: 1 vertex buffer (mesh), 5 draw calls (one per unique letter instance)

---

## CLASS RESPONSIBILITIES

### ViewController
- **Creates**: MTKView with Metal device
- **Delegates**: MTKView rendering to Renderer
- **Forwards**: Gesture events to Renderer

### Renderer
- **Manages**: Command queue, timer
- **Coordinates**: Game loop timing
- **Delegates**: Scene encoding to SceneManager
- **Updates**: HUD after each frame

### SceneManager
- **Stores**: Dictionary of scenes
- **Manages**: Scene transitions
- **Loads**: Level configuration
- **Delegates**: Encoding to current scene

### IgniterScene
- **Manages**: Game state machine logic
- **Tracks**: Word index, timers, score
- **Calculates**: Combo, multipliers
- **Delegates**: Rendering to WordRenderer
- **Maintains**: Word bank (400+ words)

### WordRenderer
- **Orchestrates**: Letter rendering
- **Manages**: Pipeline state, uniform buffers
- **Delegates**: Layout to WordLayoutManager

### WordLayoutManager
- **Positions**: Letters horizontally
- **Animates**: Long words (sliding animation)
- **Calculates**: Transform matrices
- **Manages**: Layout configuration

### Letter
- **Loads**: Single letter OBJ model
- **Stores**: Bounding box (for width calc)
- **Maintains**: Transform matrix

### SpeechRecognizer
- **Manages**: AVAudioEngine setup
- **Handles**: Audio recording
- **Processes**: Speech recognition
- **Updates**: GameState on results

### HudController
- **Creates**: UI elements (labels, buttons, gauge)
- **Updates**: Display values each frame
- **Handles**: Button actions
- **Manages**: Countdown animation

### GameState
- **Stores**: All game data
- **Provides**: Property accessors
- **No Logic**: Just data container

---

## KEY DESIGN PATTERNS

### Observer Pattern:
- GameState acts as observable
- IgniterScene, HudController observe state changes
- SpeechRecognizer updates state asynchronously

### Command Pattern:
- Renderer encodes Metal commands
- SceneManager delegates to scenes
- Each scene handles its rendering

### Factory Pattern:
- ObjLoader creates Mesh objects from OBJ strings
- WordLayoutManager creates Letter objects from characters

### MVC-ish:
- Model: GameState (data)
- View: WordRenderer + HudController (presentation)
- Controller: IgniterScene (logic)

### Singleton-ish:
- GameState instance passed around (not true singleton, but centralized)
- TimeController instance shared across components

---

## PERFORMANCE CHARACTERISTICS

### GPU Rendering:
- **Batch Size**: ~26 letter instances (A-Z)
- **Draw Calls**: ~6-8 per frame (one per letter in current word)
- **Shaders**: Simple (MVP transform, Blinn-Phong lighting)
- **Memory**: ~1-2 MB for letter meshes

### CPU Processing:
- **Game Logic**: ~0.1 ms (timer check, word comparison)
- **Layout**: ~0.5 ms (transform matrix calculations)
- **UI Updates**: ~1 ms (label text formatting)
- **Total**: < 2 ms per frame (at 60 FPS)

### Audio Processing:
- **Async Thread**: Speech recognition runs on background thread
- **No Blocking**: GameState update is lock-free
- **Callback Latency**: ~100-200 ms (network speech API)

### Memory:
- **Static**: 26 OBJ letter models (~5-10 MB)
- **Dynamic**: GameState variables (<1 KB)
- **Buffers**: Uniform buffer (~10 KB per frame)

---

## EXTENSION POINTS

### Add New Game Mode:
1. Create new Scene class implementing SceneProtocol
2. Add to SceneManager.scenes dictionary
3. Implement encode(), handlePanGesture(), handlePinchGesture()

### Add Difficulty Levels:
1. Create multiple LevelConfig variants
2. Add to SceneManager configuration
3. Load based on user selection (not yet implemented)

### Add Game Features:
- **Lives System**: Check GameState.Lives in IgniterScene
- **High Scores**: Persist GameState.HighScore to UserDefaults
- **Achievements**: Add tracking in GameState
- **Sound Effects**: Add in IgniterScene after events
- **Animations**: Add to ComboGauge or WordRenderer

### Add Rendering Effects:
- **Letter Particles**: Add in fragment shader
- **Screen Shake**: Modify camera in IgniterScene
- **Post-Processing**: Add additional render pass in Renderer
- **Camera Movement**: Implement Camera movement methods

---

## TESTING STRATEGY

### Unit Test Candidates:
- GameState property getters/setters
- WordLayoutManager positioning calculations
- ObjLoader parsing logic
- TimeController timing calculations

### Integration Test Candidates:
- Game loop (word cycling, scoring)
- Speech recognition flow
- UI button actions and state transitions
- Word comparison logic

### Manual Testing:
- Speech recognition accuracy
- UI responsiveness
- Combo gauge animation
- Word display and layout
- Score calculation multipliers

---

## DEPLOYMENT CONSIDERATIONS

### Requirements:
- iOS 13+ (Speech framework)
- Metal GPU support
- Microphone permissions
- Speech recognition permissions

### Permissions Needed:
```xml
<!-- Info.plist -->
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for voice input</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>We need speech recognition to match your answers</string>
```

### Performance Targets:
- 60 FPS on iPhone 11+
- <50 MB app size
- <20 MB memory usage during gameplay
- <2 seconds cold start time

