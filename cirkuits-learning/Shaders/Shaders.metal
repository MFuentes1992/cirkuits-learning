//
//  Shaders.metal
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 19/07/25.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
    float4 color   [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};


vertex VertexOut vertex_shader(const VertexIn vertexIn [[stage_in]]) {
    VertexOut vertexOut;
    vertexOut.position = float4(vertexIn.position, 1.0); // -- Last value is the "Normal"?
    vertexOut.color = vertexIn.color;
    return vertexOut;
}

fragment float4 fragment_shader(VertexOut in [[stage_in]]) {
    return float4(in.color);
}
