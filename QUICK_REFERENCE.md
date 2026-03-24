# Cirkuits Learning - Quick Reference Guide

## ENTRY POINTS

### App Launch
1. `ViewController.viewDidLoad()` → Sets up MTKView
2. `Renderer.init()` → Creates GameState, HudController, SceneManager
3. `Renderer.draw()` → Main render loop (called every frame)

### Game Start
1. User taps "Play" button
2. `HudController.startGame()` → Sets state to `.initializing`
3. Countdown timer displays (3 seconds)
4. Speech recognition starts
5. After countdown: state → `.running`

### Main Game Loop
```swift
// In IgniterScene.encode() each frame:
if gameState.CurrentState == .running {
    // 1. Update word timers
    wordTimeToLive += deltaTime
    
    // 2. Check answer
    if gameState.IsAnswering {
        if compareAnswer(gameState.CapturedAnswer, currentWord) {
            nextFoo(reward)
            streakChain += 1
        } else if timeoutReached {
            nextFoo(0)
            streakChain = 0
        }
    }
    
    // 3. Apply multiplier
    if streakChain >= 4 {
        score *= 1.5
        streakChain = 0
    }
    
    // 4. Check game end
    if gameElapsedTime >= levelDuration {
        state = .stop
    }
}
```

---

## KEY DATA STRUCTURES

### GameState (Repository)
```swift
score: Int                      // Current score
combo: Int                      // Unused (see streak)
streak: Int                     // Combo level (0-3)
maxStreak: Int = 3              // Max combo level
currentState: PlayState         // Game state enum
capturedAnswer: String          // From speech recognition
isAnswering: Bool               // Are we waiting for answer?
correctAnswer: Bool             // Was last answer correct?
wordTimeToLive: TimeInterval    // Time word is on screen
wordTimeToAnswer: TimeInterval  // Time to answer word
levelDuration: TimeInterval     // Total game time
```

### WordFoo
```swift
Word: String     // The word to display
Reward: Int      // Points for correct answer
```

### LevelConfig
```swift
timeToLive: 2.0              // Seconds word stays on screen
timeToAnswer: 2.0            // Seconds to answer
levelDuration: 59            // Total seconds
lives: 3                     // Not currently used
levelCountDown: 3            // Countdown before game
```

---

## GAME LOOP FLOW

```
Frame Update:
├─ Timer.update()                           // Calculate delta
├─ IgniterScene.encode()                    // Game logic
│  ├─ Check if answering
│  ├─ Compare with current word
│  ├─ Update score/combo
│  ├─ Call WordRenderer.render()
│  └─ Render 3D text
├─ HudController.updateHud()                // Update UI
│  ├─ Update timer label
│  ├─ Update score label
│  ├─ Update countdown
│  └─ Update combo gauge
└─ GPU renders frame
```

---

## SPEECH RECOGNITION FLOW

```
1. User taps Play → startGame()
2. HudController starts SpeechRecognizer.startRecording()
3. Microphone input → AVAudioEngine → Speech Framework
4. Each recognition update:
   GameState.CapturedAnswer = transcription
   GameState.IsAnswering = true
5. IgniterScene.encode() compares answer
6. If match: advance word, increment combo
7. If timeout: advance word, reset combo
```

**Key:** Speech results are PARTIAL until user stops speaking

---

## RENDERING PIPELINE

### For Each Frame:
```
1. WordRenderer.render(encoder, viewMatrix, projectionMatrix)
2. For each letter in word:
   ├─ Get transform from WordLayoutManager
   ├─ Pack into Uniforms buffer
   ├─ Set vertex buffer (OBJ mesh)
   └─ Draw indexed primitives with instance ID
3. GPU executes:
   ├─ obj_vertex_shader (computes MVP)
   └─ obj_fragment_shader (lighting calculation)
```

### 3D Asset Pipeline:
```
Letter character
  ↓
Letter.init() loads from NSDataAsset
  ↓
ObjLoader.loadMesh() parses OBJ string
  ↓
Returns (Mesh, minX, maxX)
  ↓
Letter stores transform matrix
  ↓
WordLayoutManager positions letters
  ↓
WordRenderer uploads to GPU
  ↓
Metal shaders render
```

---

## COMBO/STREAK SYSTEM

### Tracking:
- **streakChain** (local in IgniterScene): Current consecutive correct
- **gameState.Streak**: Synced display value (0-3)
- **comboGauge**: Visual bars + multiplier badge

### Logic:
```swift
// On correct answer:
streakChain += 1
gameState.Streak = streakChain

// Every 4 correct:
if streakChain >= 4 {
    score *= 1.5
    streakChain = 0
}

// On wrong/timeout:
streakChain = 0
gameState.Streak = 0
```

### Reset Conditions:
- Wrong answer
- Timeout (no answer given in timeToAnswer seconds)
- Word times out (wordTimeToLive exceeded with no answer)

---

## UI BUTTON ACTIONS

### Play Button
```swift
startGame() {
    state = .initializing
    timer.start()
    speechRecognition.startRecording()
    showCountdownLabel()
}
```

### Pause Button
```swift
togglePause() {
    if state == .running {
        state = .pause
        icon = "play.circle.fill"
    } else if state == .pause {
        state = .running
        icon = "pause.circle.fill"
    }
}
```

### Microphone Button
```swift
toggleMute() {
    if unmuted {
        muted = true
        speechRecognition.stopTranscribing()
        icon = "microphone.slash.circle.fill"
    } else {
        unmuted = true
        speechRecognition.startRecording()
        icon = "microphone.circle.fill"
    }
}
```

---

## FILE DEPENDENCY GRAPH

