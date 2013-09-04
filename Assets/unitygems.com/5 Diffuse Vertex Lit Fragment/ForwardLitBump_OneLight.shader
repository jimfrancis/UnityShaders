// http://unitygems.com/noobs-guide-shaders-5-bumped-diffuse-shader/


Shader "unitygems.com/ForwardLitBumpFragment_OneLight" {
    Properties {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _Bump ("Bump", 2D) = "bump" {}
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 200
 
        Pass {
				// tell the pass to turn on lighting and cull back faces		
			Cull Back			
				// We haave a couple of choices when we write a shader - we can define multiple passes so that each light gets to have a go at our program,
				// or we can take into account all of the lights at the vertices and interpolate them out.
				// If we write a Vertex Lit shader then we have to take into coonsideration all of the lights and their impact on the verticies
				// If we write a multiplass shader then it gets called multiple times, one for each light that is affecting our model
			Lighting On
 
				// define the CG program and specify the names of the vertex and fragment programs
				
            CGPROGRAM
// Upgrade NOTE: excluded shader from DX11 and Xbox360; has structs without semantics (struct v2f members lightDirection)
#pragma exclude_renderers d3d11 xbox360
            #pragma vertex vert
            #pragma fragment frag
 
				// include a file of useful Unity definitions we need in our CG program
			
            #include "UnityCG.cginc"
            
            	// Vertex lights are defined as three arrays: unity_LightPosition, unity_LightAtten and unity_LightColor.  The [0] entry is the most important light etc.
            	// When we write a multi-pass lighting model (as we will next) we only deal with a single light at a time - in that case Unity also 
            	// defines a _WorldSpaceLightPosition0 value that we can use to work out where it is and a very helpful ObjSpaceLightDir function that 
            	// will work out the direction to the light.  To get the color of the light we are going to have to add an extra entry defining a variable 
            	// from CG or include "Lighting.cginc" into our programs.
            uniform float4 _LightColor0;		//Define the current light's colour variable
 
            sampler2D _MainTex;
            sampler2D _Bump;
            float4 _MainTex_ST;
            float4 _Bump_ST;
 
				// our vertex function needs to get some information about the model - we define a structure for that
				// The structure reliies on semantics
				// Here we are getting the position in model space of the vertex and the direction of the normal, and we are also getting the texture
				// coordinate from uv1
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                	// We've added a : TANGENT to our input structure. We are going to use this to convert light directions to tangent space.
                float4 tangent : TANGENT;
 
            }; 
 
				// so having defined the input to our vertex program as the position, normal, and uv from the underlying mesh - we also need too know what we
				// need to output from it.
				// Remember that what we output from the vertex will be interpolated across the pixels being rendered, and this interpolated value becomes the 
				// input to our fragment function
            struct v2f
            {
					// we MUST return one value tagged as POSITION, which is the position of the vertex converted into projection space
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;		// the texture coordinate of the bump map
                float3 lightDirection;		// the interpolated light direction vector
 
            };
 
			// here's the actual vertex function - converting a2v (our input) to v2f (the input for our fragment function)
			// This shader is effectively working for directional and point lights only. We are not considering spotlight angle in this example.
            v2f vert (a2v v)
            {
                v2f o;
                	// use the TANGENT_SPACE_ROTATION macro to create our rotation matrix to convert object space to tangent space.
                	// For this macro to work our input structure must be called v and it must contain a normal called normal and a tangent called tangent.
                TANGENT_SPACE_ROTATION; 
 
 					// We then calculate the direction in object space to the light we are dealing with (at the moment the most important light) using the 
 					// built in function ObjSpaceLightDir(v.vertex).  We want the light direction in object space because we have a transformation from that 
 					// to tangent space - which we immediately apply by multiplying our new rotation matrix by the direction.
                o.lightDirection = mul(rotation, ObjSpaceLightDir(v.vertex));
                	// Finally we work out the projection space position of the vertex (remember we are required to do this and store it in a : POSITION output variable)
                	// and the uv coordinate of our texture
                o.pos = mul( UNITY_MATRIX_MVP, v.vertex); 
                o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);  
                o.uv2 = TRANSFORM_TEX (v.texcoord, _Bump);
                return o;
            }
 
			// remember that when out fragment function is called the system will be interpolating between the vertices of a triangle - ie the values returned by 3 separate
			// calls to the vert function
			// 
			// In the fragment function we are going to unpack the normal from it's encoded format in the texture map and use that, on its own, as the normal for our Lambert function.  
			// That's because all that tangent space rotation on the light direction has already got it to take account of the normal of the face of the model we are rendering.
            float4 frag(v2f i) : COLOR  
            { 
                float4 c = tex2D (_MainTex, i.uv);  
                float3 n =  UnpackNormal(tex2D (_Bump, i.uv2)); 
 
 					// We first start with the base colour of the ambient light
                float3 lightColor = UNITY_LIGHTMODEL_AMBIENT.xyz;
 					// Next we work out how far away our real light is. 
 					// If this was a directional light then the vector is already normalized so the distance will be 1 (no affect).
                float lengthSq = dot(i.lightDirection, i.lightDirection);
                	// Then we work out the final attenuation of the light by multiplying out the distance from the light squared (dot(v,v) is the 
                	// square of v's magnitude helpfully) by the intensity of the light (represented in unity_LightAtten).
                	
                	// For a directional light we are multiplying out by 1/1 + attenuation - in other words we are dividing the underlying 
                	// colour (and hence brightness) by the attenuation + 1. This is why we multiply the final colour by 2.
					// For a point light we are also making its brightness fall off in relation to the square of the distance to the light.
                float atten = 1.0 / (1.0 + lengthSq);
                
                	// Then we dot the normalised light direction with the normal we got from the bump map and now we can apply our light's color to that 
                	// in combination with the attenuation.  (Remember we've already rotated the light's direction to take into account the normal of the 
                	// face of the model we are rendering).
                float diff = saturate (dot (n, normalize(i.lightDirection)));   	// Angle to the light
                	// To get the color of the light we are using _LightColor0
                lightColor += _LightColor0.rgb * (diff * atten); 
                c.rgb = lightColor * c.rgb * 2;
                return c; 
 
            } 
 
            ENDCG
        }
 
    }
    FallBack "Diffuse"
}