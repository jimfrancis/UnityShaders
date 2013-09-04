// unitygems.com/noobs-guide-shaders-4-toon-shading-basic/

// Aim: We want to make a toon shader - one that makes our models look like thay are drawn as a cartoon rather than being a very realistic model. 
// To do that we need to do a number of things:
//	* Simplify the colors used in our model
//	* Simpligy the lighting so that we have well defined areas of light and dark
//	* Draw an outline in black around our model


Shader "unitygems.com/Toon" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
			// new normal map texture - defines a property called _Bump which is a 2D image with a default of "bump" (empty normal map)
		_Bump ("Bump", 2D) = "bump" {}
		_Ramp ("Ramp Texture", 2D) = "white" {}
		_Tooniness ("Tooniness", Range(0.1, 20)) = 4
		_ColorMerge ("Color Merge", Range(0.1, 20)) = 8
		_Outline ("Outline", Range(0, 1)) = 0.4
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf Toon

		sampler2D _MainTex;
		sampler2D _Bump;
		sampler2D _Ramp;
		float _Tooniness;
		float _ColorMerge;
		float _Outline;

		struct Input {
			float2 uv_MainTex;
			float2 uv_Bump;
				// We are going to be detecting the edges in our surface program, and its there we need to get the 
				// direction of the view - luckily thats going to be magically worked out for us if we just include 
				// viewDir in our surface shaders Input structure				
			float3 viewDir;
		};

		void surf (Input IN, inout SurfaceOutput o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			
			o.Normal = UnpackNormal( tex2D(_Bump, IN.uv_Bump) );
			
				// detect the edge
				// First we work out the dot product to the edge by taking the normal of the pixel and the view direction.
				// Then if its less than our property cut off value we make it a small number (a divide by 4 seems to work well),
				// if its above that then we make it simply a 1 (no effect). We just multiply that value into our color and away we go
			half edge = saturate(dot (o.Normal, normalize(IN.viewDir)));
			edge = edge < _Outline ? edge / 4 : 1;		
			
			o.Albedo = (floor(c.rgb * _ColorMerge) / _ColorMerge) * edge;
			o.Alpha = c.a;
		}
		
		// Lighting functions always take 3 parameters: 
		//	- the output from the surface program,
		//	- the direction of the light, and
		//	- the attenuation to use
		// They always return the color of the lit pixel
		half4 LightingToon(SurfaceOutput s, half3 lightDir, half atten) {
			
			// we take the light directiono and the normal of the pixel and produce the dot product.
			// Remember that the dot product is 1 if the two items are facing each other and -1 if they
			// are exactly opposite, and 0 at the 90 degree point.
			// That's very helpful for lighting of course - a pixel directly facing the light will get its full
			// color. Anything beyond 90 degrees will become black and unlit and there will be an interpolation in between.
						
			half4 c;			
			half NdotL = dot(s.Normal, lightDir);
				// Modify NdotL by saturating (clamping between 0..1) the texture lookup from the ramp texture
			NdotL = saturate( tex2D(_Ramp, float2(NdotL, 0.5)) );
						
			c.rgb = s.Albedo * _LightColor0.rgb * NdotL * atten * 2;
			c.a = s.Alpha;
			return c;			
		}		
		ENDCG
	} 
	FallBack "Diffuse"
}
