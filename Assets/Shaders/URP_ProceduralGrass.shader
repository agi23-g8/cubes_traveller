Shader "Universal Render Pipeline/Custom/ProceduralGrass"
{
    Properties
    {
        [Header(# Grass color)][Space(10)]
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _TipColor("Tip Color", Color) = (1, 1, 1, 1)
        [NoScaleOffset]_BladeTexture("Blade Texture", 2D) = "white" {}

        [Space(10)][Header(# Grass geometry)][Space(10)]
        _BladeWidthMin("Blade Width (Min)", Range(0, 0.1)) = 0.02
        _BladeWidthMax("Blade Width (Max)", Range(0, 0.1)) = 0.05
        _BladeHeightMin("Blade Height (Min)", Range(0, 2)) = 0.1
        _BladeHeightMax("Blade Height (Max)", Range(0, 2)) = 0.2
        _BladeSegments("Blade Segments", Range(1, 10)) = 3
        _BladeBendDistance("Blade Forward Amount", Range(-0.5, 0.5)) = 0.25
        _BladeBendCurve("Blade Curvature Amount", Range(1, 4)) = 2
        _BladeBendVariation("Blade Bend Variation", Range(0, 1)) = 0.2

        [Space(10)][Header(# Grass visibility)][Space(10)]
        _GrassTessellationDistance("Grass Density", Range(0.005, 0.05)) = 0.02
        _GrassThreshold("Visibility Threshold", Range(-0.1, 1)) = 0.5
        _GrassFalloff("Visibility Fade-In Falloff", Range(0, 0.5)) = 0.05
        [NoScaleOffset]_GrassMap("Visibility Map", 2D) = "white" {}

        [Space(10)][Header(# Wind displacement)][Space(10)]
        _WindVelocity("Wind Velocity", Vector) = (1, 0, 0, 0)
        _WindFrequency("Wind Pulse Frequency", Range(0, 1)) = 0.01
        [NoScaleOffset]_WindMap("Wind Offset Map", 2D) = "bump" {}

        [Space(10)][Header(# Player displacement)][Space(10)]
        _BendIntensity("Bend Intensity", Range(0, 10)) = 3.0
        _BendInfluenceRadius("Bend Influence Radius", Range(0, 0.5)) = 0.15

        [Space(10)][Header(# Lighting)][Space(10)]
        [Toggle(COMPUTE_LIGHTING)] _ComputeLighting("Compute Lighting", Float) = 0
        _ShadowIntensity("Shadow Intensity", Range(0, 1)) = 1.0
        _ShadowTessellation("Shadow Tessellation", Range(0, 1)) = 0.5

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
            // Shader constants
            #define UNITY_PI 3.14159265359f
            #define UNITY_TWO_PI 6.28318530718f
            #define BLADE_SEGMENTS 4

            // -------------------------------------
            // Global parameters
            uniform float3 _PlayerPosition;

            // -------------------------------------
            // Material textures
            sampler2D _BladeTexture;
            sampler2D _GrassMap;
            sampler2D _WindMap;

            // -------------------------------------
            // Material buffer
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _TipColor;

                float _BladeWidthMin;
                float _BladeWidthMax;
                float _BladeHeightMin;
                float _BladeHeightMax;
                float _BladeBendDistance;
                float _BladeBendCurve;
                float _BladeBendVariation;

                float _GrassTessellationDistance;
                float _GrassThreshold;
                float _GrassFalloff;

                float _ShadowIntensity;
                float _ShadowTessellation;

                float4 _WindMap_ST;
                float4 _WindVelocity;
                float  _WindFrequency;

                float _BendIntensity;
                float _BendInfluenceRadius;
            CBUFFER_END

            // -------------------------------------
            // Helper functions

            // Simple noise function returning a float in [0, 1], sourced from:
            // http://answers.unity.com/answers/624136/view.html
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
            Cull Off
            ColorMask 0

            HLSLPROGRAM
            #pragma target 2.0

            // Deferred Rendering Path does not support the OpenGL-based graphics APIs
            #pragma exclude_renderers gles3 glcore
            
            // Make sure geometry and tessellation shaders are supported.
            #pragma require geometry
            #pragma require tessellation tessHW

            // -------------------------------------
            // Shader Stages
            #pragma vertex   ShadowPassVertex
            #pragma hull     ShadowPassHull
            #pragma domain   ShadowPassDomain
            #pragma geometry ShadowPassGeometry
            #pragma fragment ShadowPassFragment

            // this is used during shadow map generation to differentiate between directional 
            // and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_geometry _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            // -------------------------------------
            // Custom keywords
            #pragma multi_compile_geometry _ COMPUTE_LIGHTING

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            // Shadow casting light geometric parameters. These variables are used when applying the shadow normal bias and are 
            // set by ShadowUtils::SetupShadowCasterConstantBuffer in com.unity.render-pipelines.universal/Runtime/ShadowUtils.cs
            float3 _LightDirection;
            float3 _LightPosition;

            // -------------------------------------
            // Shader structures

            struct VertexAttributes
            {
                float4 position : POSITION;
                float3 normal   : NORMAL;
                float4 tangent  : TANGENT;
                float2 texCoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexVaryings
            {
                float4 position : SV_POSITION;
                float3 normal   : NORMAL;
                float4 tangent  : TANGENT;
                float2 uv       : TEXCOORD0;
            };

            struct TessellationFactors
            {
                float edge[3] : SV_TessFactor;
                float inside  : SV_InsideTessFactor;
            };

            struct GeometryVaryings
            {
                float4 positionCS : SV_POSITION;
            };

            // -------------------------------------
            // Helper functions

            // This function lets us derive the tessellation factor for an edge from the vertices.
            float TessellationEdgeFactor(VertexAttributes _vertexA, VertexAttributes _vertexB)
            {
                float3 v0 = _vertexA.position.xyz;
                float3 v1 = _vertexB.position.xyz;
                float edgeLength = distance(v0, v1);
                return _ShadowTessellation * edgeLength / _GrassTessellationDistance;
            }

            // The patch constant function is where we create new control points on the patch. For the edges, increasing the tessellation
            // factors will add new vertices on the edge. Increasing the inside will add more 'layers' inside the new triangle.
            TessellationFactors PatchConstantFunction(InputPatch<VertexAttributes, 3> _patch)
            {
                TessellationFactors f;
                f.edge[0] = TessellationEdgeFactor(_patch[1], _patch[2]);
                f.edge[1] = TessellationEdgeFactor(_patch[2], _patch[0]);
                f.edge[2] = TessellationEdgeFactor(_patch[0], _patch[1]);
                f.inside = (f.edge[0] + f.edge[1] + f.edge[2]) / 3.0f;
                return f;
            }

            // Geometry functions derived from Roystan's tutorial: https://roystan.net/articles/grass-shader.html
            // This function applies a transformation (during the geometry shader), converting to clip space in the process.
            GeometryVaryings TransformGeomToClip(float3 _origin, float3 _normal, float3 _offset, float3x3 _transform)
            {
                GeometryVaryings varyings;

                float3 localPosition = _origin + mul(_transform, _offset);
                float3 positionWS = TransformObjectToWorld(localPosition);

            #if defined(COMPUTE_LIGHTING)
                float3 localNormal = normalize(mul(_transform, _normal));
                float3 normalWS = TransformObjectToWorldNormal(localNormal);
            #else
                float3 normalWS = TransformObjectToWorldNormal(_normal);
            #endif

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
            *          Vertex shader         *
            *********************************/
            VertexVaryings ShadowPassVertex(VertexAttributes _attributes)
            {
                VertexVaryings varyings;
                UNITY_SETUP_INSTANCE_ID(_attributes);

                varyings.position = _attributes.position;
                varyings.normal = _attributes.normal;
                varyings.tangent = _attributes.tangent;
                varyings.uv = _attributes.texCoord;

                return varyings;
            }

            /*********************************
            *      Tessellation shader       *
            *********************************/

            // The hull function is the first half of the tessellation shader. It operates on each patch (in our 
            // case, a patch is a triangle), and outputs new control points for the other tessellation stages.
            [domain("tri")]
            [outputcontrolpoints(3)]
            [outputtopology("triangle_cw")]
            [partitioning("integer")]
            [patchconstantfunc("PatchConstantFunction")]
            VertexAttributes ShadowPassHull(InputPatch<VertexAttributes, 3> _patch, uint _id : SV_OutputControlPointID)
            {
                return _patch[_id];
            }

            // The domain function is the second half of the tessellation shader. It interpolates 
            // the properties of the vertices (position, normal, etc.) to create new vertices.
            [domain("tri")]
            VertexVaryings ShadowPassDomain(TessellationFactors _factors, OutputPatch<VertexAttributes, 3> _patch, float3 _barycentricCoordinates : SV_DomainLocation)
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

                return ShadowPassVertex(vertex);
            }

            /*********************************
            *         Geometry shader        *
            *********************************/
            [maxvertexcount(BLADE_SEGMENTS * 2 + 1)]
            void ShadowPassGeometry(point VertexVaryings _input[1], inout TriangleStream<GeometryVaryings> _triStream_)
            {
                float2 uv = _input[0].uv;
                float grassVisibility = tex2Dlod(_GrassMap, float4(uv, 0, 0)).r;

                // Early discards when the grass threshold is not reached.
                if (grassVisibility < _GrassThreshold)
                {
                    return;
                }

                // local space vectors
                float3 origin = _input[0].position.xyz;
                float3 normal = _input[0].normal;
                float4 tangent = _input[0].tangent;
                float3 bitangent = cross(normal, tangent.xyz) * tangent.w;

                float3x3 tangentToLocal = float3x3
                (
                    tangent.x, bitangent.x, normal.x,
                    tangent.y, bitangent.y, normal.y,
                    tangent.z, bitangent.z, normal.z
                );

                // Rotate around the y-axis a random amount.
                float3x3 randRotMatrix = BuildRotationMatrix(GenerateRandom(origin) * UNITY_TWO_PI, float3(0, 0, 1.0f));

                // Rotate around the bottom of the blade a random amount.
                float3x3 randBendMatrix = BuildRotationMatrix(GenerateRandom(origin.zzx) * _BladeBendVariation * UNITY_PI * 0.5f, float3(-1.0f, 0, 0));

                // Apply wind displacement.
                float2 windUV = origin.xz * _WindMap_ST.xy + _WindMap_ST.zw + normalize(_WindVelocity.xzy) * _WindFrequency * _Time.y;
                float2 windSample = tex2Dlod(_WindMap, float4(windUV, 0, 0)).xy;
                windSample = 2 * windSample - 1;
                windSample *= length(_WindVelocity);
                float3 windAxis = normalize(float3(windSample.x, windSample.y, 0));
                float3x3 windMatrix = BuildRotationMatrix(UNITY_PI * windSample, windAxis);

                // Apply player displacement.
                float3 playerToBladeVector = origin - mul(unity_WorldToObject, _PlayerPosition);
                float bendIntensity = _BendIntensity * smoothstep(_BendInfluenceRadius, 0.f, length(playerToBladeVector));
                float3 bendAxis = normalize(float3(dot(playerToBladeVector, tangent), dot(playerToBladeVector, bitangent), 0));
                float3x3 playerBendMatrix = BuildRotationMatrix(bendIntensity * UNITY_PI * 0.5f, bendAxis);

                // Transform the grass blades to the correct tangent space.
                float3x3 baseTransformationMatrix = mul(tangentToLocal, randRotMatrix);
                float3x3 tipTransformationMatrix = mul(mul(mul(mul(tangentToLocal, windMatrix), playerBendMatrix), randBendMatrix), randRotMatrix);

                float falloff = smoothstep(_GrassThreshold, _GrassThreshold + _GrassFalloff, grassVisibility);
                float width = lerp(_BladeWidthMin, _BladeWidthMax, GenerateRandom(origin.xzy) * falloff) * _ShadowIntensity;
                float height = lerp(_BladeHeightMin, _BladeHeightMax, GenerateRandom(origin.zyx) * falloff);
                float forward = GenerateRandom(origin.yyz) * _BladeBendDistance;
                float exponent = _BladeBendCurve;

                // Create blade segments by adding two vertices at once.
                for (int i = 0; i < BLADE_SEGMENTS; ++i)
                {
                    float t = i / (float)BLADE_SEGMENTS;
                    float3x3 transform = (i == 0) ? baseTransformationMatrix : tipTransformationMatrix;

                    // - The blade curve lies in the YZ plane (tangent space)
                    // - Its parametric equation is C(t) -> [y = forward * t^(exponent), z = height * t]
                    // - The blade width is inversely proportional to its height
                    float3 offset;
                    offset.x = width * (1 - t);
                    offset.y = pow(t, exponent) * forward;
                    offset.z = height * t;

                #if defined(COMPUTE_LIGHTING)
                    // - The curve tangent is equal to the curbe derivative : [forward * exponent * t^(exponent - 1), height]
                    // - The normal can then be obtained by rotating the tangent at 90° : (-tanZ, tanY)
                    float3 normalT;
                    normalT.x = 0.f;
                    normalT.y = -height;
                    normalT.z = forward * exponent * pow(t, max(0.01, exponent - 1));
                    normalT = normalize(normalT);
                #else
                    float3 normalT = normal;
                #endif

                    _triStream_.Append(TransformGeomToClip(origin, normalT, float3( offset.x, offset.y, offset.z), transform));
                    _triStream_.Append(TransformGeomToClip(origin, normalT, float3(-offset.x, offset.y, offset.z), transform));
                }

                // Add the final vertex (t = 1) at the tip of the grass blade.
                {
                    float3 offset;
                    offset.x = 0.f;
                    offset.y = forward;
                    offset.z = height;

                #if defined(COMPUTE_LIGHTING)
                    float3 normalT;
                    normalT.x = 0.f;
                    normalT.y = -height;
                    normalT.z = forward * exponent;
                    normalT = normalize(normalT);
                #else
                    float3 normalT = normal;
                #endif

                    _triStream_.Append(TransformGeomToClip(origin, normalT, offset, tipTransformationMatrix));
                    _triStream_.RestartStrip();
                }
            }

            /*********************************
            *         Fragment shader        *
            *********************************/
            half4 ShadowPassFragment(GeometryVaryings _varyings) : SV_TARGET
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
            Cull Off

            HLSLPROGRAM
            #pragma target 4.5

            // Deferred Rendering Path does not support the OpenGL-based graphics APIs
            #pragma exclude_renderers gles3 glcore
            
            // Make sure geometry and tessellation shaders are supported.
            #pragma require geometry
            #pragma require tessellation tessHW

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

            // -------------------------------------
            // Custom keywords
            #pragma multi_compile_geometry _ COMPUTE_LIGHTING
            #pragma multi_compile_fragment _ COMPUTE_LIGHTING

            // -------------------------------------
            // Shader Stages
            #pragma vertex   GBufferPassVertex
            #pragma hull     GBufferPassHull
            #pragma domain   GBufferPassDomain
            #pragma geometry GBufferPassGeometry
            #pragma fragment GBufferPassFragment

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"

            // -------------------------------------
            // Shader structures

            struct VertexAttributes
            {
                float4 position : POSITION;
                float3 normal   : NORMAL;
                float4 tangent  : TANGENT;
                float2 texCoord : TEXCOORD0;

                float2 staticLightmapUV : TEXCOORD1;
                float2 dynamicLightmapUV : TEXCOORD2;
            };

            struct VertexVaryings
            {
                float4 position : SV_POSITION;
                float3 normal   : NORMAL;
                float4 tangent  : TANGENT;
                float2 uv       : TEXCOORD0;

                #if defined(LIGHTMAP_ON)
                    float2 staticLightmapUV : TEXCOORD1;
                #endif

                #if defined(DYNAMICLIGHTMAP_ON)
                    float2 dynamicLightmapUV : TEXCOORD2;
                #endif

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
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

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    float4 shadowCoord : TEXCOORD2;
                #endif

                #if defined(LIGHTMAP_ON)
                    float2 staticLightmapUV : TEXCOORD3;
                #else
                    half3 vertexSH : TEXCOORD3;
                #endif

                #if defined(DYNAMICLIGHTMAP_ON)
                    float2 dynamicLightmapUV : TEXCOORD4;
                #endif
            };

            // -------------------------------------
            // Helper functions

            // This function lets us derive the tessellation factor for an edge from the vertices.
            float TessellationEdgeFactor(VertexAttributes _vertexA, VertexAttributes _vertexB)
            {
                float3 v0 = _vertexA.position.xyz;
                float3 v1 = _vertexB.position.xyz;
                float edgeLength = distance(v0, v1);
                return edgeLength / _GrassTessellationDistance;
            }

            // The patch constant function is where we create new control points on the patch. For the edges, increasing the tessellation
            // factors will add new vertices on the edge. Increasing the inside will add more 'layers' inside the new triangle.
            TessellationFactors PatchConstantFunction(InputPatch<VertexAttributes, 3> _patch)
            {
                TessellationFactors f;
                f.edge[0] = TessellationEdgeFactor(_patch[1], _patch[2]);
                f.edge[1] = TessellationEdgeFactor(_patch[2], _patch[0]);
                f.edge[2] = TessellationEdgeFactor(_patch[0], _patch[1]);
                f.inside = (f.edge[0] + f.edge[1] + f.edge[2]) / 3.0f;
                return f;
            }

            // Geometry functions derived from Roystan's tutorial: https://roystan.net/articles/grass-shader.html
            // This function applies a transformation (during the geometry shader), converting to clip space in the process.
            GeometryVaryings TransformGeomToClip(float3 _origin, float3 _normal, float3 _offset, float3x3 _transform, float2 _uv, float2 _staticLightmapUV, float2 _dynamicLightmapUV)
            {
                GeometryVaryings varyings;
                varyings.uv = _uv;

                float3 localPosition = _origin + mul(_transform, _offset);
                varyings.positionWS = TransformObjectToWorld(localPosition);
                varyings.positionCS = TransformObjectToHClip(localPosition);

            #if defined(COMPUTE_LIGHTING)
                float3 localNormal = normalize(mul(_transform, _normal));
                varyings.normalWS = TransformObjectToWorldNormal(localNormal);
            #else
                varyings.normalWS = TransformObjectToWorldNormal(_normal);
            #endif

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    #if defined(_MAIN_LIGHT_SHADOWS_SCREEN)
                        varyings.shadowCoord =  ComputeScreenPos(varyings.positionCS);
                    #else
                        varyings.shadowCoord = TransformWorldToShadowCoord(varyings.positionWS);
                    #endif
                #endif

                #if defined(LIGHTMAP_ON)
                    varyings.staticLightmapUV = _staticLightmapUV;
                #else
                    OUTPUT_SH(varyings.normalWS, varyings.vertexSH);
                #endif

                #if defined(DYNAMICLIGHTMAP_ON)
                    varyings.dynamicLightmapUV = _dynamicLightmapUV;
                #endif

                return varyings;
            }

            /*********************************
            *          Vertex shader         *
            *********************************/
            VertexVaryings GBufferPassVertex(VertexAttributes _attributes)
            {
                VertexVaryings varyings = (VertexVaryings)0;

                UNITY_SETUP_INSTANCE_ID(_attributes);
                UNITY_TRANSFER_INSTANCE_ID(_attributes, varyings);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(varyings);

                varyings.position = _attributes.position;
                varyings.normal = _attributes.normal;
                varyings.tangent = _attributes.tangent;
                varyings.uv = _attributes.texCoord;

                // static GI
                #if defined(LIGHTMAP_ON)
                    OUTPUT_LIGHTMAP_UV(_attributes.staticLightmapUV, unity_LightmapST, varyings.staticLightmapUV);
                #endif

                // dynamic GI
                #if defined(DYNAMICLIGHTMAP_ON)
                    OUTPUT_LIGHTMAP_UV(_attributes.dynamicLightmapUV, unity_DynamicLightmapST, varyings.dynamicLightmapUV);
                #endif

                return varyings;
            }

            /*********************************
            *      Tessellation shader       *
            *********************************/

            // The hull function is the first half of the tessellation shader. It operates on each patch (in our 
            // case, a patch is a triangle), and outputs new control points for the other tessellation stages.
            [domain("tri")]
            [outputcontrolpoints(3)]
            [outputtopology("triangle_cw")]
            [partitioning("integer")]
            [patchconstantfunc("PatchConstantFunction")]
            VertexAttributes GBufferPassHull(InputPatch<VertexAttributes, 3> _patch, uint _id : SV_OutputControlPointID)
            {
                return _patch[_id];
            }

            // The domain function is the second half of the tessellation shader. It interpolates 
            // the properties of the vertices (position, normal, etc.) to create new vertices.
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

                // Early discards when the grass threshold is not reached.
                if (grassVisibility < _GrassThreshold)
                {
                    return;
                }

                // local space vectors
                float3 origin = _input[0].position.xyz;
                float3 normal = _input[0].normal;
                float4 tangent = _input[0].tangent;
                float3 bitangent = cross(normal, tangent.xyz) * tangent.w;

                #if defined(LIGHTMAP_ON)
                    float2 staticLightmapUV = _input[0].staticLightmapUV;
                #else
                    float2 staticLightmapUV = float2(0, 0);
                #endif

                #if defined(DYNAMICLIGHTMAP_ON)
                    float2 dynamicLightmapUV = _input[0].dynamicLightmapUV;
                #else
                    float2 dynamicLightmapUV = float2(0, 0);
                #endif

                float3x3 tangentToLocal = float3x3
                (
                    tangent.x, bitangent.x, normal.x,
                    tangent.y, bitangent.y, normal.y,
                    tangent.z, bitangent.z, normal.z
                );

                // Rotate the base around Z axis (local up) a random amount.
                float3x3 randRotMatrix = BuildRotationMatrix(GenerateRandom(origin) * UNITY_TWO_PI, float3(0, 0, 1.0f));

                // Rotate the tip around the base a random amount.
                float3x3 randBendMatrix = BuildRotationMatrix(GenerateRandom(origin.zzx) * _BladeBendVariation * UNITY_PI * 0.5f, float3(-1.0f, 0, 0));

                // Apply wind displacement.
                float2 windUV = origin.xz * _WindMap_ST.xy + _WindMap_ST.zw + normalize(_WindVelocity.xzy) * _WindFrequency * _Time.y;
                float2 windSample = tex2Dlod(_WindMap, float4(windUV, 0, 0)).xy;
                windSample = 2 * windSample - 1;
                windSample *= length(_WindVelocity);
                float3 windAxis = normalize(float3(windSample.x, windSample.y, 0));
                float3x3 windMatrix = BuildRotationMatrix(UNITY_PI * windSample, windAxis);

                // Apply player displacement.
                float3 playerToBladeVector = origin - mul(unity_WorldToObject, _PlayerPosition);
                float bendIntensity = _BendIntensity * smoothstep(_BendInfluenceRadius, 0.f, length(playerToBladeVector));
                float3 bendAxis = normalize(float3(dot(playerToBladeVector, tangent), dot(playerToBladeVector, bitangent), 0));
                float3x3 playerBendMatrix = BuildRotationMatrix(bendIntensity * UNITY_PI * 0.5f, bendAxis);

                // Transform the grass blades to the correct tangent space.
                float3x3 baseTransformationMatrix = mul(tangentToLocal, randRotMatrix);
                float3x3 tipTransformationMatrix = mul(mul(mul(mul(tangentToLocal, windMatrix), playerBendMatrix), randBendMatrix), randRotMatrix);

                float falloff = smoothstep(_GrassThreshold, _GrassThreshold + _GrassFalloff, grassVisibility);
                float width  = lerp(_BladeWidthMin, _BladeWidthMax, GenerateRandom(origin.xzy) * falloff);
                float height = lerp(_BladeHeightMin, _BladeHeightMax, GenerateRandom(origin.zyx) * falloff);
                float forward = GenerateRandom(origin.yyz) * _BladeBendDistance;
                float exponent = _BladeBendCurve;

                // Create blade segments by adding two vertices at once.
                for (int i = 0; i < BLADE_SEGMENTS; ++i)
                {
                    float t = i / (float)BLADE_SEGMENTS;
                    float3x3 transform = (i == 0) ? baseTransformationMatrix : tipTransformationMatrix;

                    // - The blade curve lies in the YZ plane (tangent space)
                    // - Its parametric equation is C(t) -> [y = forward * t^(exponent), z = height * t]
                    // - The blade width is inversely proportional to its height
                    float3 offset;
                    offset.x = width * (1 - t);
                    offset.y = pow(t, exponent) * forward;
                    offset.z = height * t;

                #if defined(COMPUTE_LIGHTING)
                    // - The curve tangent is equal to the curbe derivative : [forward * exponent * t^(exponent - 1), height]
                    // - The normal can then be obtained by rotating the tangent at 90° : (-tanZ, tanY)
                    float3 normalT;
                    normalT.x = 0.f;
                    normalT.y = -height;
                    normalT.z = forward * exponent * pow(t, max(0.01, exponent - 1));
                    normalT = normalize(normalT);
                #else
                    float3 normalT = normal;
                #endif

                    _triStream_.Append(TransformGeomToClip(origin, normalT, float3( offset.x, offset.y, offset.z), transform, float2(0, t), staticLightmapUV, dynamicLightmapUV));
                    _triStream_.Append(TransformGeomToClip(origin, normalT, float3(-offset.x, offset.y, offset.z), transform, float2(1, t), staticLightmapUV, dynamicLightmapUV));
                }

                // Add the final vertex (t = 1) at the tip of the grass blade.
                {
                    float3 offset;
                    offset.x = 0.f;
                    offset.y = forward;
                    offset.z = height;

                #if defined(COMPUTE_LIGHTING)
                    float3 normalT;
                    normalT.x = 0.f;
                    normalT.y = -height;
                    normalT.z = forward * exponent;
                    normalT = normalize(normalT);
                #else
                    float3 normalT = normal;
                #endif

                    _triStream_.Append(TransformGeomToClip(origin, normalT, offset, tipTransformationMatrix, float2(0.5, 1), staticLightmapUV, dynamicLightmapUV));
                    _triStream_.RestartStrip();
                }
            }

            /*********************************
            *         Fragment shader        *
            *********************************/
            FragmentOutput GBufferPassFragment(GeometryVaryings _varyings, bool _facing : SV_IsFrontFace)
            {
                UNITY_SETUP_INSTANCE_ID(_varyings);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(_varyings);

                // SURFACE DATA
                SurfaceData surfaceData = (SurfaceData)0;
                {
                    float4 color = tex2D(_BladeTexture, _varyings.uv);
                    color *= lerp(_BaseColor, _TipColor, _varyings.uv.y);
                    surfaceData.albedo = color.rgb;

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

                #if defined(COMPUTE_LIGHTING)
                    // Flip backfaces normals
                    inputData.normalWS = _facing ? _varyings.normalWS : -_varyings.normalWS;
                #else
                    inputData.normalWS =  _varyings.normalWS;
                #endif

                    // Derive view direction and screen UVs
                    inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(_varyings.positionWS);
                    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(_varyings.positionCS);

                    // Derive shadow map UVs
                    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                        inputData.shadowCoord = _varyings.shadowCoord;
                    #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                        inputData.shadowCoord = TransformWorldToShadowCoord(_varyings.positionWS);
                    #else
                        inputData.shadowCoord = float4(0, 0, 0, 0);
                    #endif

                    // static GI
                    #if defined(LIGHTMAP_ON)
                        inputData.shadowMask = SAMPLE_SHADOWMASK(_varyings.staticLightmapUV);
                    #else
                        inputData.shadowMask = float4(0, 0, 0, 0);
                    #endif

                    // dynamic GI
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

    }

    Fallback  "Hidden/Universal Render Pipeline/FallbackError"
}