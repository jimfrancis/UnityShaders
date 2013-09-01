// unitygems.com/noobs-guide-shaders-3-realistic-snow/

// When the Snow level dictates that a pixel should be snowy, allow a margin where the snow is semi transparent white, getting more opaque
// the closer the angle of the pixel is to the snow direction modified by the level of the snow. 
// In other words, the more snowy it is, the more opaque the snow on a pixel gets before it becomes solid white (or in fact, snow color)

Shader "Custom/Snow Shader" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}	
			// new normal map texture - defines a property called _Bump which is a 2D image with a default of "bump" (empty normal map)
		_Bump ("Bump", 2D) = "bump" {}
			// the Snow variable will eb the amount of snow that covers the rock. It's always in the range 0..1
		_Snow ("Snow Level", Range(0,1)) = 0
			// a color for our snow, which defaults to white
		_SnowColor ("Snow Color", Color) = (1.0, 1.0, 1.0, 1.0)
			// a direction from which the snow is falling (by default iit is falling straight down, so our accumulation vector is straight up)
		_SnowDirection ("Snow Direction", Vector) = (0, 1, 0)
			// a depth for our snoow tht we will use when we modify the vertices, which is in the range 0..0.3
		_SnowDepth ("Snow Depth", Range(0, 0.3)) = 0.1
		
		// First we need a property to indicate how much we should blend the snow - we'll call that _Wetness for want of a better name
		_Wetness ("Wetness", Range(0, 0.5)) = 0.3
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
			// To make the model bigger, predominantly (but not completely) in the direction of the snow, we also need to modify the vertices
			// of the model - this means telling the surface shader that we want to write a function to do just that
			// The addition of the vertex parameter provides thhe name of our vertex function: vert
		CGPROGRAM
		#pragma surface surf Lambert vertex:vert

			// make sure we hae variables with the right names
		sampler2D _MainTex;		
		sampler2D _Bump;			// must add a sample with exactly the same name
		float _Snow;
		float4 _SnowColor;
		float4 _SnowDirection;
		float _SnowDepth;
		float _Wetness;

			// We also need to update teh Input shader. The normal map texture will give us the modification to the normal for a pixel,
			// but for our effet to work we are going to need to work out the actual world normal so we can compare it with our snow direction.
			//
			// Basically because we want to write to o.Normal in our shader we need to get the INTERNAL_DATA supplied by Unity and then call a 
			// function called WorldNormalVector in our shader program which needs that information. 
			// The practical upshot is we need to put those things in the Input structure.
		struct Input {
			float2 uv_MainTex;			
				// Create an entry in Input to get the uv coordinates for Bump (again, using the same name)				
				// Get the uv coordinates for the bump map
			float2 uv_Bump;
			float3 worldNormal;
			INTERNAL_DATA
		};

		void surf (Input IN, inout SurfaceOutput o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Normal = UnpackNormal(tex2D(_Bump, IN.uv_Bump));
			
			// We now calculate the diffeerence between the dot of the pixel's normal against the snow direction's with the currently lerped value based
			// on the level of snow. This gives us a value in terms of the cosine of the angle, which is also what the _Wetness represents
			float difference = dot(WorldNormalVector(IN, o.Normal), _SnowDirection.xyz) - lerp(1, -1, _Snow);
		
			// We then saturate the difference between the normal of the pixel and the range of our current snow divided by Wetness
			//	- Saturation gives us a value clamped between 0 and 1
			//	- So if we were out of range for being snowy (the difference was < 0), the value will be 0
			//	- If _Wetness were its default 0.3
			//		- if we were within 27 degrees (30% of 90 degrees) then the value will lie somewhere between 0..1, otherwise the value will be 1
			difference = saturate(difference / _Wetness);
								
			// We then take this differencce and multiply it by the snow color - giving us a proportion of that color, 
			// we then take the inverse proportion of the texture color and add them together. 
			// This effectively blends the snow color into the texture color over 27 degrees of angle between the start of the snow and it becoming totally opaque	
			o.Albedo = difference * _SnowColor.rgb + (1-difference) * c;
			o.Alpha = c.a;
		}
		
		// The only problem now is that if the snow is very wet then our model may expand before it is actually snowy. That is not very realistic
		// So we apply our wetness factor to the snow range, this means the model will expand later depending on how wet it is
		void vert (inout appdata_full v) {
			// The snow direction is in world space, but we are working in object space, so we have to transpose the snow direction to object space by
			// multiplying it by a Unity supplied matrix that's designed for that purpose
					
			// Convert the normal to object coordinates
			// (UNITY_MATRIX_IT_MV is the Inverse Transpose of model * view matrix)
			float4 sn = mul(UNITY_MATRIX_IT_MV, _SnowDirection);
			
				// So the modification is to scale the _Snow level by 1-_Wetness. This means that at 0 wetness nothing chanes and at our full (0.5) wetness
				// we are effectively scaling the snow factor by 1/3 rather than 2/3 - making the model modify 50% later
																					
			if( dot(v.normal, sn.xyz) >= lerp(1, -1,  ((1-_Wetness) * _Snow*2)/3) ) {
				// Presuming our test passed we then modify the vertex by multiplying its normal + our new direction by the depth factor and the current snow level.
				// This has the effect of makinng the vertices move more towards the snow direction and increases this distortion as the snow level increases.			
				v.vertex.xyz += (sn.xyz + v.normal) * _SnowDepth * _Snow;
			} 
		}
		ENDCG
	} 
	FallBack "Diffuse"
}
