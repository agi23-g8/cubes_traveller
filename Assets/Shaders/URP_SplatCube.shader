Shader "Universal Render Pipeline/Custom/SplatCube"
{
    Properties
    {
        // material textures
        _txSplatMap ("SplatMap", 2D) = "black" {}
        _txAlbedoMaps ("AlbedoMaps", 2DArray) = "" {}
        _txNormalMaps ("NormalMaps", 2DArray) = "" {}
        _txRoughMaps ("RoughMaps", 2DArray) = "" {}
        _txCavityMaps ("CavityMaps", 2DArray) = "" {}

        // material params
        _sliceCount ("Slice Count", Range(1,256)) = 256
        _detailUvScale ("Detail UV Scale", Float) = 10.0

        // material toogles
        [Toggle(APPLY_ALBEDO)] _applyAlbedo ("Apply Albedo", Float) = 1
        [Toggle(APPLY_NORMAL)] _applyNormal ("Apply Normals", Float) = 1
        [Toggle(APPLY_ROUGHNESS)] _applyRoughness ("Apply Roughness", Float) = 1
        [Toggle(APPLY_CAVITY)] _applyCavity ("Apply Cavity", Float) = 1

        // unity lighting
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "UniversalMaterialType" = "SimpleLit"
            "IgnoreProjector" = "True"
        }

        LOD 300

        // SHADOW PASS
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            // -------------------------------------
            // Pipeline states
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
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
                float3 position : POSITION;
                float3 normal : NORMAL;
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
            // Debug keywords
            #pragma multi_compile_fragment _ APPLY_ALBEDO
            #pragma multi_compile_fragment _ APPLY_NORMAL
            #pragma multi_compile_fragment _ APPLY_ROUGHNESS
            #pragma multi_compile_fragment _ APPLY_CAVITY

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"

            /*********************************
            *        Vertex attributes       *
            *********************************/
            struct Attributes
            {
                float3 position : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texCoord : TEXCOORD0;
                float2 staticLightmapUV : TEXCOORD1;
                float2 dynamicLightmapUV : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            /*********************************
            *         Shader varyings        *
            *********************************/
            struct Varyings
            {
                float2 baseUV : TEXCOORD0;
                float2 detailUV : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
                float3 tangentWS : TEXCOORD4;
                float3 bitangentWS : TEXCOORD5;

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    float4 shadowCoord : TEXCOORD6;
                #endif

                DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 7);

                #ifdef DYNAMICLIGHTMAP_ON
                    float2 dynamicLightmapUV : TEXCOORD8;
                #endif

                float4 positionCS : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            /*********************************
            *         Shader resources       *
            *********************************/
            TEXTURE2D(_txSplatMap);

            TEXTURE2D_ARRAY(_txAlbedoMaps);
            SAMPLER(sampler_txAlbedoMaps);

            TEXTURE2D_ARRAY(_txNormalMaps);
            SAMPLER(sampler_txNormalMaps);

            TEXTURE2D_ARRAY(_txRoughMaps);
            SAMPLER(sampler_txRoughMaps);

            TEXTURE2D_ARRAY(_txCavityMaps);
            SAMPLER(sampler_txCavityMaps);

            CBUFFER_START(cbMaterial)
                half4 _txSplatMap_TexelSize;
                int _sliceCount;
                float _detailUvScale;
            CBUFFER_END

            /*********************************
            *     Splat material helpers     *
            *********************************/
            struct MaterialSample
            {
                float3 albedo;
                float3 normal;
                float roughness;
                float cavity;
            };

            /// fetches current material index from the splat map
            uint FetchMaterialIndex(in int2 _iuv)
            {
                const float range = max(0, float(_sliceCount - 1));
                const float normIndex = LOAD_TEXTURE2D_LOD(_txSplatMap, _iuv, 0).r;
                return uint(min(range, range * normIndex + 0.5)); // '+0.5' is to avoid approximation errors
            }

            /// fetches PBR material values from texture maps (albedo, normal, roughness, cavity)
            MaterialSample FetchMaterialValues(in uint _matIndex, in float2 _uv, in float2 _uvDx, in float2 _uvDy)
            {
                MaterialSample mat;

                #if APPLY_ALBEDO
                    mat.albedo = SAMPLE_TEXTURE2D_ARRAY_GRAD(_txAlbedoMaps, sampler_txAlbedoMaps, _uv, _matIndex, _uvDx, _uvDy).rgb;
                #else
                    mat.albedo = float3(1, 1, 1);
                #endif

                #if APPLY_NORMAL
                    mat.normal = UnpackNormal(SAMPLE_TEXTURE2D_ARRAY_GRAD(_txNormalMaps, sampler_txNormalMaps, _uv, _matIndex, _uvDx, _uvDy));
                #else
                    mat.normal = float3(0, 0, 1);
                #endif

                #if APPLY_ROUGHNESS
                    mat.roughness = SAMPLE_TEXTURE2D_ARRAY_GRAD(_txRoughMaps, sampler_txRoughMaps, _uv, _matIndex, _uvDx, _uvDy).r;
                #else
                    mat.roughness = 1.f;
                #endif

                #if APPLY_CAVITY
                    mat.cavity = SAMPLE_TEXTURE2D_ARRAY_GRAD(_txCavityMaps, sampler_txCavityMaps, _uv, _matIndex, _uvDx, _uvDy).r;
                #else
                    mat.cavity = 1.f;
                #endif

                return mat;
            }

            /// performs linear blending between given material values
            MaterialSample LerpMaterial(in MaterialSample _mat1, in MaterialSample _mat2, in float _weight)
            {
                MaterialSample res;

                // lerp albedo in linear space
                const float3 linearAlbedo1 = SRGBToLinear(_mat1.albedo);
                const float3 linearAlbedo2 = SRGBToLinear(_mat2.albedo);
                res.albedo = LinearToSRGB(lerp(linearAlbedo1, linearAlbedo2, _weight));

                // other material properties are already in linear space
                res.normal = lerp(_mat1.normal, _mat2.normal, _weight);
                res.roughness = lerp(_mat1.roughness, _mat2.roughness, _weight);
                res.cavity = lerp(_mat1.cavity, _mat2.cavity, _weight);

                return res;
            }

            /// samples the detail material without filtering
            MaterialSample SampleNearestMaterial(in float2 _uv, in float2 _uvDetail)
            {
                const float2 textureDims = _txSplatMap_TexelSize.zw;
                const int2 iuv = int2(_uv * textureDims);
                const uint matIndex = FetchMaterialIndex(iuv);

                const float2 uvDx = ddx_coarse(_uvDetail);
                const float2 uvDy = ddy_coarse(_uvDetail);
                return FetchMaterialValues(matIndex, _uvDetail, uvDx, uvDy);
            }

            // samples the detail material with bilinear filtering
            MaterialSample SampleBilinearMaterial(in float2 _uv, in float2 _uvDetail)
            {
                const float2 textureDims = _txSplatMap_TexelSize.zw;
                const float2 floatIuv = _uv * textureDims - float2(0.5, 0.5);
                const int2 iuv = int2(floatIuv);

                // manually compute the weight to perform bilinear filtering
                const float coeffX = frac(floatIuv.x);
                const float coeffY =  frac(floatIuv.y);

                const uint matIndex00 = FetchMaterialIndex(iuv + int2(0, 0));
                const uint matIndex01 = FetchMaterialIndex(iuv + int2(0, 1));
                const uint matIndex10 = FetchMaterialIndex(iuv + int2(1, 0));
                const uint matIndex11 = FetchMaterialIndex(iuv + int2(1, 1));

                const float2 uvDx = ddx_coarse(_uvDetail);
                const float2 uvDy = ddy_coarse(_uvDetail);

                // early discard when dealing with a single material
                if ((matIndex00 == matIndex10) && (matIndex01 == matIndex11) && (matIndex00 == matIndex01))
                {
                    return FetchMaterialValues(matIndex00, _uvDetail, uvDx, uvDy);
                }

                MaterialSample mat00 = FetchMaterialValues(matIndex00, _uvDetail, uvDx, uvDy);

                if (matIndex00 != matIndex10)
                {
                    const MaterialSample mat10 = FetchMaterialValues(matIndex10, _uvDetail, uvDx, uvDy);
                    mat00 = LerpMaterial(mat00, mat10, coeffX);
                }

                MaterialSample mat01 = FetchMaterialValues(matIndex01, _uvDetail, uvDx, uvDy);

                if (matIndex01 != matIndex11)
                {
                    const MaterialSample mat11 = FetchMaterialValues(matIndex11, _uvDetail, uvDx, uvDy);
                    mat01 = LerpMaterial(mat01, mat11, coeffX);
                }

                return LerpMaterial(mat00, mat01, coeffY);
            }

            /*********************************
            *          Vertex shader         *
            *********************************/
            Varyings GBufferPassVertex(Attributes _attributes)
            {
                Varyings varyings = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(_attributes);
                UNITY_TRANSFER_INSTANCE_ID(_attributes, varyings);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(varyings);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(_attributes.position);
                VertexNormalInputs normalInput = GetVertexNormalInputs(_attributes.normal, _attributes.tangent);

                // UV
                varyings.baseUV = _attributes.texCoord;
                varyings.detailUV = _attributes.texCoord * _detailUvScale;

                // position
                varyings.positionWS = vertexInput.positionWS;
                varyings.positionCS = vertexInput.positionCS;

                // normal
                varyings.normalWS = normalInput.normalWS;
                varyings.tangentWS = normalInput.tangentWS;
                varyings.bitangentWS = normalInput.bitangentWS;

                // lighting
                OUTPUT_SH(varyings.normalWS, varyings.vertexSH);
                OUTPUT_LIGHTMAP_UV(_attributes.staticLightmapUV, unity_LightmapST, varyings.staticLightmapUV);
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
                    //MaterialSample mat = SampleNearestMaterial(_varyings.baseUV, _varyings.detailUV);
                    MaterialSample mat = SampleBilinearMaterial(_varyings.baseUV, _varyings.detailUV);

                    surfaceData.albedo = mat.albedo;
                    surfaceData.normalTS = mat.normal;
                    surfaceData.smoothness = 1.f - mat.roughness;
                    surfaceData.occlusion = mat.cavity;

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

                    #if defined(DYNAMICLIGHTMAP_ON)
                        inputData.bakedGI = SAMPLE_GI(_varyings.staticLightmapUV, _varyings.dynamicLightmapUV, _varyings.vertexSH, inputData.normalWS);
                    #else
                        inputData.bakedGI = SAMPLE_GI(_varyings.staticLightmapUV, _varyings.vertexSH, inputData.normalWS);
                    #endif

                    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(_varyings.positionCS);
                    inputData.shadowMask = SAMPLE_SHADOWMASK(_varyings.staticLightmapUV);

                    #if defined(DEBUG_DISPLAY)
                        #if defined(DYNAMICLIGHTMAP_ON)
                            inputData.dynamicLightmapUV = _varyings.dynamicLightmapUV;
                        #endif
                        #if defined(LIGHTMAP_ON)
                            inputData.staticLightmapUV = _varyings.staticLightmapUV;
                        #else
                            inputData.vertexSH = _varyings.vertexSH;
                        #endif
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
