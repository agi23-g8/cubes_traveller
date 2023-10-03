Shader "Universal Render Pipeline/Custom/ProceduralGrass"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _TipColor("Tip Color", Color) = (1, 1, 1, 1)
        _BladeTexture("Blade Texture", 2D) = "white" {}

        _BladeWidthMin("Blade Width (Min)", Range(0, 0.1)) = 0.02
        _BladeWidthMax("Blade Width (Max)", Range(0, 0.1)) = 0.05
        _BladeHeightMin("Blade Height (Min)", Range(0, 2)) = 0.1
        _BladeHeightMax("Blade Height (Max)", Range(0, 2)) = 0.2

        _BladeSegments("Blade Segments", Range(1, 10)) = 3
        _BladeBendDistance("Blade Forward Amount", Range(-0.5, 0.5)) = 0.25
        _BladeBendCurve("Blade Curvature Amount", Range(1, 4)) = 2

        _BendDelta("Bend Variation", Range(0, 1)) = 0.2
        _TessellationGrassDistance("Tessellation Grass Distance", Range(0.01, 0.5)) = 0.1

        _GrassMap("Grass Visibility Map", 2D) = "white" {}
        _GrassThreshold("Grass Visibility Threshold", Range(-0.1, 1)) = 0.5
        _GrassFalloff("Grass Visibility Fade-In Falloff", Range(0, 0.5)) = 0.05

        _WindMap("Wind Offset Map", 2D) = "bump" {}
        _WindVelocity("Wind Velocity", Vector) = (1, 0, 0, 0)
        _WindFrequency("Wind Pulse Frequency", Range(0, 1)) = 0.01
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
            "RenderPipeline" = "UniversalPipeline"
            "UniversalMaterialType" = "Lit"
            "IgnoreProjector" = "True"
        }
        LOD 300
        Cull Off

        HLSLINCLUDE

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

            /*********************************
            *        Vertex attributes       *
            *********************************/
            struct VertexAttributes
            {
                float4 position : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texCoord : TEXCOORD0;

                float2 staticLightmapUV : TEXCOORD1;
                float2 dynamicLightmapUV : TEXCOORD2;
            };

            /*********************************
            *         Shader varyings        *
            *********************************/
            struct VertexVaryings
            {
                float4 position  : SV_POSITION;
                float3 normal  : NORMAL;
                float4 tangent : TANGENT;
                float2 uv      : TEXCOORD0;

                #ifdef LIGHTMAP_ON
                    float2 staticLightmapUV : TEXCOORD2;
                #endif

                #ifdef DYNAMICLIGHTMAP_ON
                    float2 dynamicLightmapUV : TEXCOORD3;
                #endif
            };

            struct TessellationFactors
            {
                float edge[3] : SV_TessFactor;
                float inside  : SV_InsideTessFactor;
            };

            struct GeometryVaryings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS   : NORMAL;
                float2 uv         : TEXCOORD0;
                float3 positionWS : TEXCOORD1;

                #ifdef LIGHTMAP_ON
                    float2 staticLightmapUV : TEXCOORD2;
                #else
                    half3 vertexSH : TEXCOORD2;
                #endif

                #ifdef DYNAMICLIGHTMAP_ON
                    float2 dynamicLightmapUV : TEXCOORD3;
                #endif
            };

            /*********************************
            *        Shader resources        *
            *********************************/
            #define UNITY_PI 3.14159265359f
            #define UNITY_TWO_PI 6.28318530718f
            #define BLADE_SEGMENTS 4

            sampler2D _BladeTexture;
            sampler2D _GrassMap;
            sampler2D _WindMap;

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _TipColor;

                float _BladeWidthMin;
                float _BladeWidthMax;
                float _BladeHeightMin;
                float _BladeHeightMax;

                float _BladeBendDistance;
                float _BladeBendCurve;

                float _BendDelta;
                float _TessellationGrassDistance;
                
                float  _GrassThreshold;
                float  _GrassFalloff;

                float4 _WindMap_ST;
                float4 _WindVelocity;
                float  _WindFrequency;
            CBUFFER_END

            /*********************************
            *         Shader helpers         *
            *********************************/

            // Simple noise function, sourced from http://answers.unity.com/answers/624136/view.html
            // Extended discussion on this function can be found at the following link:
            // https://forum.unity.com/threads/am-i-over-complicating-this-random-function.454887/#post-2949326
            // Returns a number in the 0...1 range.
            float GenerateRandom(float3 _seed)
            {
                return frac(sin(dot(_seed, float3(12.9898, 78.233, 53.539))) * 43758.5453);
            }

            // Construct a rotation matrix that rotates around the provided axis, sourced from:
            // https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
            float3x3 BuildRotationMatrix(float _angle, float3 _axis)
            {
                float s, c;
                sincos(_angle, s, c);

                float t = 1 - c;
                float x = _axis.x;
                float y = _axis.y;
                float z = _axis.z;

                return float3x3
                (
                    t * x * x + c, t * x * y - s * z, t * x * z + s * y,
                    t * x * y + s * z, t * y * y + c, t * y * z - s * x,
                    t * x * z - s * y, t * y * z + s * x, t * z * z + c
                );
            }

            // Geometry functions derived from Roystan's tutorial:
            // https://roystan.net/articles/grass-shader.html
            // This function applies a transformation (during the geometry shader),
            // converting to clip space in the process.
            GeometryVaryings TransformGeomToClip(float3 _origin, float3 _normal, float3 _offset, float3x3 _transform, float2 _uv, float2 _staticLightmapUV, float2 _dynamicLightmapUV)
            {
                GeometryVaryings varyings;

                varyings.positionCS = TransformObjectToHClip(_origin + mul(_transform, _offset));
                varyings.uv = _uv;

                varyings.positionWS = TransformObjectToWorld(_origin + mul(_transform, _offset));
                varyings.normalWS = TransformObjectToWorldNormal(_normal);

                #ifdef LIGHTMAP_ON
                    varyings.staticLightmapUV = _staticLightmapUV;
                #else
                    OUTPUT_SH(varyings.normalWS, varyings.vertexSH);
                #endif

                #ifdef DYNAMICLIGHTMAP_ON
                    varyings.dynamicLightmapUV = _dynamicLightmapUV;
                #endif

                return varyings;
            }

            // This function lets us derive the tessellation factor for an edge
            // from the vertices.
            float TessellationEdgeFactor(VertexAttributes _vertexA, VertexAttributes _vertexB)
            {
                float3 v0 = _vertexA.position.xyz;
                float3 v1 = _vertexB.position.xyz;
                float edgeLength = distance(v0, v1);
                return edgeLength / _TessellationGrassDistance;
            }

            // The patch constant function is where we create new control
            // points on the patch. For the edges, increasing the tessellation
            // factors adds new vertices on the edge. Increasing the inside
            // will add more 'layers' inside the new triangle.
            TessellationFactors PatchConstantFunction(InputPatch<VertexAttributes, 3> _patch)
            {
                TessellationFactors f;
                f.edge[0] = TessellationEdgeFactor(_patch[1], _patch[2]);
                f.edge[1] = TessellationEdgeFactor(_patch[2], _patch[0]);
                f.edge[2] = TessellationEdgeFactor(_patch[0], _patch[1]);
                f.inside = (f.edge[0] + f.edge[1] + f.edge[2]) / 3.0f;
                return f;
            }

        ENDHLSL

        // GBUFFER PASS
        Pass
        {
            Name "GBuffer"
            Tags { "LightMode" = "UniversalGBuffer" }

            HLSLPROGRAM
            #pragma target 4.5

            // Deferred Rendering Path does not support the OpenGL-based graphics APIs
            #pragma exclude_renderers gles3 glcore
            
            // Make sure geometry and tesselation shaders are supported.
            #pragma require geometry
            #pragma require tessellation tessHW

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"

            // -------------------------------------
            // Shader Stages
            #pragma vertex   GBufferPassVertex
            #pragma hull     GBufferPassHull
            #pragma domain   GBufferPassDomain
            #pragma geometry GBufferPassGeometry
            #pragma fragment GBufferPassFragment

            /*********************************
            *          Vertex shader         *
            *********************************/
            VertexVaryings GBufferPassVertex(VertexAttributes _attributes)
            {
                VertexVaryings varyings = (VertexVaryings)0;

                varyings.position = _attributes.position;
                varyings.normal = _attributes.normal;
                varyings.tangent = _attributes.tangent;
                varyings.uv = _attributes.texCoord;

                // static GI
                #ifdef LIGHTMAP_ON
                    OUTPUT_LIGHTMAP_UV(_attributes.staticLightmapUV, unity_LightmapST, varyings.staticLightmapUV);
                #endif

                // dynamic GI
                #ifdef DYNAMICLIGHTMAP_ON
                    OUTPUT_LIGHTMAP_UV(_attributes.dynamicLightmapUV, unity_DynamicLightmapST, varyings.dynamicLightmapUV);
                #endif

                return varyings;
            }

            /*********************************
            *    Tesselation hull shader     *
            *********************************/
            // The hull function is the first half of the tessellation shader.
            // It operates on each patch (in our case, a patch is a triangle),
            // and outputs new control points for the other tessellation stages.
            [domain("tri")]
            [outputcontrolpoints(3)]
            [outputtopology("triangle_cw")]
            [partitioning("integer")]
            [patchconstantfunc("PatchConstantFunction")]
            VertexAttributes GBufferPassHull(InputPatch<VertexAttributes, 3> _patch, uint _id : SV_OutputControlPointID)
            {
                return _patch[_id];
            }

            /*********************************
            *   Tesselation domain shader    *
            *********************************/
            // The domain function is the second half of the tessellation shader.
            // It interpolates the properties of the vertices (position, normal, etc.)
            // to create new vertices.
            [domain("tri")]
            VertexVaryings GBufferPassDomain(TessellationFactors _factors, OutputPatch<VertexAttributes, 3> _patch, float3 _barycentricCoordinates : SV_DomainLocation)
            {
                VertexAttributes vertex;

                #define INTERPOLATE(fieldname) vertex.fieldname = \
                    _patch[0].fieldname * _barycentricCoordinates.x + \
                    _patch[1].fieldname * _barycentricCoordinates.y + \
                    _patch[2].fieldname * _barycentricCoordinates.z;

                INTERPOLATE(position)
                INTERPOLATE(normal)
                INTERPOLATE(tangent)
                INTERPOLATE(texCoord)

                return GBufferPassVertex(vertex);
            }

            /*********************************
            *         Geometry shader        *
            *********************************/
            [maxvertexcount(BLADE_SEGMENTS * 2 + 1)]
            void GBufferPassGeometry(point VertexVaryings _input[1], inout TriangleStream<GeometryVaryings> _triStream_)
            {
                float2 uv = _input[0].uv;
                float grassVisibility = tex2Dlod(_GrassMap, float4(uv, 0, 0)).r;

                if (grassVisibility >= _GrassThreshold)
                {
                    float3 origin = _input[0].position.xyz;
                    float3 normal = _input[0].normal;
                    float4 tangent = _input[0].tangent;
                    float3 bitangent = cross(normal, tangent.xyz) * tangent.w;

                    float2 staticLightmapUV = float2(0, 0);
                    #if LIGHTMAP_ON
                        staticLightmapUV = _input[0].staticLightmapUV;
                    #endif

                    float2 dynamicLightmapUV = float2(0, 0);
                    #if DYNAMICLIGHTMAP_ON
                        dynamicLightmapUV = _input[0].dynamicLightmapUV;
                    #endif

                    float3x3 tangentToLocal = float3x3
                    (
                        tangent.x, bitangent.x, normal.x,
                        tangent.y, bitangent.y, normal.y,
                        tangent.z, bitangent.z, normal.z
                    );

                    // Rotate around the y-axis a random amount.
                    float3x3 randRotMatrix = BuildRotationMatrix(GenerateRandom(origin) * UNITY_TWO_PI, float3(0, 0, 1.0f));

                    // Rotate around the bottom of the blade a random amount.
                    float3x3 randBendMatrix = BuildRotationMatrix(GenerateRandom(origin.zzx) * _BendDelta * UNITY_PI * 0.5f, float3(-1.0f, 0, 0));

                    float2 windUV = origin.xz * _WindMap_ST.xy + _WindMap_ST.zw + normalize(_WindVelocity.xzy) * _WindFrequency * _Time.y;
                    float2 windSample = tex2Dlod(_WindMap, float4(windUV, 0, 0)).xy;
                    windSample = 2 * windSample - 1;
                    windSample *= length(_WindVelocity);
                    float3 windAxis = normalize(float3(windSample.x, windSample.y, 0));

                    // Rotate around wind matrix.
                    float3x3 windMatrix = BuildRotationMatrix(UNITY_PI * windSample, windAxis);

                    // Transform the grass blades to the correct tangent space.
                    float3x3 baseTransformationMatrix = mul(tangentToLocal, randRotMatrix);
                    float3x3 tipTransformationMatrix = mul(mul(mul(tangentToLocal, windMatrix), randBendMatrix), randRotMatrix);

                    float falloff = smoothstep(_GrassThreshold, _GrassThreshold + _GrassFalloff, grassVisibility);

                    float width  = lerp(_BladeWidthMin, _BladeWidthMax, GenerateRandom(origin.xzy) * falloff);
                    float height = lerp(_BladeHeightMin, _BladeHeightMax, GenerateRandom(origin.zyx) * falloff) * grassVisibility;
                    float forward = GenerateRandom(origin.yyz) * _BladeBendDistance;

                    // Create blade segments by adding two vertices at once.
                    for (int i = 0; i < BLADE_SEGMENTS; ++i)
                    {
                        float t = i / (float)BLADE_SEGMENTS;
                        float3 offset = float3(width * (1 - t), pow(t, _BladeBendCurve) * forward, height * t);

                        float3x3 transform = (i == 0) ? baseTransformationMatrix : tipTransformationMatrix;

                        _triStream_.Append(TransformGeomToClip(origin, normal, float3( offset.x, offset.y, offset.z), transform, float2(0, t), staticLightmapUV, dynamicLightmapUV));
                        _triStream_.Append(TransformGeomToClip(origin, normal, float3(-offset.x, offset.y, offset.z), transform, float2(1, t), staticLightmapUV, dynamicLightmapUV));
                    }

                    // Add the final vertex at the tip of the grass blade.
                    _triStream_.Append(TransformGeomToClip(origin, normal, float3(0, forward, height), tipTransformationMatrix, float2(0.5, 1), staticLightmapUV, dynamicLightmapUV));
                    _triStream_.RestartStrip();
                }
            }

            /*********************************
            *         Fragment shader        *
            *********************************/
            FragmentOutput GBufferPassFragment(GeometryVaryings _varyings)
            {
                // SURFACE DATA
                SurfaceData surfaceData = (SurfaceData)0;
                {
                    float4 color = tex2D(_BladeTexture, _varyings.uv);
                    color *= lerp(_BaseColor, _TipColor, _varyings.uv.y);

                    surfaceData.albedo = color;
                    surfaceData.normalTS = float3(0.f, 0.f, 1.f);
                    surfaceData.smoothness = 0.f;
                    surfaceData.occlusion = 1.f;

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
                    inputData.normalWS = _varyings.normalWS;
                    inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(_varyings.positionWS);
                    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(_varyings.positionCS);

                    #if defined(LIGHTMAP_ON)
                        inputData.shadowMask = SAMPLE_SHADOWMASK(_varyings.staticLightmapUV);
                    #else
                        inputData.shadowMask = float4(0, 0, 0, 0);
                    #endif

                    #ifdef _MAIN_LIGHT_SHADOWS
                        inputData.shadowCoord = TransformWorldToShadowCoord(_varyings.positionWS);
                    #else
                        inputData.shadowCoord = float4(0, 0, 0, 0);
                    #endif

                    #if defined(DYNAMICLIGHTMAP_ON)
                        inputData.bakedGI = SAMPLE_GI(_varyings.staticLightmapUV, _varyings.dynamicLightmapUV, _varyings.vertexSH, inputData.normalWS);
                    #else
                        inputData.bakedGI = SAMPLE_GI(_varyings.staticLightmapUV, _varyings.vertexSH, inputData.normalWS);
                    #endif

                    // we don't want vertex lighting support
                    inputData.vertexLighting = half3(0, 0, 0);

                    // we don't apply fog in the gbuffer pass
                    inputData.fogCoord = 0;
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

        // SHADOW PASS : todo...
        // Pass
        // {
        // }

    }

    Fallback  "Hidden/Universal Render Pipeline/FallbackError"
}
