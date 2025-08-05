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

// -- Camera struct
struct CameraVertexIn {
    float3 position [[attribute(0)]];
};

struct CameraVertexOut {
    float4 position [[position]];
};

// -- Obj struct
struct ObjectVertexIn {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
};

struct Uniforms {
    float4x4 modelViewProjectionMatrix;
    float4x4 modelMatrix;
    float3 lightPosition;
    float3 cameraPosition;
};

struct ObjectVertexOut {
    float4 position [[position]];
    float3 normal;
    float3 worldPosition;
};

vertex VertexOut vertex_shader(const VertexIn vertexIn [[stage_in]]) {
    VertexOut vertexOut;
    vertexOut.position = float4(vertexIn.position, 1.0); // -- Last value is the "Normal"?
    vertexOut.color = vertexIn.color;
    return vertexOut;
}

// -- Orbital Camera
vertex CameraVertexOut camera_vertex_shader(const VertexIn in [[stage_in]],
                                    constant float4x4 &mvp [[buffer(1)]]) {
    CameraVertexOut out;
    out.position = mvp * float4(in.position, 1.0);
    return out;
}

// -- 3D Object + Camera
vertex ObjectVertexOut obj_vertex_shader(const ObjectVertexIn in [[stage_in]], constant Uniforms& uniforms [[buffer(1)]]) {
    ObjectVertexOut out;
    float4 pos = float4(in.position, 1.0);
    out.position = uniforms.modelViewProjectionMatrix * pos;
    out.normal = in.normal;
    out.worldPosition = (uniforms.modelMatrix * pos).xyz;
    return out;
}

// -------- >

fragment float4 fragment_shader(VertexOut in [[stage_in]]) {
    return float4(in.color);
}

// -- Orbital + Camera

fragment float4 camera_fragment_shader(VertexOut in [[stage_in]]) {
    return float4(in.color);
}

// -- 3D Object fragment
fragment float4 obj_fragment_shader(ObjectVertexOut in [[stage_in]]) {
    float3 lightDir = normalize(in.worldPosition - float3(0, 0, 100));
    float diff = max(dot(-lightDir, in.normal), 0.0);

    float3 baseColor = float3(1.0, 0.647, 0.0); // Dorado
    float3 ambient = 0.3 * baseColor;
    float3 diffuse = diff * baseColor;

    return float4(ambient + diffuse, 1.0);
}
