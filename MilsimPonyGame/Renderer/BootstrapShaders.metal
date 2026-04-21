#include <metal_stdlib>
using namespace metal;

struct SceneVertex {
    float3 position;
    float3 normal;
    float2 uv;
    float4 color;
};

struct SceneUniforms {
    float4x4 viewProjectionMatrix;
    float4x4 modelMatrix;
    float4 lightDirection;
    float4 sunColor;
    float4 cameraPosition;
    float4 fogColor;
    float4 lightingParameters;
    float4 atmosphereParameters;
};

struct SkyUniforms {
    float4 horizonColor;
    float4 zenithColor;
    float4 sunColor;
    float4 skyParameters;
};

struct BootstrapVertexOut {
    float4 position [[position]];
    float4 color;
    float3 normal;
    float3 worldPosition;
    float2 uv;
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
    out.worldPosition = worldPosition.xyz;
    out.uv = inVertex.uv;
    return out;
}

fragment float4 skyFragmentMain(
    SkyVertexOut in [[stage_in]],
    constant SkyUniforms &uniforms [[buffer(0)]]
) {
    float heightFactor = clamp(in.uv.y, 0.0, 1.0);
    float4 baseGradient = mix(uniforms.horizonColor, uniforms.zenithColor, pow(heightFactor, 0.75));
    float hazeStrength = max(uniforms.skyParameters.x, 0.0);
    float horizonGlow = pow(1.0 - abs((heightFactor * 2.0) - 1.0), 6.0) * (0.08 + (hazeStrength * 0.10));
    float3 skyColor = baseGradient.rgb + horizonGlow + (uniforms.sunColor.rgb * horizonGlow * 0.18);
    return float4(skyColor, 1.0);
}

fragment float4 bootstrapFragmentMain(
    BootstrapVertexOut in [[stage_in]],
    constant SceneUniforms &uniforms [[buffer(1)]],
    texture2d<float> surfaceTexture [[texture(0)]],
    sampler surfaceSampler [[sampler(0)]]
) {
    float4 sampledTexture = surfaceTexture.sample(surfaceSampler, in.uv);
    float3 baseColor = in.color.rgb * sampledTexture.rgb;
    float3 lightDirection = normalize(-uniforms.lightDirection.xyz);
    float3 normal = normalize(in.normal);
    float diffuse = pow(clamp(dot(normal, lightDirection) * 0.5 + 0.5, 0.0, 1.0), 1.2);
    float ambientIntensity = uniforms.lightingParameters.x;
    float diffuseIntensity = uniforms.lightingParameters.y;
    float fogNear = uniforms.lightingParameters.z;
    float fogFar = uniforms.lightingParameters.w;
    float hazeStrength = max(uniforms.atmosphereParameters.x, 0.0);
    float3 ambient = baseColor * ambientIntensity;
    float3 sunContribution = baseColor * diffuse * diffuseIntensity * uniforms.sunColor.rgb;
    float3 litColor = ambient + sunContribution;

    float fogDistance = distance(in.worldPosition, uniforms.cameraPosition.xyz);
    float fogFactor = smoothstep(fogNear, max(fogFar, fogNear + 0.001), fogDistance);
    float heightFog = clamp((uniforms.cameraPosition.y - in.worldPosition.y) * 0.035, 0.0, 0.35);
    fogFactor = clamp(fogFactor + (heightFog * hazeStrength), 0.0, 1.0);

    return float4(mix(litColor, uniforms.fogColor.rgb, fogFactor), in.color.a * sampledTexture.a);
}
