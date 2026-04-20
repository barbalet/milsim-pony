#include <metal_stdlib>
using namespace metal;

struct SceneVertex {
    float3 position;
    float3 normal;
    float4 color;
};

struct SceneUniforms {
    float4x4 viewProjectionMatrix;
    float4x4 modelMatrix;
    float3 lightDirection;
    float ambientIntensity;
};

struct BootstrapVertexOut {
    float4 position [[position]];
    float4 color;
    float3 normal;
};

vertex BootstrapVertexOut bootstrapVertexMain(
    uint vertexID [[vertex_id]],
    constant SceneVertex *vertices [[buffer(0)]],
    constant SceneUniforms &uniforms [[buffer(1)]]
) {
    SceneVertex inVertex = vertices[vertexID];
    float4 worldPosition = uniforms.modelMatrix * float4(inVertex.position, 1.0);
    BootstrapVertexOut out;
    out.position = uniforms.viewProjectionMatrix * worldPosition;
    out.color = inVertex.color;
    out.normal = normalize((uniforms.modelMatrix * float4(inVertex.normal, 0.0)).xyz);
    return out;
}

fragment float4 bootstrapFragmentMain(
    BootstrapVertexOut in [[stage_in]],
    constant SceneUniforms &uniforms [[buffer(1)]]
) {
    float3 lightDirection = normalize(-uniforms.lightDirection);
    float diffuse = max(dot(normalize(in.normal), lightDirection), 0.0);
    float lighting = uniforms.ambientIntensity + (diffuse * 0.68);
    return float4(in.color.rgb * lighting, in.color.a);
}
