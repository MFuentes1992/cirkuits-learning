# Cirkuits Learning - iOS Metal Game Codebase Analysis

## PROJECT OVERVIEW
This is an iOS educational word-game built with Metal (GPU rendering). It's a speech-recognition word matching game where players hear/see words and respond via speech input.

---

## FOLDER STRUCTURE & ORGANIZATION

```
cirkuits-learning/
├── AppDelegate.swift
├── SceneDelegate.swift
├── ViewController.swift
├── Renderer.swift
├── Repository/
│   └── GameState.swift
├── Scenes/
│   ├── SceneManager.swift
│   ├── IgniterScene.swift (MAIN GAME SCENE)
│   ├── MenuScene.swift (STUB)
│   └── TextureScene.swift (POC)
├── Components/
│   ├── WordRenderer.swift
│   ├── WordLayoutManager.swift
│   ├── Letter.swift
│   └── Camera.swift
├── Structs/
│   ├── HudController.swift
│   ├── SpeechRecognizer.swift
│   ├── LevelConfig.swift
│   ├── WordLayoutConfig.swift
│   ├── WordFoo.swift
│   ├── ComboGauge.swift
│   ├── Mesh.swift
│   ├── Uniforms.swift
│   ├── Vertex.swift
│   ├── CameraSettings.swift
│   ├── OrbitCamera.swift (UNUSED)
│   ├── ParallelogramBar.swift
│   ├── ParallelogramStack.swift
│   └── Game/ (EMPTY)
├── Protocols/
│   ├── SceneProtocol.swift
│   ├── CameraProtocol.swift
│   └── Renderable.swift
├── Enums/
│   └── GameEnums.swift
├── Utils/
│   ├── TimeController.swift
│   ├── CameraUtils.swift
│   ├── Utils.swift (Pipeline helpers)
│   └── ObjLoader.swift
├── Extensions/
│   └── Extensions.swift
├── Shaders/
│   ├── Shader_Obj.metal (MAIN: Letter rendering)
│   ├── Shaders.metal (unused)
│   └── TextureShaders.metal (POC, unused)
└── 3DAssets.xcassets/
    └── *_letter.dataset/ (26 letters: a-z as OBJ models)
```

---

## DATA FLOW & ARCHITECTURE

### Application Initialization Flow:
1. **AppDelegate** → Basic app setup
2. **SceneDelegate** → Window setup (storyboard-based)
3. **ViewController** → Creates MTKView + initializes Renderer
4. **Renderer** → Creates GameState, TimeController, HudController, SceneManager

### Render Loop:
```
ViewController (MTKView delegate)
  ↓ (draw in view)
Renderer.draw(in:)
  ├─ TimeController.update() [Calculate delta]
  ├─ SceneManager.encode() [Render current scene]
  └─ HudController.updateHud() [Update UI labels]
```

### Scene Management:
- **SceneManager**: Holds dictionary of scenes, switches between them
- Currently only **IgniterScene** is active
- MenuScene & TextureScene are stubs/POCs

---

## GAME STATE MANAGEMENT (Repository/GameState.swift)

### Purpose:
Central repository for all game state. Single source of truth.

### Key Properties:
```swift
// Scoring
- score: Int
- combo: Int
- maxStreak: Int = 3
- streak: Int

// Level Configuration
- lives: Int
- levelDuration: TimeInterval
- wordTimeToLive: TimeInterval (time word stays on screen before auto-advance)
- wordTimeToAnswer: TimeInterval (time player has to answer)

// Game State
- currentState: PlayState (stop, pause, running, initializing)
- countDown: TimeInterval (countdown timer before game starts)
- timer: TimeController (reference to active timer)

// Speech Recognition Input
- capturedAnswer: String (set by SpeechRecognizer)
- isAnswering: Bool
- correctAnswer: Bool

// Configuration
- configLoaded: Bool
```

### CapturedAnswer Processing:
- Setter strips whitespace and keeps only last word
- Allows multi-word transcription but only matches final word

