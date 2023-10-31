Shader "Universal Render Pipeline/Custom/DeformableSnow"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [NoScaleOffset]_AlbedoMap("Albedo Map", 2D) = "white" {}
        [NoScaleOffset]_NormalMap("Normal Map", 2D) = "bump" {}
        [NoScaleOffset]_RoughMap ("Rough Map", 2D)  = "white" {}
        [NoScaleOffset]_CavityMap("Cabity Map", 2D) = "white" {}
        _DetailUvScale ("Detail UV Scale", Float) = 10.0

        _SnowHeight("Snow Height", Range(0,2)) = 0.3
        [NoScaleOffset]_SnowMap("Snow Map", 2D) = "white" {}

        _NoiseScale("Noise Scale", Range(0,50)) = 10
        _NoiseWeight("Noise Weight", Range(0, 0.1)) = 0.01
        [NoScaleOffset]_NoiseMap("Noise Map", 2D) = "gray" {}

        // unity lighting
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Geometry"
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "UniversalMaterialType" = "Lit"
            "IgnoreProjector" = "True"
        }

        LOD 300

        // COMMON
        HLSLINCLUDE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            // -------------------------------------
            // Material textures
            TEXTURE2D(_AlbedoMap);
            SAMPLER(sampler_AlbedoMap);
            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);
            TEXTURE2D(_RoughMap);
            SAMPLER(sampler_RoughMap);
            TEXTURE2D(_CavityMap);
            SAMPLER(sampler_CavityMap);

            TEXTURE2D(_NoiseMap);
            SAMPLER(sampler_NoiseMap);

            TEXTURE2D(_SnowMap);
            SAMPLER(sampler_SnowMap);

            // -------------------------------------
            // Material buffer
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float _SnowHeight;
                float _NormalScale;
                float _NoiseScale;
                float _NoiseWeight;
                float _DetailUvScale;
                half4 _SnowMap_TexelSize;
            CBUFFER_END


            // -------------------------------------
            // Shader helpers

            void ApplyHeightDeformation(
                inout float3 _position_, 
                inout float3 _normal_, 
                in float4 _tangent, 
                in float2 _uv)
            {
                float deformation = SAMPLE_TEXTURE2D_LOD(_SnowMap, sampler_SnowMap, _uv, 0).r;

                float3 groundNormal    = _normal_;
                float3 groundTangent   = _tangent;
                float3 groundBitangent = normalize(cross(groundNormal, groundTangent) * _tangent.w);

                float3x3 tangentToLocal = float3x3
                (
                    groundTangent.x, groundBitangent.x, groundNormal.x,
                    groundTangent.y, groundBitangent.y, groundNormal.y,
                    groundTangent.z, groundBitangent.z, groundNormal.z
                );

                // move local vertex up where snow is
                {
                    float snowNoise = _NoiseWeight * SAMPLE_TEXTURE2D_LOD(_NoiseMap, sampler_NoiseMap, _uv * _NoiseScale, 0).r;
                    float snowHeight = saturate(_SnowHeight + snowNoise);

                    _position_ += groundNormal * (1.f - deformation) * snowHeight;
                }

                // recompute normal using finite difference
                {
                    const float2 textureDims = _SnowMap_TexelSize.zw;
                    const int2 iuv = int2(textureDims * _uv);

                    float4 hs;
                    hs[0] = LOAD_TEXTURE2D_LOD(_SnowMap, iuv + int2( 0,-1), 0).r;
                    hs[1] = LOAD_TEXTURE2D_LOD(_SnowMap, iuv + int2( 0, 1), 0).r;
                    hs[2] = LOAD_TEXTURE2D_LOD(_SnowMap, iuv + int2(-1, 0), 0).r;
                    hs[3] = LOAD_TEXTURE2D_LOD(_SnowMap, iuv + int2( 1, 0), 0).r;

                    float3 normalT;
                    normalT.y = hs[1] - hs[0];
                    normalT.x = hs[3] - hs[2];
                    normalT.z = 0.05;
                    normalT = normalize(normalT);

                    _normal_ = normalize(mul(tangentToLocal, normalT));
                }
            }

        ENDHLSL

        // SHADOW PASS
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            // -------------------------------------
            // Pipeline states
            ZWrite On
            ZTest LEqual
            Cull Back
            ColorMask 0

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            // this is used during shadow map generation to differentiate between directional 
            // and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            // Shadow Casting Light geometric parameters.These variables are used when applying the shadow Normal Bias and are set by 
            // UnityEngine.Rendering.Universal.ShadowUtils.SetupShadowCasterConstantBuffer in com.unity.render-pipelines.universal/Runtime/ShadowUtils.cs
            float3 _LightDirection;
            float3 _LightPosition;

            /*********************************
            *        Vertex attributes       *
            *********************************/
            struct Attributes
            {
                float4 position : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texCoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            /*********************************
            *         Shader varyings        *
            *********************************/
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            /*********************************
            *          Vertex shader         *
            *********************************/
            Varyings ShadowPassVertex(Attributes _attributes)
            {
                Varyings varyings;
                UNITY_SETUP_INSTANCE_ID(_attributes);

                // Apply vertex deformation
                ApplyHeightDeformation(_attributes.position.xyz, _attributes.normal, _attributes.tangent, _attributes.texCoord);

                float3 positionWS = TransformObjectToWorld(_attributes.position);
                float3 normalWS = TransformObjectToWorldNormal(_attributes.normal);

                #if _CASTING_PUNCTUAL_LIGHT_SHADOW
                    float3 lightDirectionWS = normalize(_LightPosition - positionWS);
                #else
                    float3 lightDirectionWS = _LightDirection;
                #endif

                varyings.positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

                #if UNITY_REVERSED_Z
                    varyings.positionCS.z = min(varyings.positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #else
                    varyings.positionCS.z = max(varyings.positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #endif

                return varyings;
            }

            /*********************************
            *         Fragment shader        *
            *********************************/
            half4 ShadowPassFragment(Varyings _varyings) : SV_TARGET
            {
                return 0;
            }

            ENDHLSL
        }

        // GBUFFER PASS
        Pass
        {
            Name "GBuffer"
            Tags { "LightMode" = "UniversalGBuffer" }

            // -------------------------------------
            // Pipeline states
            ZWrite On
            ZTest LEqual
            Cull Back

            HLSLPROGRAM
            #pragma target 4.5

            // Deferred Rendering Path does not support the OpenGL-based graphics API
            #pragma exclude_renderers gles3 glcore

            // -------------------------------------
            // Shader Stages
            #pragma vertex GBufferPassVertex
            #pragma fragment GBufferPassFragment

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
            #pragma multi_compile_fragment _ _RENDER_PASS_ENABLED

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"

            /*********************************
            *        Vertex attributes       *
            *********************************/
            struct Attributes
            {
                float4 position : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texCoord : TEXCOORD0;

                #if defined(LIGHTMAP_ON)
                    float2 staticLightmapUV : TEXCOORD1;
                #endif

                #if defined(DYNAMICLIGHTMAP_ON)
                    float2 dynamicLightmapUV : TEXCOORD2;
                #endif

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            /*********************************
            *         Shader varyings        *
            *********************************/
            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 tangentWS : TEXCOORD3;
                float3 bitangentWS : TEXCOORD4;

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    float4 shadowCoord : TEXCOORD5;
                #endif

                #if defined(LIGHTMAP_ON)
                    float2 staticLightmapUV : TEXCOORD6;
                #else
                    half3 vertexSH : TEXCOORD6;
                #endif

                #if defined(DYNAMICLIGHTMAP_ON)
                    float2 dynamicLightmapUV : TEXCOORD7;
                #endif

                float4 positionCS : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            /*********************************
            *          Vertex shader         *
            *********************************/
            Varyings GBufferPassVertex(Attributes _attributes)
            {
                Varyings varyings = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(_attributes);
                UNITY_TRANSFER_INSTANCE_ID(_attributes, varyings);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(varyings);

                // Apply vertex deformation
                ApplyHeightDeformation(_attributes.position.xyz, _attributes.normal, _attributes.tangent, _attributes.texCoord);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(_attributes.position);
                VertexNormalInputs normalInput = GetVertexNormalInputs(_attributes.normal, _attributes.tangent);

                // UV
                varyings.uv = _attributes.texCoord;

                // position
                varyings.positionWS = vertexInput.positionWS;
                varyings.positionCS = vertexInput.positionCS;

                // normal
                varyings.normalWS = normalInput.normalWS;
                varyings.tangentWS = normalInput.tangentWS;
                varyings.bitangentWS = normalInput.bitangentWS;

                // static lighting
                #ifdef LIGHTMAP_ON
                    OUTPUT_LIGHTMAP_UV(_attributes.staticLightmapUV, unity_LightmapST, varyings.staticLightmapUV);
                #else
                    OUTPUT_SH(varyings.normalWS, varyings.vertexSH);
                #endif

                // dynamic lighting
                #ifdef DYNAMICLIGHTMAP_ON
                    OUTPUT_LIGHTMAP_UV(_attributes.dynamicLightmapUV, unity_DynamicLightmapST, varyings.dynamicLightmapUV);
                #endif

                // shadows
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    varyings.shadowCoord = GetShadowCoord(vertexInput);
                #endif

                return varyings;
            }

            /*********************************
            *         Fragment shader        *
            *********************************/
            FragmentOutput GBufferPassFragment(Varyings _varyings)
            {
                UNITY_SETUP_INSTANCE_ID(_varyings);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(_varyings);

                // SURFACE DATA
                SurfaceData surfaceData = (SurfaceData)0;
                {
                    float2 uv = _DetailUvScale * _varyings.uv;
                    float3 albedo = SAMPLE_TEXTURE2D(_AlbedoMap, sampler_AlbedoMap, uv).rgb;
                    float3 normal = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv));
                    float roughness = SAMPLE_TEXTURE2D(_RoughMap, sampler_RoughMap, uv).r;
                    float cavity = SAMPLE_TEXTURE2D(_CavityMap, sampler_CavityMap, uv).r;

                    surfaceData.albedo = albedo;
                    surfaceData.normalTS = normal;
                    surfaceData.smoothness = 1.f - roughness;
                    surfaceData.occlusion = cavity;

                    surfaceData.emission = half3(0, 0, 0);
                    surfaceData.specular = half3(0, 0, 0);
                    surfaceData.metallic = 0.0;
                    surfaceData.alpha = 1.0;
                }

                // INPUT DATA
                InputData inputData = (InputData)0;
                {
                    inputData.positionCS = _varyings.positionCS;
                    inputData.positionWS = _varyings.positionWS;
                    inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(_varyings.positionWS);
                    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(_varyings.positionCS);

                    float3x3 TBN = float3x3(_varyings.tangentWS, _varyings.bitangentWS, _varyings.normalWS);
                    float3 normalW = TransformTangentToWorld(surfaceData.normalTS, TBN);
                    inputData.normalWS = NormalizeNormalPerPixel(normalW);

                    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                        inputData.shadowCoord = _varyings.shadowCoord;
                    #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                        inputData.shadowCoord = TransformWorldToShadowCoord(_varyings.positionWS);
                    #else
                        inputData.shadowCoord = float4(0, 0, 0, 0);
                    #endif

                    // we don't want vertex lighting support
                    inputData.vertexLighting = half3(0, 0, 0);

                    // we don't apply fog in the gbuffer pass
                    inputData.fogCoord = 0;

                    #if defined(LIGHTMAP_ON)
                        inputData.shadowMask = SAMPLE_SHADOWMASK(_varyings.staticLightmapUV);
                    #else
                        inputData.shadowMask = float4(0, 0, 0, 0);
                    #endif

                    #if defined(DYNAMICLIGHTMAP_ON)
                        inputData.bakedGI = SAMPLE_GI(_varyings.staticLightmapUV, _varyings.dynamicLightmapUV, _varyings.vertexSH, inputData.normalWS);
                    #else
                        inputData.bakedGI = SAMPLE_GI(_varyings.staticLightmapUV, _varyings.vertexSH, inputData.normalWS);
                    #endif
                }

                // BRDF DATA
                BRDFData brdfData;
                InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);

                // GI COLOR
                half3 GIColor = half3(0, 0, 0);
                {
                    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, inputData.shadowMask);
                    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, inputData.shadowMask);
                    GIColor = GlobalIllumination(brdfData, inputData.bakedGI, surfaceData.occlusion, inputData.positionWS, inputData.normalWS, inputData.viewDirectionWS);
                }

                return BRDFDataToGbuffer(brdfData, inputData, surfaceData.smoothness, surfaceData.emission + GIColor, surfaceData.occlusion);
            }

            ENDHLSL
        }
    }

    Fallback  "Hidden/Universal Render Pipeline/FallbackError"
}