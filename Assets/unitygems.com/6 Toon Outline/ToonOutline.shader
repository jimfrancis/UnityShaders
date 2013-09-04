// unitygems.com/noobs-guide-shaders-6-toon-shader/

// We want an outllined toon shader using simplified lighting and colors. To do this we need to:
//	- Draw an outline for the model
//	- Appply the toon shader principles to our vertex and fragment programs, i.e.
//			* Simplify the colors used in our model
//			* Simpligy the lighting so that we have well defined areas of light and dark

// One fo the building blocks of toon shading is that to draw an outline you can actually just render the part of the model you
// can't see (the back faces) scaled up in black. The idea goes that these will then be a good outline that isn't destroying the 
// fidelity of the front faces of your model
// So our first attempt at that will be to:
//		- write a pass that draws back faces only
//		- move all of the vertices so that they are bigger

Shader "unitygems.com/ToonOutline" {
	Properties {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _Bump ("Bump", 2D) = "bump" {}
        _ColorMerge ("Color Merge", Range(0.1,20000)) = 8
        _Ramp ("Ramp Texture", 2D) = "white" {}
        _Outline ("Outline", Range(0, 0.15)) = 0.08
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
						
		// a pass that draws only back faces 
		Pass {
			Cull Front
			Lighting Off
			ZWrite On
			Tags { "LightMode"="ForwardBase" } 
		
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
						
			// we need the input structures for the vertex and fragment parts of our shader.
			// We're going to expand the faces along the normal of each vertex - that's facing backwards and outwards from the point so should
			// provide a useful tool
			// All we really need then is the position and the normal for each vertex in the pass.
			struct a2v {
		        float4 vertex : POSITION;
		        float3 normal : NORMAL;
		        float3 tangent : TANGENT;
		    }; 
	 
			struct v2f {
				float4 pos : POSITION;
			};
			
			float _Outline;
			
			v2f vert (a2v v) {
				// * convert the vertex to view space
				// * convert the normal to view space
				// * fix the z element of the normal to some minimal value
				// * re-normalize the normal (we broke it in the previous step)
				// * scale the normal and add it on to the vertex position
				// * convert the vertex position into projection space
				
				v2f o;
				float4 pos = mul(UNITY_MATRIX_MV, v.vertex);
				float3 normal = mul( (float3x3)UNITY_MATRIX_IT_MV, v.normal);
				normal.z = -0.4;
				pos = pos + float4(normalize(normal), 0) * _Outline;
				o.pos = mul(UNITY_MATRIX_P, pos);
				return o;
			}
			
			// the fragment shader is the easy part, just always draw pixels in black
			float4 frag (v2f IN) : COLOR
		    {
		        return float4(0,0,0,1);
		    }
			
			ENDCG
		}
		
		Pass { 
            Cull Back 
            Lighting On
            Tags { "LightMode"="ForwardBase" }
 
            CGPROGRAM
// Upgrade NOTE: excluded shader from DX11 and Xbox360; has structs without semantics (struct v2f members lightDirection)
#pragma exclude_renderers d3d11 xbox360
            #pragma vertex vert
            #pragma fragment frag
 
            #include "UnityCG.cginc"
            uniform float4 _LightColor0;
 
            sampler2D _MainTex;
            sampler2D _Bump;
            sampler2D _Ramp;
 
            float4 _MainTex_ST;
            float4 _Bump_ST;
 
            float _Tooniness;
            float _ColorMerge;
 
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                float4 tangent : TANGENT;
 
            }; 
 
            struct v2f
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float3 lightDirection : TEXCOORD2;
 
            };
 
            v2f vert (a2v v)
            {
                v2f o;
                //Create a rotation matrix for tangent space
                TANGENT_SPACE_ROTATION; 
                //Store the light's direction in tangent space
                o.lightDirection = mul(rotation, ObjSpaceLightDir(v.vertex));
                //Transform the vertex to projection space
                o.pos = mul( UNITY_MATRIX_MVP, v.vertex); 
                //Get the UV coordinates
                o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);  
                o.uv2 = TRANSFORM_TEX (v.texcoord, _Bump);
                return o;
            }
 
            float4 frag(v2f i) : COLOR  
            { 
                //Get the color of the pixel from the texture
                float4 c = tex2D (_MainTex, i.uv);  
                //Merge the colours
                c.rgb = (floor(c.rgb*_ColorMerge)/_ColorMerge);
 
                //Get the normal from the bump map
                float3 n =  UnpackNormal(tex2D (_Bump, i.uv2)); 
 
                //Based on the ambient light
                float3 lightColor = UNITY_LIGHTMODEL_AMBIENT.xyz;
 
                //Work out this distance of the light
                float lengthSq = dot(i.lightDirection, i.lightDirection);
                //Fix the attenuation based on the distance
                float atten = 1.0 / (1.0 + lengthSq);
                //Angle to the light
                float diff = saturate (dot (n, normalize(i.lightDirection)));  
                //Perform our toon light mapping 
                diff = tex2D(_Ramp, float2(diff, 0.5));
                //Update the colour
                lightColor += _LightColor0.rgb * (diff * atten); 
                //Product the final color
                c.rgb = lightColor * c.rgb * 2;
                return c; 
 
            }  
            ENDCG
        }
        
        // Note: cant seem too get the ForwardAdd pass working, but not sure what Im doing wrong
        Pass { 
            Tags { "LightMode"="ForwardAdd" }
            Cull Back 
            Lighting On
			Blend One One
 
            CGPROGRAM
// Upgrade NOTE: excluded shader from DX11 and Xbox360; has structs without semantics (struct v2f members lightDirection)
#pragma exclude_renderers d3d11 xbox360
            #pragma vertex vert
            #pragma fragment frag
 
            #include "UnityCG.cginc"
            uniform float4 _LightColor0;
  
            sampler2D _MainTex;
            sampler2D _Bump;
            sampler2D _Ramp;
 
            float4 _MainTex_ST;
            float4 _Bump_ST;
 
            float _Tooniness;
            float _ColorMerge;
 
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                float4 tangent : TANGENT; 
            }; 
 
            struct v2f {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float3 lightDirection : TEXCOORD2;
 
            };
 
            v2f vert (a2v v) {
                v2f o;
                TANGENT_SPACE_ROTATION; 
                
                o.lightDirection = mul(rotation, ObjSpaceLightDir(v.vertex)); 
                o.pos = mul( UNITY_MATRIX_MVP, v.vertex); 
                o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);  
                o.uv2 = TRANSFORM_TEX (v.texcoord, _Bump);
                return o;
            }
 
 				 // We need to remove the refence to UNITY_AMBIIENT_LIGHT in our second pass copy of the fragment shader, because we've already
 				 // handled that in the first pass.
            float4 frag(v2f i) : COLOR { 
                float4 c = tex2D (_MainTex, i.uv); 
                c.rgb = (floor(c.rgb*_ColorMerge)/_ColorMerge);
                float3 n =  UnpackNormal(tex2D (_Bump, i.uv2)); 
                float3 lightColor = float3(0);
                float lengthSq = dot(i.lightDirection, i.lightDirection);
                float atten = 1.0 / (1.0 + lengthSq);
                float diff = saturate (dot (n, normalize(i.lightDirection)));  
                diff = tex2D(_Ramp, float2(diff, 0.5));
                lightColor += _LightColor0.rgb * (diff * atten); 
                c.rgb = lightColor * c.rgb * 2;
             	return c;
            }  
            ENDCG
        }        
	} 
	FallBack "Diffuse"
}