### Responsibilities:
- **NONE**: Just a data container
- Modified by: IgniterScene, HudController, SpeechRecognizer
- Observed by: Renderer, HudController

---

## GAME LOOP & LOGIC (Scenes/IgniterScene.swift)

### The Main Game Scene

#### Initialization:
- Builds word bank: 400+ common English words
- Creates WordFoo array (word + reward pairs)
- Initializes Camera with perspective settings
- Creates WordRenderer for 3D text rendering
- Loads LevelConfig from SceneManager

#### Game State Enum (PlayState):
```
stop       → Game over, initial state
initializing → Countdown before running (3 seconds)
running    → Active gameplay
pause      → Paused by player
```

#### Game Loop Logic (encode function):

**When NOT answering:**
- `wordTimeToLive` accumulates
- If `wordTimeToLive > gameState.WordTimeToLive` → move to next word (no reward)
- Reset streakChain to 0

**When answering (isAnswering = true):**
- If answer is CORRECT → advance word, increment streak, add reward
- If answer is WRONG after timeout → advance word, reset streak, no reward
- Accumulate `timeToAnswer`
- Compare captured answer (case-insensitive) with current word

**Score Multiplier:**
- If `streakChain == maxStreak + 1` (i.e., >= 4) → multiply score by 1.5
- Reset streak counter

**Level End:**
- When `gameElapsedTime >= levelDuration` → set state to .stop

#### Current Word Management:
- `currentFooIndex`: Cycles through word bank (0 to count)
- `nextFoo()`: Advances index, adds score reward, updates renderer
- `WordFoos`: Array of WordFoo structs

#### Data Passed to Renderer:
- `gameState.Score`
- `gameState.Streak`
- Camera matrices (view, projection)

---

## WORD RENDERING PIPELINE

### Components Involved:
1. **WordFoo** (Structs/WordFoo.swift)
   - Simple struct: `Word: String, Reward: Int`

2. **Letter** (Components/Letter.swift)
   - Loads 3D OBJ model from assets for single letter
   - Parses model to get bounding box (minX, maxX → width)
   - Stores: `mesh`, `transform`, `width`

3. **WordLayoutManager** (Components/WordLayoutManager.swift)
   - Takes word string, splits into Letter objects
   - Manages linear layout (horizontal centering)
   - Handles animation when word is too long:
     - `shouldAnimateLayout`: Toggles sliding animation
     - `createLinearTransform()`: Centers word or starts at left
     - `updateLinearTransforms()`: Animates left-right sliding with sinusoidal easing
   - Calculates transforms based on letterSpacing, letterWidth, maxLinearWidth
   - Computes total width and centers around origin

4. **WordLayoutConfig** (Structs/WordLayoutConfig.swift)
   - Configurable layout parameters:
     - `screenWidth`: Device width
     - `maxLinearWidth`: 60% of screen (default)
     - `letterSpacing`: 2.5 (units)
     - `letterWidth`: 15
     - `speed`: 1.5 (animation speed)
     - `blankSpaceWidth`: 10 (for space character)

5. **WordRenderer** (Components/WordRenderer.swift)
   - Main renderer orchestrator
   - Creates WordLayoutManager
   - Creates Metal render pipeline (obj_vertex_shader, obj_fragment_shader)
   - Sets CurrentFoo property → triggers WordLayoutManager.setWord()
   - In render():
     - Gets transform matrix from each letter
     - Packs transforms into uniform buffer
     - Renders each letter with instance drawing

### Rendering Flow:
```
IgniterScene.encode()
  ↓
WordRenderer.render()
  ├─ Gets letter transforms from WordLayoutManager
  ├─ Uploads Uniforms (projection, view, model per letter)
  ├─ For each letter:
  │  ├─ Set vertex buffer (mesh geometry)
  │  ├─ Draw indexed primitives (instance draw)
  └─ GPU executes shaders
```

