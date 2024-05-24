Shader "Custom/Crystal"
{
    Properties
    {
        _Color ("Specular Color", Color) = (1,0,0,1)
        _MainTex ("Texture", 2D) = "white" {}
        _TextureAlpha ("Texture Alpha", Range(0.0, 1.0)) = 1
        _Transparency ("Transparency", Range(0.0, 1.0)) = 0.2
        _Glossiness ("Glossiness", Range(0,1)) = 1
        _RimLightColor ("Rim Light Color", Color) = (1,1,1,1)
        _RimLightPower ("Rim Light Power", Range(0.0, 1.0)) = 1
        _Refraction ("Refraction Strength", Range(0.0, 1.0)) = 0.1
        _BlurAmount ("Blur Amount", Range(0.0, 1.0)) = 0.2
        _NoiseIntensity ("Noise Intensity", Range(0.0, 1.0)) = 0.1
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent" "Queue"="Transparent"
        }
        ZWrite On
        ZTest LEqual
        LOD 200

        GrabPass
        {
            "_GrabTexture"
        }

        CGPROGRAM
        #pragma surface surf StandardSpecular fullforwardshadows keepalpha
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _GrabTexture;
        sampler2D _NormalMap;

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir;
            float3 worldNormal;
            float3 worldPos;
            float4 screenPos;
            INTERNAL_DATA
        };

        fixed4 _Color;
        float _TextureAlpha;
        float _Transparency;
        half _Glossiness;
        fixed4 _RimLightColor;
        float _RimLightPower;
        float _Refraction;
        float _BlurAmount;
        float _NoiseIntensity;


        /**
         * Calculates the rim light effect
         **/
        float CalculateRimLight(float3 viewDir, float3 worldNormal)
        {
            float fresnel = pow(1.0 - dot(viewDir, worldNormal), 3);
            return fresnel * _RimLightPower;
        }
        
        /**
         * Calculates the Perlin noise
         **/
        float PerlinNoise(float2 uv)
        {
            return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
        }

        /**
         * Calculates the Gaussian blur
         **/
        float4 GaussianBlur(sampler2D tex, float2 uv, float2 resolution, float blurAmount)
        {
            float4 color = float4(0, 0, 0, 0);

            float2 texelSize = blurAmount / resolution;
            float2 offsets[9] = {
                float2(-1.0, 1.0), float2(0.0, 1.0), float2(1.0, 1.0),
                float2(-1.0, 0.0), float2(0.0, 0.0), float2(1.0, 0.0),
                float2(-1.0, -1.0), float2(0.0, -1.0), float2(1.0, -1.0)
            };

            float weights[9] = {
                1.0 / 16.0, 2.0 / 16.0, 1.0 / 16.0,
                2.0 / 16.0, 4.0 / 16.0, 2.0 / 16.0,
                1.0 / 16.0, 2.0 / 16.0, 1.0 / 16.0
            };

            for (int i = 0; i < 9; i++)
            {
                color += tex2D(tex, uv + offsets[i] * texelSize) * weights[i];
            }

            return color;
        }

        /**
         * Calculates the refraction texture with the grab pass texture
         **/
        float4 CaluculateRefractionTexture(float3 viewDir, float3 worldNormal, float4 screenPos)
        {
            float3 refractDir = refract(viewDir, worldNormal, 1);
            float2 refractedUV = screenPos.xy / screenPos.w + _Refraction * refractDir.xy;
            float2 resolution = float2(1.0, 1.0);
            
            float noise = PerlinNoise(refractedUV * _NoiseIntensity / 80);
            float2 noiseOffset = float2(noise, noise) * _NoiseIntensity / 80;
            refractedUV += noiseOffset;

            return GaussianBlur(_GrabTexture, refractedUV, resolution, _BlurAmount / 40);
        }

        void surf(Input IN, inout SurfaceOutputStandardSpecular o)
        {
            fixed4 mainText = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            fixed4 lerpedMainText = lerp(_Color, mainText, _TextureAlpha);
            float4 refractionText = CaluculateRefractionTexture(IN.viewDir, IN.worldNormal, IN.screenPos) * lerpedMainText;
            float4 finalColor = lerp(lerpedMainText, refractionText, _Transparency);

            o.Albedo = finalColor.rgb;
            o.Specular = finalColor.rgb;
            o.Smoothness = _Glossiness;
            o.Emission = CalculateRimLight(IN.viewDir, IN.worldNormal) * _RimLightColor;
        }
        ENDCG
    }
    FallBack "Diffuse"
}