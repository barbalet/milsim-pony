#include <metal_stdlib>
using namespace metal;

struct SceneVertex {
    float3 position;
    float3 normal;
    float4 tangent;
    float2 uv;
    float4 color;
};

struct SceneUniforms {
    float4x4 viewProjectionMatrix;
    float4x4 shadowViewProjectionMatrix;
    float4x4 modelMatrix;
    float4 lightDirection;
    float4 sunColor;
    float4 cameraPosition;
    float4 fogColor;
    float4 lightingParameters;
    float4 atmosphereParameters;
    float4 shadowParameters;
};

struct SceneMaterialUniforms {
    float4 baseColorFactor;
    float4 channelFactors;
};

struct ScenePostProcessUniforms {
    float4 exposureParameters;
    float4 shadowTint;
    float4 highlightTint;
    float4 gradeParameters;
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
    float4 tangent;
    float3 worldPosition;
    float4 shadowPosition;
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
    out.tangent = float4(
        normalize((uniforms.modelMatrix * float4(inVertex.tangent.xyz, 0.0)).xyz),
        inVertex.tangent.w
    );
    out.worldPosition = worldPosition.xyz;
    out.shadowPosition = uniforms.shadowViewProjectionMatrix * worldPosition;
    out.uv = inVertex.uv;
    return out;
}

vertex float4 bootstrapShadowVertexMain(
    uint vertexID [[vertex_id]],
    constant SceneVertex *vertices [[buffer(0)]],
    constant SceneUniforms &uniforms [[buffer(1)]]
) {
    SceneVertex inVertex = vertices[vertexID];
    float4 worldPosition = uniforms.modelMatrix * float4(inVertex.position, 1.0);
    return uniforms.shadowViewProjectionMatrix * worldPosition;
}

float sampleShadowVisibility(
    float4 shadowPosition,
    float3 normal,
    float3 lightDirection,
    constant SceneUniforms &uniforms,
    depth2d<float> shadowTexture,
    sampler shadowSampler
) {
    float shadowStrength = clamp(uniforms.shadowParameters.x, 0.0, 1.0);
    if (shadowStrength <= 0.001 || shadowPosition.w <= 0.0001) {
        return 1.0;
    }

    float3 projected = shadowPosition.xyz / shadowPosition.w;
    float2 uv = projected.xy * 0.5 + 0.5;
    float depth = projected.z * 0.5 + 0.5;
    if (
        uv.x <= 0.001 || uv.x >= 0.999 ||
        uv.y <= 0.001 || uv.y >= 0.999 ||
        depth <= 0.0 || depth >= 1.0
    ) {
        return 1.0;
    }

    float texelSize = max(uniforms.shadowParameters.z, 1.0 / 8192.0);
    float receiverBias = max(uniforms.shadowParameters.y, 0.0);
    float grazing = 1.0 - saturate(dot(normalize(normal), lightDirection));
    float comparisonDepth = saturate(depth - (receiverBias * (0.45 + grazing * 0.55)));

    float visibility = 0.0;
    visibility += shadowTexture.sample_compare(shadowSampler, uv, comparisonDepth);
    visibility += shadowTexture.sample_compare(shadowSampler, uv + float2(texelSize, 0.0), comparisonDepth);
    visibility += shadowTexture.sample_compare(shadowSampler, uv + float2(0.0, texelSize), comparisonDepth);
    visibility += shadowTexture.sample_compare(shadowSampler, uv + float2(texelSize, texelSize), comparisonDepth);
    visibility *= 0.25;

    return 1.0 - ((1.0 - visibility) * shadowStrength);
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
    constant SceneMaterialUniforms &material [[buffer(2)]],
    texture2d<float> albedoTexture [[texture(0)]],
    texture2d<float> normalTexture [[texture(1)]],
    texture2d<float> roughnessTexture [[texture(2)]],
    texture2d<float> ambientOcclusionTexture [[texture(3)]],
    depth2d<float> shadowTexture [[texture(4)]],
    sampler surfaceSampler [[sampler(0)]],
    sampler shadowSampler [[sampler(1)]]
) {
    float4 sampledAlbedo = albedoTexture.sample(surfaceSampler, in.uv);
    float4 sampledNormal = normalTexture.sample(surfaceSampler, in.uv);
    float sampledRoughness = roughnessTexture.sample(surfaceSampler, in.uv).r;
    float sampledAmbientOcclusion = ambientOcclusionTexture.sample(surfaceSampler, in.uv).r;

    float3 lightDirection = normalize(-uniforms.lightDirection.xyz);
    float3 viewDirection = normalize(uniforms.cameraPosition.xyz - in.worldPosition);
    float3 geometricNormal = normalize(in.normal);
    float3 tangent = normalize(in.tangent.xyz - (geometricNormal * dot(geometricNormal, in.tangent.xyz)));
    float3 bitangent = normalize(cross(geometricNormal, tangent)) * in.tangent.w;
    float3 tangentSpaceNormal = normalize((sampledNormal.xyz * 2.0) - 1.0);
    tangentSpaceNormal.xy *= material.channelFactors.z;
    float3x3 tangentFrame = float3x3(tangent, bitangent, geometricNormal);
    float3 shadedNormal = normalize(tangentFrame * tangentSpaceNormal);
    float3 halfVector = normalize(lightDirection + viewDirection);
    float3 baseColor = in.color.rgb * material.baseColorFactor.rgb * sampledAlbedo.rgb;
    float diffuse = clamp(dot(shadedNormal, lightDirection), 0.0, 1.0);
    float roughness = clamp(sampledRoughness * material.channelFactors.x, 0.04, 1.0);
    float ambientOcclusion = mix(1.0, sampledAmbientOcclusion, material.channelFactors.y);
    float ambientIntensity = uniforms.lightingParameters.x;
    float diffuseIntensity = uniforms.lightingParameters.y;
    float fogNear = uniforms.lightingParameters.z;
    float fogFar = uniforms.lightingParameters.w;
    float hazeStrength = max(uniforms.atmosphereParameters.x, 0.0);
    float specularPower = mix(128.0, 10.0, roughness);
    float specularStrength = mix(0.16, 0.02, roughness);
    float specular = pow(clamp(dot(shadedNormal, halfVector), 0.0, 1.0), specularPower) * specularStrength * diffuse;
    float3 ambient = baseColor * ambientIntensity * ambientOcclusion;
    float shadowVisibility = sampleShadowVisibility(
        in.shadowPosition,
        shadedNormal,
        lightDirection,
        uniforms,
        shadowTexture,
        shadowSampler
    );
    float3 sunContribution = baseColor * diffuse * diffuseIntensity * uniforms.sunColor.rgb;
    float3 specularContribution = uniforms.sunColor.rgb * specular * diffuseIntensity;
    float3 litColor = ambient + ((sunContribution + specularContribution) * shadowVisibility);

    float fogDistance = distance(in.worldPosition, uniforms.cameraPosition.xyz);
    float fogFactor = smoothstep(fogNear, max(fogFar, fogNear + 0.001), fogDistance);
    float heightFog = clamp((uniforms.cameraPosition.y - in.worldPosition.y) * 0.035, 0.0, 0.35);
    fogFactor = clamp(fogFactor + (heightFog * hazeStrength), 0.0, 1.0);

    return float4(
        mix(litColor, uniforms.fogColor.rgb, fogFactor),
        in.color.a * material.baseColorFactor.a * sampledAlbedo.a
    );
}