### Metal Shaders Used:
- **obj_vertex_shader** (Shader_Obj.metal)
  - Input: ObjVertex (position, normal)
  - Receives Uniforms via instanceID (different per letter)
  - Computes: MVP matrix = Projection × View × Model
  - Outputs: VertexOut with position, normal, worldPosition

- **obj_fragment_shader** (Shader_Obj.metal)
  - Lighting calculation: simple diffuse + ambient
  - Base color: magenta/gold (1, 0.647, 1.0)
  - Light direction: from camera (0, 0, 100)

---

## SPEECH RECOGNITION (Structs/SpeechRecognizer.swift)

### Integration:
- Embedded in HudController (one per app)
- Sets up during app initialization
- Requests permissions asynchronously

### How It Works:
1. **startRecording()**:
   - Prepares AVAudioEngine + SFSpeechAudioBufferRecognitionRequest
   - Installs audio tap to feed input to recognizer
   - Starts background task

2. **Recognition Callback**:
   - Receives `SFSpeechRecognitionResult` as audio is processed
   - Extracts `bestTranscription.formattedString`
   - Sets `GameState.CapturedAnswer = newText` (triggers setter)
   - Sets `GameState.IsAnswering = true`
   - **Note**: Result is PARTIAL until `result.isFinal`

3. **stopTranscribing()**:
   - Cancels task, stops audio engine, clears buffers

### Data Flow:
```
Microphone (iOS)
  ↓ AVAudioEngine
Speech Framework
  ↓ recognition callback
GameState.CapturedAnswer = newText
GameState.IsAnswering = true
  ↓
IgniterScene detects answer in game loop
  ├─ Compares with current word
  ├─ Sets CorrectAnswer = true/false
  └─ Advances word if correct
```

---

## HUD & UI ELEMENTS (Structs/HudController.swift)

### HUD Components:

1. **Timer Label** (top-left)
   - Shows remaining time: MM:SS format
   - Updates during running state
   - Font: monospaced bold, white with shadow

2. **Score Label** (top-right)
   - Shows current score: XXX format (3 digits)
   - Updates every frame
   - Same styling as timer

3. **Countdown Label** (center screen)
   - Shows 3-2-1 countdown
   - Visible only during initializing state
   - Large font (42pt)
   - Hidden after countdown complete

4. **Combo/Streak Gauge** (bottom-left)
   - Custom UIView: **ComboGauge**
   - Shows parallelogram bars (0-3 max combo)
   - Bar fills when combo increases
   - Badge displays multiplier "x00" to "x03"
   - Animates on combo increase (scale pulse)

5. **Buttons** (bottom area):
   - **Play Button**: Visible at start, triggers game init
   - **Pause Button**: Pauses/resumes game (toggle icon)
   - **Microphone Button**: Mutes/unmutes audio input (toggle icon)

### HUD Update Flow:
```
updateHud() called every frame:
  ├─ If configLoaded & state==stop:
  │  └─ Initialize timers from config
  ├─ Else:
  │  ├─ updateTimerDisplay() → remaining time
  │  ├─ updateScoreDisplay() → format score
  │  ├─ updateCountDown() → countdown animation
  │  └─ If streak changed: comboGauge.incrementCombo()
```

---

## COMBO GAUGE UI (Structs/ComboGauge.swift)

### Visual Design:
- 4 parallelogram bars (one per streak level)
- Each bar: 100pt wide × 18pt tall
- 8pt spacing between bars
- Outline: 2pt white stroke
- Fill color: yellow-green (0.78, 1.0, 0)
- Glow: shadow with 8pt radius

### Badge:
- Circle: 60pt diameter
- Background: cream color
- Text: "xNN" (multiplier value)
- Shadow: 4pt blur, 0.5 opacity

### Animation:
- On combo increase: scale pulse (1.0 → 1.15 → 1.0 over 150ms)
- Updates multiplier badge text

---

## LEVEL CONFIGURATION (Structs/LevelConfig.swift)

