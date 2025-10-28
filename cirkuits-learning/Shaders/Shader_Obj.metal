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
    float3 lightPosition;
    float3 cameraPosition;
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
    out.normal = in.normal;
    out.worldPosition = (u.modelMatrix * pos).xyz;
    return out;
}

// -- Fragment shader
fragment float4 obj_fragment_shader(VertexOut in [[stage_in]]) {
    float3 lightDir = normalize(in.worldPosition - float3(0, 0, 100));
    float diff = max(dot(-lightDir, in.normal), 0.0);

    float3 baseColor = float3(0, 0.647, 1.0); // Dorado
    float3 ambient = 0.3 * baseColor;
    float3 diffuse = diff * baseColor;    
    return float4(ambient + diffuse, 1.0);
}
