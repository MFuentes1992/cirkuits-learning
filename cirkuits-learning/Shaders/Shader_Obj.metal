//
//  Shader_Obj.metal
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 06/08/25.
//

#include <metal_stdlib>
using namespace metal;


// -- Obj struct
struct VertexIn {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
};

struct Uniforms {
    float4x4 projectionMatrix;
    float4x4 viewMatrix;
    float4x4 modelMatrix;
    // Inverse-transpose of modelMatrix. Field order must stay in step with the
    // Swift `Uniforms` struct in Structs/Uniforms.swift.
    float4x4 normalMatrix;
};

struct TimeUniforms {
    float time;
    float zoomAmount;
    float zoomSpeed;
};

struct VertexOut {
    float4 position [[position]];
    float3 normal;
    float3 worldPosition;
};

// -- Camera is always after uniforms buffer!!
vertex VertexOut obj_vertex_shader(const VertexIn in [[stage_in]],
                                   constant Uniforms* uniforms [[buffer(1)]],
                                   uint instanceID [[instance_id]]) {
    VertexOut out;
    
    // float animatedZoom = 1.0 + tUniforms.zoomAmount * cos(tUniforms.time * tUniforms.zoomSpeed);
    // float zoomAmount = 1.0 + *zoom;
    float4 pos = float4(in.position, 1.0);
    // float4 pos = float4(in.position, 1.0);
    constant Uniforms& u = uniforms[instanceID];
    float4x4 mvpMatrix = u.projectionMatrix * u.viewMatrix * u.modelMatrix;
    out.position = mvpMatrix * pos;
    // Carry the normal into world space, matching worldPosition below. Passing
    // the raw object-space normal is only correct while a letter is purely
    // translated — it breaks the moment one rotates.
    out.normal = (u.normalMatrix * float4(in.normal, 0.0)).xyz;
    out.worldPosition = (u.modelMatrix * pos).xyz;
    return out;
}

// -- Lighting rig. Key from the front-right, fill from behind-left so a face
// -- turned away from the key still shows its form instead of flat ambient.
constant float3 kKeyLightPosition  = float3( 70.0,  90.0,  160.0);
constant float3 kFillLightPosition = float3(-90.0, -30.0, -140.0);

// -- Fragment shader
fragment float4 obj_fragment_shader(VertexOut in [[stage_in]]) {
    // Interpolation across a triangle shortens the normal, which dims the
    // diffuse term toward the middle of every face unless it's renormalised.
    float3 normal = normalize(in.normal);

    float3 toKey  = normalize(kKeyLightPosition  - in.worldPosition);
    float3 toFill = normalize(kFillLightPosition - in.worldPosition);

    float key  = max(dot(normal, toKey),  0.0);
    float fill = max(dot(normal, toFill), 0.0);

    float3 baseColor = float3(1.0, 1.0, 1.0);
    // Tuned so the front face lands just under white (~0.95) while the bevels
    // and side walls stay near 0.6 — that gap is what keeps a white letter
    // reading as 3D. Flattening the spread to reach pure white everywhere
    // turns the glyph back into a silhouette.
    //
    // The two lights sit almost opposite each other (their directions dot to
    // -0.94), so no face collects much from both and the sum overshooting 1.0
    // costs nothing in practice; min() covers the sliver that does.
    float3 lit = baseColor * (0.30 + 0.80 * key + 0.45 * fill);
    return float4(min(lit, 1.0), 1.0);
}