### Current Configuration (SceneManager):
```swift
LevelConfig(
    timeToLive: 2.0,           // Word display time before auto-advance
    timeToAnswer: 2.0,         // Player answer response time
    levelDuration: 59,         // Game duration in seconds
    lives: 3,                  // Lives (unused currently)
    levelCountDown: 3          // Pre-game countdown seconds
)
```

### Data Flow:
1. SceneManager loads config when setting scene
2. Config values copied to GameState properties
3. IgniterScene reads from GameState during game loop
4. HudController reads for display/countdown

---

## CAMERA SYSTEM

### Camera Class (Components/Camera.swift):
- Implements CameraProtocol
- Stores CameraSettings (eye, center, up, FOV, aspect, near/far planes)
- Provides viewMatrix (LookAt) and projectionMatrix (Perspective)

### Current Setup (IgniterScene):
```swift
CameraSettings(
    eye: (0, 0, 100),           // Far back on Z
    center: (0, 0, 0),          // Looking at origin
    up: (0, 1, 0),              // Y is up
    fovDegrees: 60.0,
    aspectRatio: 19.5/9,        // Wide phone aspect
    nearZ: 1.0,
    farZ: 1000.0
)
```

### Unimplemented Methods:
- `move()`, `strafe()`, `pitch()`, `yaw()`, `fly()` → All empty stubs
- Gesture input (pan/pinch) captured but not applied to camera

---

## PROTOCOLS

### SceneProtocol (Protocols/SceneProtocol.swift):
```swift
protocol SceneProtocol {
    func handlePanGesture(gesture: UIPanGestureRecognizer, location: CGPoint)
    func handlePinchGesture(gesture: UIPinchGestureRecognizer)
    func encode(encoder: MTLRenderCommandEncoder, view: MTKView)
}
```
- Defines scene interface (gesture handling + encoding)

### CameraProtocol (Protocols/CameraProtocol.swift):
- Defines camera interface with view/projection matrices
- Camera movement methods (mostly unimplemented)

### Renderable (Protocols/Renderable.swift):
- Not currently used in codebase (orphaned protocol)

---

## ENUMS (Enums/GameEnums.swift)

### PlayState:
```swift
enum PlayState {
    case stop           // Game not running
    case pause          // Paused by player
    case running        // Active gameplay
    case initializing   // Countdown in progress
}
```

### MicrophoneState:
```swift
enum MicrophoneState {
    case muted
    case unmuted
}
```

---

## UTILITY FUNCTIONS

### TimeController (Utils/TimeController.swift):
- `start()`: Start timing
- `stop()`: Stop timing
- `update()`: Calculate delta time
- `getTickSeconds() -> Int`: Returns 0 or 1 (ISSUE: not actual delta)
- `getElapsedTime() -> Double`: Total elapsed since start
- `isComplete() -> Bool`: Returns isStopped

**NOTE**: getTickSeconds() returns Int and always 0 or 1, not actual frame delta

### Camera Utils (Utils/CameraUtils.swift):
- `makePerspectiveMatrix()`: Perspective projection
- `makeLookAtMatrix()`: View matrix from eye/center/up
- `makeTranslationMatrix()`: Translation matrix
- `matrix_rotation()`: Rotation around arbitrary axis
- `makeModelMatrix()`: TRS composite matrix
- `radians_from_degrees()`: Angle conversion
- Plus matrix helper functions

### Utils Functions (Utils/Utils.swift):
- `makeDefaultRenderPipeline()`: For colored vertex data
- `makeObjectRenderPipeline()`: For OBJ vertex data (position + normal)

### ObjLoader (Utils/ObjLoader.swift):
- `loadMesh(content: String, device)`: Parses OBJ format, returns (Mesh, minX, maxX)
- `loadModel(device)`: Loads a_letter_texture.obj (hardcoded, unused)
- `loadTexture(device)`: Loads letter_A_texture_c.png (stub, returns nil)

