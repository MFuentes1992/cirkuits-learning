//
//  TextureShaders.metal
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 14/02/26.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

struct Uniforms {
    float4x4 projectionMatrix;
    float4x4 viewMatrix;
    float4x4 modelMatrix;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                             constant Uniforms &uniforms [[buffer(1)]]) {
    VertexOut out;
    float4 position4 = float4(in.position, 1.0);
    float4x4 mvpMatrix = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix;
    out.position = mvpMatrix * position4;
    out.texCoord = in.texCoord;
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              texture2d<float> baseColorTexture [[texture(0)]]
                              ){
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    float4 color = baseColorTexture.sample(textureSampler, in.texCoord);
    return color;
}
