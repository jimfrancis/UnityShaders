// unitygems.com/noobs-guide-shaders-2/

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
			// Normal color of a pixel
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			
			// Extract the normal map information from the texture, and convert the result into a normal
			// we pass it the pixel from the texture, using tex2D and the _Bump variable and uv cooordinates from the Input structure
			o.Normal = UnpackNormal(tex2D(_Bump, IN.uv_Bump));
			
				// We are going to get the dot product of two vectors - one is our snow direction and the other is the vector that will actually
				// be used for the normal of the pixel - a combination of the world normal for this point and the bump map
				//
				// We get that normal by calling WorldNormalVector passing it the Input structure with our new INTERNAL_DATA and the normal
				// of the pixel from the bump map (http://docs.unity3d.com/Documentation/Components/SL-SurfaceShaders.html)
				//
				// After this dot product we will have a value between 1 (the pixel is exactly on the snow direction) and -1 (it is exactly opposite)
				//
				// We then compare the dot value with a lerp - if our Snow level is 0 (no snow) this returns 1 and if the Snow level is 1 it will return
				// -1 (the entire rock is covered). It's quite normal to only vary the snow level between 0..0.5 when we use this shader so that we only
				// have snow on surfaces that actually face the snow direction
				//
				// When the dot is greater than the snow level lerp we use the snow color, otherwise we use the texture
				
			
			// Get the dot product of the real normal vector and our snow direction and compare it to the snow level
			if( dot( WorldNormalVector(IN, o.Normal), _SnowDirection.xyz) > lerp(1, -1, _Snow) ) {
				// if this should be snow, pass on the snow color
				o.Albedo = _SnowColor.rgb;
			} else {
				o.Albedo = c.rgb;
			}
			
			o.Alpha = 1;
		}
		
		// first we pass the vert function a paraameter - this is the incoming data and we've chosen to use appdata_full (from Unity) which has both texture
		// coordinates, the normal, the vertex position and the tangent. 
		// You can pass extra information to your pixel function by specifying a second parameter with your own Input data structure - where you can add extra
		// values if you want
		void vert (inout appdata_full v) {
			// The snow direction is in world space, but we are working in object space, so we have to transpose the snow direction to object space by
			// multiplying it by a Unity supplied matrix that's designed for that purpose
					
			// Convert the normal to object coordinates
			// (UNITY_MATRIX_IT_MV is the Inverse Transpose of model * view matrix)
			float4 sn = mul(UNITY_MATRIX_IT_MV, _SnowDirection);
			
			// We now only have the normal of the vertex, so we do the same calculation for snow direction we did before - but we scale the snow level by 2/3
			// so that only areas well covered in snow already are modified
						
			if( dot(v.normal, sn.xyz) >= lerp(1, -1, (_Snow*2)/3) ) {
				// Presuming our test passed we then modify the vertex by multiplying its normal + our new direction by the depth factor and the current snow level.
				// This has the effect of makinng the vertices move more towards the snow direction and increases this distortion as the snow level increases.			
				v.vertex.xyz += (sn.xyz + v.normal) * _SnowDepth * _Snow;
			} 
		}
		ENDCG
	} 
	FallBack "Diffuse"
}
