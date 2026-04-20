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
    float3 sunColor;
    float diffuseIntensity;
};

struct SkyUniforms {
    float4 horizonColor;
    float4 zenithColor;
};

struct BootstrapVertexOut {
    float4 position [[position]];
    float4 color;
    float3 normal;
};

struct SkyVertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex SkyVertexOut skyVertexMain(uint vertexID [[vertex_id]]) {
    constexpr float2 positions[3] = {
        float2(-1.0, -1.0),
        float2(3.0, -1.0),
        float2(-1.0, 3.0)
    };

    SkyVertexOut out;
    float2 clipPosition = positions[vertexID];
    out.position = float4(clipPosition, 0.0, 1.0);
    out.uv = (clipPosition + 1.0) * 0.5;
    return out;
}

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

fragment float4 skyFragmentMain(
    SkyVertexOut in [[stage_in]],
    constant SkyUniforms &uniforms [[buffer(0)]]
) {
    float heightFactor = clamp(in.uv.y, 0.0, 1.0);
    float4 baseGradient = mix(uniforms.horizonColor, uniforms.zenithColor, pow(heightFactor, 0.75));
    float horizonGlow = pow(1.0 - abs((heightFactor * 2.0) - 1.0), 6.0) * 0.08;
    return float4(baseGradient.rgb + horizonGlow, 1.0);
}

fragment float4 bootstrapFragmentMain(
    BootstrapVertexOut in [[stage_in]],
    constant SceneUniforms &uniforms [[buffer(1)]]
) {
    float3 lightDirection = normalize(-uniforms.lightDirection);
    float diffuse = max(dot(normalize(in.normal), lightDirection), 0.0);
    float3 ambient = in.color.rgb * uniforms.ambientIntensity;
    float3 sunContribution = in.color.rgb * diffuse * uniforms.diffuseIntensity * uniforms.sunColor;
    return float4(ambient + sunContribution, in.color.a);
}