### Extensions (Extensions/Extensions.swift):
- **float4x4 constructors**: translation, scaling, rotation (X/Y/Z)
- **SFSpeechRecognizer async**: hasAuthorizationToRecognize()
- **AVAudioSession async**: hasPermissionToRecord()

---

## VERTEX & UNIFORM STRUCTS

### Vertex (Structs/Vertex.swift):
```swift
struct Vertex { position: SIMD3<Float>, color: SIMD4<Float> }
struct SimpleVertex { position: SIMD3<Float> }
struct ObjVertex { position: SIMD3<Float>, normal: SIMD3<Float> }
```

### Uniforms (Structs/Uniforms.swift):
```swift
struct Uniforms {
    var projectionMatrix: simd_float4x4
    var viewMatrix: simd_float4x4
    var modelMatrix: simd_float4x4
}
```

### Mesh (Structs/Mesh.swift):
```swift
struct Mesh {
    let vertexBuffer: MTLBuffer
    let indexBuffer: MTLBuffer
    let indexCount: Int
}
```

---

## METAL SHADERS

### Shader_Obj.metal (ACTIVE):

**obj_vertex_shader**:
- Input: ObjVertex (position, normal)
- Per-instance Uniforms from buffer[1]
- Computes MVP = Projection × View × Model
- Outputs: VertexOut (position, normal, worldPosition)

**obj_fragment_shader**:
- Lighting: simple diffuse + ambient
- Base color: magenta (1, 0.647, 1)
- Light from (0, 0, 100) looking down Z
- Output: ambient + diffuse blend

### Shaders.metal:
- Basic colored vertex shaders (unused)

### TextureShaders.metal:
- Texture mapping PoC (unused)

---

## SCORING & COMBO SYSTEM

### Score Calculation:
```
Base Score: 1 point per correct answer (WordFoo.Reward)
    ↓
For every 4 consecutive correct answers:
    ↓
Score *= 1.5  (50% multiplier)
```

### Combo/Streak Tracking:
- `streakChain`: Local in IgniterScene (0-max)
- `gameState.Streak`: Synced to GameState every frame
- `gameState.MaxStreak`: Fixed at 3 (display max)
- `comboGauge.incrementCombo()`: `value % (maxCombo + 1)` keeps 0-3

### Combo Reset:
- Resets to 0 when word times out (no answer given)
- Resets when wrong answer given

---

## WORD CYCLING & DISPLAY

### Word Bank:
- 400+ common English words in IgniterScene.wordBank
- Includes verbs, nouns, pronouns, prepositions

### Layout Behavior:
- **Short words**: Centered on screen, static
- **Long words**: Slide left-right repeatedly with sinusoidal animation
  - Reverses direction at screen boundaries
  - Speed configurable via WordLayoutConfig.speed

### Advance Conditions:
1. Player answers correctly → immediate advance
2. timeToAnswer expires → advance without reward
3. wordTimeToLive expires (no answer) → advance without reward

---

## KNOWN ISSUES & INCOMPLETE AREAS

### TODOs Found:
1. **GameState.swift:11**: "TODO: move to configuration file - persistance"
2. **Renderer.swift:55**: "TODO: We need to stop timer on game over"
3. **HudController.swift:235**: "TODO: We can display loading spinner"
4. **ObjLoader.swift:74-99**: "TODO: enhance to receive model path→extension via param"
5. **TextureScene.swift**: Multiple TODOs for polygon/shader replacement

### Dead/Unused Code:
1. **MenuScene**: Empty stubs, no implementation
2. **TextureScene**: PoC code, not used in main game
3. **OrbitCamera struct**: Defined but never instantiated
4. **ParallelogramBar & ParallelogramStack**: Defined but unused
5. **Renderable protocol**: No implementations
6. **TextureShaders.metal**: Texture PoC, not used
7. **Shaders.metal**: Old colored shaders, not used
8. **ObjLoader.loadModel()**: Hardcoded, never called
9. **ObjLoader.loadTexture()**: Returns nil stub
10. **Camera movement methods**: Empty stubs
11. **Gesture handling**: Captured but not applied