float postLuminance(float3 color) {
    return dot(color, float3(0.2126, 0.7152, 0.0722));
}

float3 applyPostSaturation(float3 color, float saturation) {
    float luminance = postLuminance(color);
    return mix(float3(luminance), color, saturation);
}

float3 applyPostContrast(float3 color, float contrast) {
    return saturate((color - 0.5) * contrast + 0.5);
}

float3 filmicToneMap(float3 color) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return saturate((color * (a * color + b)) / (color * (c * color + d) + e));
}

float3 linearToSRGB(float3 color) {
    float3 positive = max(color, 0.0);
    float3 low = positive * 12.92;
    float3 high = 1.055 * pow(positive, float3(1.0 / 2.4)) - 0.055;
    return select(low, high, positive >= 0.0031308);
}

fragment float4 postProcessFragmentMain(
    SkyVertexOut in [[stage_in]],
    constant ScenePostProcessUniforms &uniforms [[buffer(0)]],
    texture2d<float> sceneTexture [[texture(0)]],
    sampler postSampler [[sampler(0)]]
) {
    float2 uv = saturate(in.uv);
    float3 hdrColor = max(sceneTexture.sample(postSampler, uv).rgb, 0.0);
    float exposure = exp2(uniforms.exposureParameters.x);
    float whitePoint = max(uniforms.exposureParameters.y, 0.001);
    float contrast = max(uniforms.exposureParameters.z, 0.0);
    float saturation = max(uniforms.exposureParameters.w, 0.0);
    float shadowBalance = clamp(uniforms.gradeParameters.x, 0.05, 0.95);
    float vignetteStrength = clamp(uniforms.gradeParameters.y, 0.0, 1.0);

    float3 graded = hdrColor * exposure;
    graded /= whitePoint;
    graded = filmicToneMap(graded);

    float luminance = postLuminance(graded);
    float shadowWeight = 1.0 - smoothstep(max(shadowBalance - 0.30, 0.0), shadowBalance, luminance);
    float highlightWeight = smoothstep(shadowBalance, min(shadowBalance + 0.35, 1.0), luminance);

    graded *= mix(float3(1.0), uniforms.shadowTint.rgb, shadowWeight * 0.22);
    graded *= mix(float3(1.0), uniforms.highlightTint.rgb, highlightWeight * 0.18);
    graded = applyPostSaturation(graded, saturation);
    graded = applyPostContrast(graded, contrast);

    float2 centered = uv * 2.0 - 1.0;
    float vignette = 1.0 - smoothstep(0.40, 1.35, dot(centered, centered)) * vignetteStrength;
    graded *= vignette;

    return float4(linearToSRGB(graded), 1.0);
}