```
ViewController
  ↓
Renderer
  ├─ GameState
  ├─ TimeController
  ├─ HudController
  │  ├─ SpeechRecognizer
  │  ├─ ComboGauge
  │  └─ GameState
  └─ SceneManager
     ├─ LevelConfig
     └─ IgniterScene
        ├─ WordRenderer
        │  ├─ WordLayoutManager
        │  │  └─ Letter
        │  │     └─ ObjLoader
        │  └─ Uniforms
        ├─ Camera
        └─ GameState
```

---

## IMPORTANT FUNCTIONS

### IgniterScene.nextFoo(reward: Int)
- Advances to next word
- Adds reward to score
- Updates WordRenderer with new word
- Increments currentFooIndex (wraps around)

### WordLayoutManager.setWord(word: String)
- Creates Letter objects for each character
- Computes layout transforms
- Determines if animation needed

### HudController.startGame()
- Initializes countdown display
- Starts timer
- Begins speech recognition
- Shows pause/mute buttons

### SpeechRecognizer.startRecording()
- Sets up AVAudioEngine
- Installs audio tap
- Starts recognition task
- Callback updates GameState.CapturedAnswer

---

## SHADER DETAILS

### obj_vertex_shader
- **Input**: position, normal (from OBJ file)
- **Uniforms**: projection, view, model (per instance)
- **Output**: position (MVP-transformed), normal, worldPosition
- **Key**: Instance ID selects which Uniforms to use

### obj_fragment_shader
- **Input**: normal, worldPosition
- **Lighting**: Simple Blinn-Phong (ambient + diffuse)
- **Color**: Magenta base (1, 0.647, 1)
- **Light**: From camera position (0, 0, 100)

---

## CONFIGURATION CUSTOMIZATION

### In SceneManager.setCurrentScene():
```swift
let levelConfig = LevelConfig(
    timeToLive: 2.0,        // Change word display time
    timeToAnswer: 2.0,      // Change response time
    levelDuration: 59,      // Change total game time
    lives: 3,               // Not used yet
    levelCountDown: 3       // Change pre-game countdown
)
```

### In IgniterScene.buildInitialScene():
```swift
cameraSettings = CameraSettings(
    eye: SIMD3<Float>(0,0,100),      // Camera position
    center: SIMD3<Float>(0,0,0),     // Look-at target
    up: SIMD3<Float>(0,1,0),         // Up direction
    fovDegrees: 60.0,                // Field of view
    aspectRatio: 19.5/9,             // Screen aspect
    nearZ: 1.0,                      // Near plane
    farZ: 1000.0                     // Far plane
)
```

### In WordLayoutConfig:
```swift
WordLayoutConfig(
    screenWidth: 400,
    maxWidthPercentage: 0.6,    // 60% of screen
    letterSpacing: 2.5,
    letterWidth: 15,
    speed: 1.5,                 // Animation speed
    blankSpaceWidth: 10
)
```

---

## TROUBLESHOOTING CHECKLIST

**Word not displaying?**
- Check if Letter asset exists in 3DAssets.xcassets
- Verify ObjLoader is correctly parsing the OBJ file
- Check WordRenderer is being called in IgniterScene.encode()

**Speech recognition not working?**
- Check microphone permissions in Info.plist
- Verify SpeechRecognizer.startRecording() is called
- Check GameState.IsAnswering is being set

**Scoring not updating?**
- Check IgniterScene game loop logic
- Verify GameState.Score is being set
- Check HudController.updateScoreDisplay() is called

**Combo not incrementing?**
- Check answer comparison (case-insensitive)
- Verify streakChain logic in IgniterScene
- Check comboGauge.incrementCombo() is called

**Game not starting?**
- Verify startGame() is being called from Play button
- Check state transitions (.stop → .initializing → .running)
- Verify timer is started

---

## COMMON MODIFICATIONS

### Add a new word:
```swift
// In IgniterScene.wordBank:
let wordBank: [String] = [
    "existing", "words",
    "new_word"  // Add here
]
```

### Change game duration:
```swift
// In SceneManager.setCurrentScene():
let levelConfig = LevelConfig(..., levelDuration: 120, ...)
```

### Change word display time:
```swift
let levelConfig = LevelConfig(timeToLive: 3.0, ...)
```

### Change combo multiplier:
```swift
// In IgniterScene.encode():
if streakChain >= 4 {
    score *= 2.0  // Was 1.5
}
```

### Change camera position:
```swift
// In IgniterScene.buildInitialScene():
eye: SIMD3<Float>(0, 0, 150)  // Move camera back
```

---

## DEBUGGING TIPS

### Print current state:
```swift
print("Score:\(gameState.Score) Streak:\(gameState.Streak) State:\(gameState.CurrentState)")
```

### Log word changes:
```swift
// In IgniterScene.nextFoo():
print("Current word: \(WordFoos[currentFooIndex].Word)")
```

### Check speech input:
```swift
// In SpeechRecognizer callback:
print("Voice captured:\(newText)")
print("GameState.CapturedAnswer:\(gameState.CapturedAnswer)")
```

### Monitor timing:
```swift
// In IgniterScene.encode():
print("wordTimeToLive: \(wordTimeToLive), timeToAnswer: \(timeToAnswer)")
```

---

## PERFORMANCE NOTES

- **GPU Rendering**: Uses instance drawing (one call for all letters)
- **Memory**: 26 OBJ letter models loaded at startup
- **CPU**: Simple game loop, no heavy computation
- **Audio**: Async speech recognition callback

No optimization needed for current scope, but consider:
- LOD for distant letters if adding 3D effects
- Batching if adding many more objects
- Culling if camera becomes dynamic