### Incomplete Features:
1. **Pause functionality**: Button exists but pause not fully implemented
2. **Lives system**: Config exists but never decremented
3. **Multiple levels**: Only one level, no level selection
4. **Difficulty progression**: No difficulty settings
5. **Persistence**: No saved high scores
6. **Sound effects**: No audio feedback beyond voice
7. **Visual feedback**: No error/correct animations
8. **Gesture input**: Pan/pinch recognized but not used

### Potential Bugs:
1. **TimeController.getTickSeconds()** returns Int (0 or 1), not actual delta
   - May cause discrete timing issues
2. **Speech recognition partial results**: Sets IsAnswering early on partial matches
3. **Combo multiplier**: `if streakChain == 4` with maxStreak=3 means always true after 4th
4. **Button overlap**: Microphone button constraints may cause overlap with pause button

---

## KEY ARCHITECTURE INSIGHTS

1. **Clean Separation**: State, Scene, Render, UI, Input well separated
2. **Unidirectional Flow**: Input → GameState → Scene Logic → Rendering
3. **Instance Rendering**: One call per letter with unique MVP matrices
4. **Callback-based Input**: Speech recognition updates GameState asynchronously
5. **Pure UIKit**: No SwiftUI despite imports, manual layout constraints
6. **Pre-loaded Assets**: OBJ models for letters, loaded on demand
7. **No Optimization**: No LOD, batching, or culling yet
8. **Scalable Design**: Easy to add more levels, game modes, difficulty

---

## FILE LISTING (Complete)

**Main App:**
- ViewController.swift - MTKView setup, gesture forwarding
- Renderer.swift - Frame loop, command buffer, HUD updates
- AppDelegate.swift - App initialization
- SceneDelegate.swift - Window/scene setup

**Game Logic:**
- Repository/GameState.swift - Central state container
- Scenes/SceneManager.swift - Scene switching, config loading
- Scenes/IgniterScene.swift - Main game loop, scoring
- Scenes/MenuScene.swift - STUB
- Scenes/TextureScene.swift - PoC

**Rendering:**
- Components/WordRenderer.swift - Letter rendering orchestrator
- Components/WordLayoutManager.swift - Layout & animation
- Components/Letter.swift - Single letter model loading
- Components/Camera.swift - View/projection matrices

**Input/UI:**
- Structs/SpeechRecognizer.swift - Voice input capture
- Structs/HudController.swift - HUD management
- Structs/ComboGauge.swift - Combo visualization

**Configuration:**
- Structs/LevelConfig.swift - Level parameters
- Structs/WordLayoutConfig.swift - Layout parameters
- Structs/WordFoo.swift - Word + reward
- Structs/CameraSettings.swift - Camera config

**Data Structures:**
- Structs/Uniforms.swift - GPU uniforms
- Structs/Vertex.swift - Vertex formats
- Structs/Mesh.swift - Geometry container

**Utilities:**
- Utils/TimeController.swift - Timing
- Utils/ObjLoader.swift - 3D model loading
- Utils/CameraUtils.swift - Matrix math
- Utils/Utils.swift - Pipeline helpers
- Extensions/Extensions.swift - Matrix & async helpers

**Protocols:**
- Protocols/SceneProtocol.swift - Scene interface
- Protocols/CameraProtocol.swift - Camera interface
- Protocols/Renderable.swift - Renderable interface (unused)

**Enums:**
- Enums/GameEnums.swift - PlayState, MicrophoneState

**Shaders:**
- Shaders/Shader_Obj.metal - Letter rendering (ACTIVE)
- Shaders/Shaders.metal - Colored vertices (unused)
- Shaders/TextureShaders.metal - Texture PoC (unused)

**Assets:**
- 3DAssets.xcassets - 26 letter OBJ models

