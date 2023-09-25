Shader "Skybox/SkyboxGradient"
{
    Properties
    {
        _SkyRiseColor ("Sky Rise Color", Color) = (0,0,0,0)
        _FogRiseColor ("Fog Rise Color", Color) = (0,0,0,0)
        _SunRiseColor ("Sun Rise Color", Color) = (0,0,0,0)

        _SkyNoonColor ("Sky Noon Color", Color) = (0,0,0,0)
        _FogNoonColor ("Fog Noon Color", Color) = (0,0,0,0)
        _SunNoonColor ("Sun Noon Color", Color) = (0,0,0,0)

        _SkySetColor ("Sky Set Color", Color) = (0,0,0,0)
        _FogSetColor ("Fog Set Color", Color) = (0,0,0,0)
        _SunSetColor ("Sun Set Color", Color) = (0,0,0,0)

        _SkyNightColor ("Sky Night Color", Color) = (0,0,0,0)
        _FogNightColor ("Fog Night Color", Color) = (0,0,0,0)
        _SunNightColor ("Sun Night Color", Color) = (0,0,0,0)

        _ColorBlending ("Color blending", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "QUEUE"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
        LOD 0
        ZWrite Off
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float3 worldPos : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            // -----------------------------------------------------------------
            // Vertex Program

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            // -----------------------------------------------------------------
            // Fragment Program

            float4 _SkyRiseColor;
            float4 _FogRiseColor;
            float4 _SunRiseColor;

            float4 _SkyNoonColor;
            float4 _FogNoonColor;
            float4 _SunNoonColor;

            float4 _SkySetColor;
            float4 _FogSetColor;
            float4 _SunSetColor;

            float4 _SkyNightColor;
            float4 _FogNightColor;
            float4 _SunNightColor;

            float _ColorBlending;

            // source: https://stackoverflow.com/questions/3451553/value-remapping
            float remap(float value, float low1, float high1, float low2, float high2)
            {
                return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // lerp colors depending on world time
                float3 bottom = _FogNoonColor.rgb;
                float3 top = _SkyNoonColor.rgb;

                // TODO: lerp gradients: rise -> noon -> set -> night -> rise ...

                // color gradient for the sky
                float y = normalize(i.worldPos).y;
                y = remap(y, -1, 1, 0, 1);
                y = pow(y, _ColorBlending);
                float3 skyColor = lerp(bottom, top, y);

                return fixed4(skyColor, 1);
            }
            ENDCG
        }
    }

    Fallback Off
}
