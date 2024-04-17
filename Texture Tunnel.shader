Shader "!nextrix/FX/Texture Tunnel v0.1"
{
    Properties
    {
        [NoScaleOffset]_MainTex ("Texture", 2D) = "white" {}
        _Alpha ("Alpha", range(0,1)) = 1
        _Speed ("Speed", float) = 1
        _SpeedOffset ("Speed Offset", float) = 0
        _scale ("Scale", float) = 63.66
        _Vignette ("Vignette", range(0,1)) = 0
        [Space(20)]
        [Toggle()]_PARTICLE ("Use PS", int) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Float) = 8
        [Enum(UnityEngine.Rendering.BlendMode)] _SourceBlend ("Source Blend", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DestinationBlend ("Destination Blend", Float) = 10
        [Enum(Off, 0, On, 1)] _ZWrite ("ZWrite", Int) = 0

    }
    SubShader
    {
        LOD 100
        ZWrite [_ZWrite]
        Cull [_Cull]
        ZTest [_ZTest]
        Blend [_SourceBlend] [_DestinationBlend]
        Tags{ "LightMode" = "Always""RenderType" = "Overlay"  "Queue" = "Overlay+32000""IsEmissive" = "true" "DisableBatching"= "true" "ForceNoShadowCasting" = "true" "IgnoreProjector" = "true" "PreviewType"="Plane"} 

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            uniform int _PARTICLE;

            struct appdata
            {
                float4 vertex		: POSITION;
                float4 vertexColor	: COLOR;
                float3 cen			: TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex		: SV_POSITION;
                float3 uv			: TEXCOORD0;
                float vertexColor : COLOR;
            };

            inline bool IsInMirror()
            {
                return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
            }

            inline float3 cPos()
            {
                #if UNITY_SINGLE_PASS_STEREO
                    return (unity_StereoWorldSpaceCameraPos[0] + unity_StereoWorldSpaceCameraPos[1]) * 0.5;
                #else
                    return _WorldSpaceCameraPos;
                #endif
            }

            v2f vert(appdata v)
            {
                v2f o;
                float4 pos = 0.0, cen = 0.0;
                float dist = 0.0;
                UNITY_BRANCH if (_PARTICLE)
                {
                    pos = mul(unity_WorldToObject, mul(unity_CameraToWorld, v.vertex - float4(v.cen, 0)));
                    dist = distance(cPos(), v.cen);
                    cen = float4(v.cen, 1.0);
                    o.vertexColor = v.vertexColor.w;
                }
                else
                {
                    pos = mul(unity_WorldToObject, mul(unity_CameraToWorld, v.vertex));
                    dist = distance(cPos(), mul(unity_ObjectToWorld, float4(0.0, 0.0, 0.0, 1.0)));
                    cen = float4(0.0, 0.0, 0.0, 1.0);
                    o.vertexColor = 1.0;
                }
                o.vertex = UnityObjectToClipPos(pos);
                o.uv = mul(UNITY_MATRIX_V, mul(unity_ObjectToWorld, pos).xyz - cPos());
                if (IsInMirror())
                    o.vertex = 0.0;
                return o;
            }

            uniform float _Speed, _SpeedOffset, _Alpha, _scale, _Vignette;
            sampler2D _MainTex;

            fixed4 frag (v2f i) : SV_Target
            {
                
                float _distance = _scale / 10.;
                float2 uv = (i.uv.xy / abs(i.uv.z));
                uv.xy *= _ScreenParams.x / _ScreenParams.y;
                float2 v = float2(.1, .1) * _Time.y * _Speed + (_SpeedOffset / 10.) + float2(
                    atan2(uv.y, uv.x) * _distance / 8,
                    .3 / sqrt(length(uv)) * _distance
                );
                float2 vigUV = uv;
                float vignette = saturate(length(vigUV) - lerp(-1,2,_Vignette));

                return tex2D(_MainTex, v) * vignette * _Alpha;
            }
            ENDCG
        }
    }
}
