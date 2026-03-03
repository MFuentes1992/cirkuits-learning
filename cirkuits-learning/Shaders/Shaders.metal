//
//  Shaders.metal
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 19/07/25.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    simd_float3 position;
    simd_float4 color;
};

struct VertexOut {
    float4 position [[position]];
    float3 worldPos;
};

struct Uniforms {
    float4x4 modelMatrix;
};

vertex VertexOut vertex_shader(uint vertexID [[vertex_id]],
                               constant VertexIn *vertices [[buffer(0)]],
                               constant Uniforms &uniforms [[buffer(1)]]) {
    VertexOut vertexOut;
    float4 position4 = float4(vertices[vertexID].position, 1.0);
    vertexOut.position =  uniforms.modelMatrix * position4;
    vertexOut.worldPos = vertices[vertexID].position;
    return vertexOut;
}

fragment float4 fragment_shader(VertexOut in [[stage_in]]) {
    float3 normal = normalize(in.worldPos);
    float3 lightDirection = normalize(float3(1.0,1.0,1.0));
    float difuse = max(dot(normal, lightDirection), 0.2);
    return float4(float3(1.0,1.0,1.0) * difuse, 1.0);
}
