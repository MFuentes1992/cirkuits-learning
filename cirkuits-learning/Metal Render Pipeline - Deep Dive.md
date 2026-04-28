# Metal Render Pipeline - Deep Dive

> How pixels get from your Swift code to the screen, explained with technical precision *and* like you're five.

---

## Table of Contents

- [[#The Big Picture - What Even Is a Render Pipeline?]]
- [[#Step 1 - The GPU Device]]
- [[#Step 2 - Vertices: The Atoms of 3D Graphics]]
- [[#Step 3 - Buffers: Shipping Containers for Data]]
- [[#Step 4 - The Vertex Descriptor: The Packing Instructions]]
- [[#Step 5 - The Render Pipeline State: The Factory Blueprint]]
- [[#Step 6 - Shaders: The Artists on the Assembly Line]]
- [[#Step 7 - The Command Buffer & Encoder: The Work Orders]]
- [[#Step 8 - The Draw Call: Pressing "Go"]]
- [[#Full Data Flow - From Swift to Screen]]
- [[#How Cirkuits Uses All of This]]
- [[#Appendix - Buffer Index Map]]
- [[#Appendix - Glossary]]

---

## The Big Picture - What Even Is a Render Pipeline?

### Like you're 5

Imagine you want to build a LEGO castle and show it on a TV screen. You can't just throw LEGO bricks at the TV. You need:

1. **Bricks** (vertices) - the raw building blocks
2. **A box to carry them** (buffers) - so they don't get lost
3. **Instruction booklet** (pipeline state) - tells you what goes where
4. **Painters** (shaders) - they color and light everything up
5. **A conveyor belt** (command buffer) - moves everything through the factory
6. **The factory itself** (the GPU) - does all the heavy lifting super fast

The **render pipeline** is the entire assembly line from "I have 3D data" to "there's a picture on screen."

### Technically

The Metal render pipeline is a **fixed-function + programmable hybrid pipeline** that processes vertex data through a series of stages to produce rasterized, shaded fragments (pixels) in a framebuffer. It runs on the GPU, which is a massively parallel processor optimized for this exact workload.

```
Swift Code
    |
    v
[MTLDevice] ---- creates ----> [MTLBuffer] (vertex data)
    |                           [MTLBuffer] (uniform data)
    |                           [MTLBuffer] (index data)
    |
    v
[MTLRenderPipelineState] ---- compiled from ----> [.metal shaders]
    |
    v
[MTLCommandBuffer]
    |
    v
[MTLRenderCommandEncoder] --- binds buffers + pipeline state
    |
    v
drawIndexedPrimitives() --- THE DRAW CALL
    |
    v
GPU Pipeline:
    [Vertex Shader] -> [Rasterizer] -> [Fragment Shader] -> [Framebuffer]
    |
    v
Screen (via CAMetalDrawable)
```

---

## Step 1 - The GPU Device

### Like you're 5

The `MTLDevice` is the **factory manager**. Before you can build anything, you need to talk to the manager. The manager gives you access to the factory floor (GPU) and lets you order supplies (buffers, textures, pipeline states).

### Technically

`MTLDevice` is your interface to the GPU hardware. Every Metal object - buffers, textures, pipeline states, command queues - is created through it.

```swift
// You typically get it once at app startup
guard let device = MTLCreateSystemDefaultDevice() else {
    fatalError("Metal is not supported on this device")
}
```

In Cirkuits, the `Renderer` class obtains the device and passes it down to every component that needs GPU resources: `WordRenderer`, `Letter`, `ExplosionSprite`, etc.

> **Key insight**: The `MTLDevice` is **not** the GPU itself. It's an abstraction layer - a Swift object that knows how to talk to the actual hardware. Think of it as a telephone to the factory, not the factory.

---

## Step 2 - Vertices: The Atoms of 3D Graphics

### Like you're 5

Every 3D shape is made of tiny triangles, like a mosaic. Each corner of each triangle is called a **vertex**. A vertex knows two things:
- **Where am I?** (position)
- **Which way am I facing?** (normal - used for lighting)

A single letter "A" in Cirkuits might have hundreds of these tiny triangle corners!

### Technically

A vertex is a data structure that carries per-vertex attributes through the pipeline. In Cirkuits, there are multiple vertex types for different rendering paths:

```swift
// For 3D letter rendering (24 bytes per vertex)
struct ObjVertex {
    var position: SIMD3<Float>  // 12 bytes - x, y, z in model space
    var normal: SIMD3<Float>    // 12 bytes - surface direction for lighting
}

// For 2D sprite rendering (16 bytes per vertex)
struct SpriteVertex {
    var position: SIMD2<Float>  // 8 bytes - x, y in NDC
    var uv: SIMD2<Float>        // 8 bytes - texture coordinates
}
```

**Why `SIMD3<Float>` instead of three separate floats?**

SIMD (Single Instruction, Multiple Data) types are aligned to GPU-friendly boundaries. The GPU can process a `SIMD3<Float>` in a single clock cycle instead of three. It's not just a convenience type - it maps directly to GPU register widths.

### Memory Layout

```
ObjVertex in memory (24 bytes):
|--- position (12B) ---|--- normal (12B) ---|
| x    | y    | z      | nx   | ny   | nz  |
| 4B   | 4B   | 4B     | 4B   | 4B   | 4B  |
offset 0                offset 12
```

These byte offsets become critical when we tell Metal how to read the data (see Vertex Descriptor).

---

## Step 3 - Buffers: Shipping Containers for Data

### Like you're 5

You have a thousand LEGO bricks, but you can't hand them to the factory one by one - that would take forever. Instead, you put them all in a **big shipping container** (buffer) and send the whole container to the factory at once.

The GPU factory is *really fast* at unpacking containers, but *really slow* at receiving individual bricks. So buffers are essential.

### Technically

An `MTLBuffer` is a contiguous block of memory accessible by both the CPU and GPU. It's the primary mechanism for transferring data to the GPU.

```swift
// Creating a vertex buffer from an array of ObjVertex
let vertexBuffer = device.makeBuffer(
    bytes: vertices,                              // pointer to Swift array
    length: MemoryLayout<ObjVertex>.stride * vertices.count,  // total bytes
    options: .storageModeShared                   // CPU + GPU access
)!
```

### Storage Modes

| Mode | CPU Access | GPU Access | When to use |
|------|-----------|-----------|-------------|
| `.storageModeShared` | Read/Write | Read/Write | Data that changes every frame (uniforms, sprite UVs) |
| `.storageModePrivate` | None | Read/Write | Static data (textures, meshes that never change) |
| `.storageModeManaged` | Read/Write | Read/Write | macOS only, requires explicit sync |

In Cirkuits:
- **Vertex buffers** use `.storageModeShared` because sprite UVs update every frame
- **Textures** use `.storageModePrivate` because once loaded, the CPU never touches them

### Three Kinds of Buffers in Cirkuits

#### 1. Vertex Buffer (Buffer Index 0)
Holds the raw geometry - positions and normals for every triangle corner.

```swift
// In ObjLoader - loads an OBJ file into a vertex buffer
let vertexBuffer = device.makeBuffer(
    bytes: objVertices,
    length: MemoryLayout<ObjVertex>.stride * objVertices.count,
    options: .storageModeShared
)!
```

#### 2. Index Buffer (No buffer index - passed directly to draw call)
Holds indices that reference vertices. Instead of duplicating shared vertices, you list them once and reference them by number.

```
Without indexing (wasteful):          With indexing (efficient):
Triangle 1: V0, V1, V2               Vertices: V0, V1, V2, V3
Triangle 2: V2, V1, V3               Indices:  [0, 1, 2, 2, 1, 3]
= 6 vertices stored                  = 4 vertices + 6 tiny indices
```

```swift
// A quad (two triangles sharing an edge):
let indices: [UInt16] = [0, 1, 2, 0, 2, 3]
let indexBuffer = device.makeBuffer(
    bytes: indices,
    length: MemoryLayout<UInt16>.stride * 6,
    options: .storageModeShared
)!
```

#### 3. Uniform Buffer (Buffer Index 1)
Holds per-instance transformation matrices (Model, View, Projection). These tell the GPU *where* to place each letter in the scene.

```swift
// WordRenderer allocates space for 64 letter transforms
struct Uniforms {
    var projectionMatrix: simd_float4x4  // 64 bytes - lens/perspective
    var viewMatrix: simd_float4x4        // 64 bytes - camera position
    var modelMatrix: simd_float4x4       // 64 bytes - object transform
}
// Total: 192 bytes per instance, 192 * 64 = 12,288 bytes
let uniformBuffer = device.makeBuffer(
    length: MemoryLayout<Uniforms>.stride * 64,
    options: .storageModeShared
)!
```

### Like you're 5 (again)

Think of it as three boxes you send to the factory:
- **Box 0** (vertex buffer): "Here are all the LEGO bricks and which direction they face"
- **The index list**: "Build triangles using brick #0, then #1, then #2, then start a new triangle with #2, #1, #3..."
- **Box 1** (uniform buffer): "Put the letter A *here*, the letter B *there*, and the letter C *way over there*"

---

## Step 4 - The Vertex Descriptor: The Packing Instructions

### Like you're 5

When you ship a box of LEGO bricks, you include a note that says: "The first 12 things in each packet are the position, and the next 12 things are the direction they face." Without this note, the factory wouldn't know what's what - it's all just raw bytes.

### Technically

The `MTLVertexDescriptor` tells Metal how to interpret the raw bytes in your vertex buffer. It maps byte offsets to shader attributes.

```swift
// From Utils.swift - makeObjectRenderPipeline
let vertexDescriptor = MTLVertexDescriptor()

// Attribute 0: Position → maps to [[attribute(0)]] in shader
vertexDescriptor.attributes[0].format = .float3        // SIMD3<Float>
vertexDescriptor.attributes[0].offset = 0              // starts at byte 0
vertexDescriptor.attributes[0].bufferIndex = 0         // comes from buffer 0

// Attribute 1: Normal → maps to [[attribute(1)]] in shader
vertexDescriptor.attributes[1].format = .float3        // SIMD3<Float>
vertexDescriptor.attributes[1].offset = 12             // starts at byte 12
vertexDescriptor.attributes[1].bufferIndex = 0         // also from buffer 0

// Layout: how to step through the buffer
vertexDescriptor.layouts[0].stride = MemoryLayout<ObjVertex>.stride  // 24 bytes
vertexDescriptor.layouts[0].stepFunction = .perVertex                // one per vertex
```

### The Bridge Between Swift and Metal

This is where the Swift struct and the Metal struct **must agree perfectly**:

```
Swift Side (Vertex.swift)          Metal Side (Shader_Obj.metal)
─────────────────────────          ──────────────────────────────
struct ObjVertex {                 struct VertexIn {
  position: SIMD3<Float>    ←→      float3 position [[attribute(0)]];
  normal: SIMD3<Float>      ←→      float3 normal   [[attribute(1)]];
}                                  };
```

If these don't match - wrong offset, wrong format, wrong buffer index - you get garbage on screen or a crash. The vertex descriptor is the **contract** between CPU and GPU memory.

> **Common pitfall**: Swift struct padding. `MemoryLayout<ObjVertex>.stride` may differ from `MemoryLayout<ObjVertex>.size` due to alignment. Always use `.stride` for buffer math.

---

## Step 5 - The Render Pipeline State: The Factory Blueprint

### Like you're 5

Before the factory can start making things, you give the manager a **big blueprint** that says:
- "Use *this* painting technique for shapes" (vertex shader)
- "Use *this* coloring technique for pixels" (fragment shader)
- "The bricks come packed *this* way" (vertex descriptor)
- "The final picture should be in *this* format" (pixel format)

Once the blueprint is approved, the factory can build things *super fast* because it already knows the plan.

### Technically

`MTLRenderPipelineState` is a **pre-compiled, immutable, validated** GPU program. Creating it is expensive (compiles shaders, validates state), but using it is nearly free.

```swift
// From Utils.swift
func makeObjectRenderPipeline(device: MTLDevice, 
                               vertexName: String, 
                               fragmentName: String) -> MTLRenderPipelineState {
    let library = device.makeDefaultLibrary()!
    
    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.vertexFunction = library.makeFunction(name: vertexName)!
    descriptor.fragmentFunction = library.makeFunction(name: fragmentName)!
    descriptor.vertexDescriptor = vertexDescriptor  // from Step 4
    descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm  // 8 bits per channel
    
    return try! device.makeRenderPipelineState(descriptor: descriptor)
}
```

### Two Pipelines in Cirkuits

| Pipeline | Vertex Shader | Fragment Shader | Purpose |
|----------|--------------|----------------|---------|
| Object Pipeline | `obj_vertex_shader` | `obj_fragment_shader` | 3D letter rendering with lighting |
| Sprite Pipeline | `sprite_vertex_shader` | `sprite_fragment_shader` | 2D explosion effect with alpha blending |

The sprite pipeline has an extra configuration - **alpha blending** - so the explosion can be transparent:

```swift
// Sprite pipeline enables blending
descriptor.colorAttachments[0].isBlendingEnabled = true
descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
```

This means: `finalColor = spriteColor * alpha + backgroundColor * (1 - alpha)`

> **Performance note**: Pipeline state creation triggers shader compilation. In production, you'd do this at load time and cache the result. Never create pipeline states inside a render loop.

---

## Step 6 - Shaders: The Artists on the Assembly Line

### Like you're 5

There are two painters working on the assembly line:

1. **The Position Painter** (vertex shader): Takes each LEGO brick and figures out exactly where it should appear on the TV screen. "This brick is part of the letter A, which should be *here*."

2. **The Color Painter** (fragment shader): Once we know where everything goes, this painter fills in each tiny dot on the screen with the right color. "This dot is facing the light, so make it bright pink. This dot is in shadow, so make it darker."

### Technically

Shaders are programs written in **Metal Shading Language (MSL)** - a C++14 dialect - that run on the GPU. They execute *in parallel* across thousands of GPU cores.

#### The Vertex Shader

Runs **once per vertex**. Its job: transform 3D model-space coordinates into 2D screen-space (clip-space) coordinates.

```metal
// Shader_Obj.metal
vertex VertexOut obj_vertex_shader(
    const VertexIn in [[stage_in]],                    // Per-vertex data (buffer 0)
    constant Uniforms* uniforms [[buffer(1)]],         // Per-instance transforms
    uint instanceID [[instance_id]]                    // Which letter instance
) {
    Uniforms u = uniforms[instanceID];
    
    // The MVP transform chain:
    // Model space → World space → Camera space → Clip space
    float4x4 mvp = u.projectionMatrix * u.viewMatrix * u.modelMatrix;
    
    VertexOut out;
    out.position = mvp * float4(in.position, 1.0);  // Clip-space position
    
    // Transform normal to world space for lighting
    out.normal = (u.modelMatrix * float4(in.normal, 0.0)).xyz;
    out.worldPosition = (u.modelMatrix * float4(in.position, 1.0)).xyz;
    
    return out;
}
```

**What `[[stage_in]]` means**: Metal automatically unpacks the vertex buffer using the vertex descriptor. You get a nice struct instead of raw bytes.

**What `[[buffer(1)]]` means**: "Get this data from whatever buffer is bound at index 1." This is how the shader accesses the uniform buffer.

**What `[[instance_id]]` means**: When rendering multiple letters with one draw call pattern, this tells the shader which instance it's processing. Cirkuits uses `baseInstance` to select the right uniform set.

#### The Fragment Shader

Runs **once per pixel** (fragment). Its job: determine the final color of each pixel.

```metal
fragment float4 obj_fragment_shader(VertexOut in [[stage_in]]) {
    // Blinn-Phong simplified lighting
    float3 lightPosition = float3(0, 0, 100);
    float3 lightDir = normalize(in.worldPosition - lightPosition);
    
    float3 baseColor = float3(1.0, 0.647, 1.0);  // Magenta-pink
    
    float3 ambient = baseColor * 0.3;             // Always visible (30%)
    float diffuse = max(dot(-lightDir, normalize(in.normal)), 0.0);
    
    float3 finalColor = ambient + baseColor * diffuse;
    return float4(finalColor, 1.0);  // RGBA, fully opaque
}
```

#### The Sprite Shader (simpler)

For the explosion effect, shaders are minimal - just pass through position and sample a texture:

```metal
// SpriteShader.metal
vertex SpriteVertexOut sprite_vertex_shader(const SpriteVertexIn in [[stage_in]]) {
    SpriteVertexOut out;
    out.position = float4(in.position, 0.0, 1.0);  // Already in NDC, no transform needed
    out.uv = in.uv;
    return out;
}

fragment float4 sprite_fragment_shader(
    SpriteVertexOut in [[stage_in]],
    texture2d<float> spriteTexture [[texture(0)]],
    sampler texSampler [[sampler(0)]]
) {
    return spriteTexture.sample(texSampler, in.uv);  // Just sample the texture
}
```

### The GPU Execution Model

```
For a letter "A" with 500 vertices and covering 10,000 pixels:

Vertex Shader: 500 parallel invocations
     |
     v
[Rasterizer] - Fixed function, not programmable
  Figures out which pixels each triangle covers
  Interpolates vertex outputs across the triangle surface
     |
     v
Fragment Shader: ~10,000 parallel invocations
     |
     v
Framebuffer (the final image)
```

The **rasterizer** between the two shaders is the unsung hero. It:
1. Takes three transformed vertices (a triangle)
2. Determines which pixels that triangle covers on screen
3. **Interpolates** all vertex outputs (normals, UVs, colors) smoothly across the surface
4. Feeds each pixel to the fragment shader

> This is why the fragment shader receives smooth, interpolated normals even though we only specified normals at triangle corners.

---

## Step 7 - The Command Buffer & Encoder: The Work Orders

### Like you're 5

You can't just yell instructions at the factory. You write everything down on a **work order** (command buffer), hand it to the **foreman** (command encoder) who organizes it, and then send it off. The factory processes the whole stack of orders at once.

### Technically

Metal uses a **deferred command model**. You don't talk to the GPU directly - you record commands into buffers, then submit them.

```swift
// From Renderer.draw(in:)
func draw(in view: MTKView) {
    // 1. Get where we'll draw to
    guard let drawable = view.currentDrawable,
          let descriptor = view.currentRenderPassDescriptor else { return }
    
    // 2. Create a work order
    let commandBuffer = commandQueue.makeCommandBuffer()!
    
    // 3. Create a foreman who records render commands
    let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
    
    // 4. Record ALL the drawing commands
    // (the scene manager delegates to the active scene)
    sceneManager.encode(encoder: encoder, view: view)
    
    // 5. Seal the work order
    encoder.endEncoding()
    
    // 6. Tell the system to show the result when done
    commandBuffer.present(drawable)
    
    // 7. Ship it to the GPU!
    commandBuffer.commit()
}
```

### The Render Pass Descriptor

Before encoding, you configure a **render pass descriptor** that specifies:
- Which texture to render into (the screen's drawable)
- What to do at the start (clear to a background color)
- What to do at the end (store the result)

`MTKView` provides this automatically via `currentRenderPassDescriptor`.

### Why This Architecture?

The deferred model exists because:
1. **Batching**: The GPU gets all commands at once - no back-and-forth latency
2. **Validation**: Metal can check the entire command buffer for errors before submitting
3. **Parallelism**: The CPU can prepare frame N+1 while the GPU renders frame N
4. **Reordering**: The driver can optimize command order within a buffer

---

## Step 8 - The Draw Call: Pressing "Go"

### Like you're 5

After all the setup - loading bricks, preparing the blueprint, positioning the painters - you finally press the big red **GO** button. "Take bricks #0, #1, #2 and make a triangle! Now #2, #1, #3, another triangle!"

### Technically

The draw call is where everything comes together. In Cirkuits, the `WordRenderer` issues one draw call per letter:

```swift
// WordRenderer.render()
func render(encoder: MTLRenderCommandEncoder, 
            viewMatrix: simd_float4x4, 
            projectionMatrix: simd_float4x4) {
    
    // 1. Set the factory blueprint
    encoder.setRenderPipelineState(pipelineState)
    
    // 2. Fill uniform buffer with per-letter transforms
    let uniformsPointer = uniformBuffer.contents()
        .bindMemory(to: Uniforms.self, capacity: 64)
    
    for (index, letter) in letters.enumerated() {
        uniformsPointer[index] = Uniforms(
            projectionMatrix: projectionMatrix,
            viewMatrix: viewMatrix,
            modelMatrix: letter.transform     // Each letter has its own position
        )
    }
    
    // 3. Bind the uniform buffer (shared across all letters)
    encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
    
    // 4. Draw each letter
    for (index, letter) in letters.enumerated() {
        // Bind this letter's vertex buffer
        encoder.setVertexBuffer(letter.mesh.vertexBuffer, offset: 0, index: 0)
        
        // THE DRAW CALL
        encoder.drawIndexedPrimitives(
            type: .triangle,                        // Assemble vertices as triangles
            indexCount: letter.mesh.indexCount,      // How many indices to read
            indexType: .uint16,                      // Indices are 16-bit integers
            indexBuffer: letter.mesh.indexBuffer,    // Where the indices are
            indexBufferOffset: 0,                    // Start from the beginning
            instanceCount: 1,                        // Draw one instance
            baseVertex: 0,                           // No vertex offset
            baseInstance: index                      // SELECT uniforms[index]!
        )
    }
}
```

### The `baseInstance` Trick

This is clever. Instead of binding a different uniform buffer for each letter, Cirkuits packs **all** letter transforms into **one** buffer and uses `baseInstance` to tell the shader which slot to read:

```
Uniform Buffer (12,288 bytes):
┌──────────────┬──────────────┬──────────────┬──────────────┐
│ uniforms[0]  │ uniforms[1]  │ uniforms[2]  │ uniforms[3]  │ ...
│ Letter "H"   │ Letter "E"   │ Letter "L"   │ Letter "L"   │
│ 192 bytes    │ 192 bytes    │ 192 bytes    │ 192 bytes    │
└──────────────┴──────────────┴──────────────┴──────────────┘
                                                     ↑
                       baseInstance: 3 → shader reads this slot
```

In the shader, `instanceID` equals `baseInstance`, so `uniforms[instanceID]` gets the right transform.

---

## Full Data Flow - From Swift to Screen

Here's the complete journey of a single letter "A" being rendered:

```
                          SWIFT / CPU SIDE
═══════════════════════════════════════════════════════════════

  1. ObjLoader reads "a.obj" file
     ↓
  2. Parses vertices & normals into [ObjVertex] array
     ↓
  3. Creates MTLBuffer (vertex buffer, index 0)
     Creates MTLBuffer (index buffer)
     ↓
  4. Letter stores mesh + transform matrix
     ↓
  5. WordLayoutManager computes position
     → letter.transform.columns.3.x = calculated X position
     ↓
  6. WordRenderer.render() called at 60fps
     ↓
  7. Writes Uniforms to buffer index 1:
     { projectionMatrix, viewMatrix, modelMatrix }
     ↓
  8. Binds pipeline state, vertex buffer (0), uniform buffer (1)
     ↓
  9. drawIndexedPrimitives(baseInstance: letterIndex)

═══════════════════════════════════════════════════════════════
                          GPU SIDE
═══════════════════════════════════════════════════════════════

  10. For each vertex (parallel):
      ┌─────────────────────────────────────────────┐
      │ obj_vertex_shader                           │
      │   reads position from [[attribute(0)]]      │
      │   reads normal from [[attribute(1)]]        │
      │   reads uniforms[instanceID] from buffer 1  │
      │   MVP = proj * view * model                 │
      │   clipPos = MVP * position                  │
      │   worldNormal = model * normal              │
      └─────────────────────────────────────────────┘
      ↓
  11. Rasterizer
      ┌─────────────────────────────────────────────┐
      │ Groups vertices into triangles (via indices)│
      │ Clips triangles to screen bounds            │
      │ Determines which pixels each triangle covers│
      │ Interpolates normals & positions per-pixel  │
      └─────────────────────────────────────────────┘
      ↓
  12. For each pixel/fragment (parallel):
      ┌─────────────────────────────────────────────┐
      │ obj_fragment_shader                         │
      │   receives interpolated normal & worldPos   │
      │   computes lighting: ambient + diffuse      │
      │   returns float4(color, 1.0)                │
      └─────────────────────────────────────────────┘
      ↓
  13. Framebuffer stores the pixel color
      ↓
  14. CAMetalDrawable presents to screen

═══════════════════════════════════════════════════════════════
```

---

## How Cirkuits Uses All of This

### The Render Loop (60fps)

Every 16.67ms, `MTKView` calls `Renderer.draw(in:)`:

```
Renderer.draw(in:)
  │
  ├── Creates command buffer & encoder
  │
  ├── SceneManager.encode()
  │     │
  │     └── IgniterScene.encode()
  │           │
  │           ├── WordRenderer.render()      ← 3D letters
  │           │     ├── Set object pipeline
  │           │     ├── Fill uniforms for N letters
  │           │     └── N draw calls (one per letter)
  │           │
  │           └── ExplosionSprite.render()   ← 2D sprite overlay
  │                 ├── Set sprite pipeline
  │                 ├── Update UV coordinates (sprite sheet frame)
  │                 └── 1 draw call (one quad, 2 triangles)
  │
  ├── encoder.endEncoding()
  ├── commandBuffer.present(drawable)
  └── commandBuffer.commit()
```

### Pipeline Switching

Notice that within a single frame, Metal switches between two different pipelines:

1. **Object pipeline** - 3D projection, lighting, no blending
2. **Sprite pipeline** - 2D passthrough, texture sampling, alpha blending

Each `setRenderPipelineState()` call tells the GPU: "From now on, use *this* set of shaders and configuration."

### The Explosion Sprite: A Simpler Pipeline

The `ExplosionSprite` uses a dramatically simpler pipeline than the 3D letters:

```
No 3D transforms needed (positions are already in screen space)
No lighting calculations
Just: position a quad → sample a texture → blend with alpha

The sprite sheet animation works by updating UV coordinates each frame:
┌────┬────┬────┬────┐
│ F0 │ F1 │ F2 │ F3 │   ← 4 columns
├────┼────┼────┼────┤
│ F4 │ F5 │ F6 │ F7 │   ← 2 rows = 8 frames
└────┴────┴────┴────┘

Frame 5 → col=1, row=1 → UV: (0.25, 0.5) to (0.50, 1.0)
```

Each frame, the CPU calculates which sub-rectangle of the texture to show and overwrites the vertex buffer's UV coordinates via `memcpy`:

```swift
// ExplosionSprite.render() - updates UVs every frame
let col = frameIndex % columns
let row = frameIndex / columns
let uLeft = Float(col) * frameWidth
let vTop = Float(row) * frameHeight
// ... writes new SpriteVertex array into vertexBuffer
memcpy(vertexBuffer.contents(), vertices, MemoryLayout<SpriteVertex>.stride * 4)
```

---

## Appendix - Buffer Index Map

| Index | Content | Set By | Read By | Size |
|-------|---------|--------|---------|------|
| **0** | Vertex data (position + normal/UV) | `setVertexBuffer(..., index: 0)` | `[[stage_in]]` via vertex descriptor | Varies per mesh |
| **1** | Uniform data (MVP matrices) | `setVertexBuffer(..., index: 1)` | `[[buffer(1)]]` in vertex shader | 192B x 64 instances |
| **texture 0** | Sprite sheet | `setFragmentTexture(..., index: 0)` | `[[texture(0)]]` in fragment shader | Image dimensions |
| **sampler 0** | Texture sampler | `setFragmentSamplerState(..., index: 0)` | `[[sampler(0)]]` in fragment shader | N/A |

---

## Appendix - Glossary

| Term | Like you're 5 | Technically |
|------|--------------|-------------|
| **Vertex** | A corner point of a triangle | A data structure carrying per-point attributes (position, normal, UV, etc.) |
| **Fragment** | A tiny dot that might become a pixel | A potential pixel generated by rasterization, before depth/stencil tests |
| **Buffer** | A shipping container of data | A contiguous GPU-accessible memory allocation (`MTLBuffer`) |
| **Pipeline State** | The factory blueprint | A pre-compiled, immutable GPU program configuration (`MTLRenderPipelineState`) |
| **Shader** | A painter on the assembly line | A GPU program in MSL that runs in parallel across thousands of cores |
| **Command Buffer** | A stack of work orders | A container for GPU commands, submitted atomically (`MTLCommandBuffer`) |
| **Encoder** | The foreman writing orders | Records type-specific commands into a command buffer (`MTLRenderCommandEncoder`) |
| **Vertex Descriptor** | Packing instructions for the box | A schema that maps byte offsets to shader attributes (`MTLVertexDescriptor`) |
| **NDC** | TV screen coordinates (-1 to 1) | Normalized Device Coordinates - the coordinate system after projection |
| **Clip Space** | Almost-screen coordinates | The coordinate system output by the vertex shader, before perspective divide |
| **MVP** | The 3-step position calculator | Model-View-Projection matrix chain that transforms 3D points to screen |
| **Uniform** | A setting that's the same for all bricks | Data constant across all vertices/fragments in a draw call (per-instance here) |
| **Rasterizer** | The triangle-to-dots converter | Fixed-function hardware that determines pixel coverage of triangles |
| **Framebuffer** | The final picture | The render target texture where fragment shader output is written |
| **Drawable** | The TV screen for this frame | A displayable texture provided by `CAMetalLayer` for presentation |
| **SIMD** | A super-efficient number bundle | Single Instruction Multiple Data - GPU-aligned vector types |
| **Sampler** | Instructions for reading a picture | Configuration for texture filtering and addressing (`MTLSamplerState`) |

---

> **Further reading**: Apple's [Metal Best Practices Guide](https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/) and [Metal Shading Language Specification](https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf)
