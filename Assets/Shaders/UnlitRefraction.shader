Shader "Custom/RefractionShader"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _Refraction ("Refraction Strength", Range(0, 1)) = 0.5
        _Distortion ("Distortion", Range(0, 1)) = 0.1
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent" "RenderType"="Transparent"
        }
        LOD 200

        GrabPass
        {
            "_GrabTexture"
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float4 grabPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _GrabTexture;
            float _Refraction;
            float _Distortion;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.grabPos = ComputeGrabScreenPos(o.pos);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float3 viewDir = normalize(i.viewDir);
                float3 normal = normalize(i.normal);
                float3 refractDir = refract(viewDir, normal, _Refraction);
                float2 refractedUV = i.grabPos.xy / i.grabPos.w + _Distortion * refractDir.xy;
                float4 grabbed = tex2Dproj(_GrabTexture, float4(refractedUV, 0, 1));
                float4 baseColor = tex2D(_MainTex, i.uv);
                float4 finalColor = lerp(baseColor, grabbed, 0.5);

                return finalColor;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}