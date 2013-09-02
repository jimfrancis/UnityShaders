
Shader "Custom/DiffuseVertexLitFragment" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
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
// Upgrade NOTE: excluded shader from DX11 and Xbox360; has structs without semantics (struct v2f members color)
#pragma exclude_renderers d3d11 xbox360
			#pragma vertex vert
			#pragma fragment frag
			
				// include a file of useful Unity definitions we need in our CG program
			
			#include "UnityCG.cginc"
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			
				// our vertex function needs to get some information about the model - we define a structure for that
				// The structure reliies on semantics
				// Here we are getting the position in model space of the vertex and the direction of the normal, and we are also getting the texture
				// coordinate from uv1
			struct a2v 
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};
			
				// so having defined the input to our vertex program as the position, normal, and uv from the underlying mesh - we also need too know what we
				// need to output from it.
				// Remember that what we output from the vertex will be interpolated across the pixels being rendered, and this interpolated value becomes the 
				// input to our fragment function
			struct v2f 
			{
					// we MUST return one value tagged as POSITION, which is the position of the vertex converted into projection space
				float4 pos : POSITION;
				float2 uv;
				float3 color;
			};
			
			// here's the actual vertex function - converting a2v (our input) to v2f (the input for our fragment function)
			v2f vert (a2v v) {
					// fiirst define an instance of our output structure
				v2f o;
					// then transform model space to projection space by multiplying the vertex's position by a predefined matrix we got from Unity (by including UnityCg.cginc)
					// UNITY_MATRIX_MVP is a matrix that will convert a model's vertex position to the projection space coordinate
				o.pos = mul( UNITY_MATRIX_MVP, v.vertex );
					// next work out a uv for a given texture - in other words the actual texture positions that relate to the uvs from the underlying mesh
					// We use a built-in macro from UnityCG.cginc to do that
					// (NOTE: to use TRANSFORM_TEX you need to define a couple of extra variables in your shader. These must be float4 variables called _YourTextureName_ST)
				o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);
					// finally work out a base color for this pixel - this is the color of the light falling on this pixel and for the first shader we call ShaderVertexLights
					// passing the model vertex and normal - this built-in function takes the 4 nearest lights into consideration in addition to ambient light
				o.color = ShadeVertexLights(v.vertex, v.normal);
					// finally we return out output structure ready for processing
				return o;
			}
			
			// remember that when out fragment function is called the system will be interpolating between the vertices of a triangle - ie the values returned by 3 separate
			// calls to the vert function
			float4 frag (v2f i) : COLOR
			{
				// now we want to work out the color of a particular pixel given our interpolated input structure
				
				// our fragment program uses the familiar texture lookup to get the color of the texture pixel for this screen pixel and then multiply that by the 
				// interpolated light color coming from the vertex function, and multiply the whole thing by 2 (for no other reason than its too dark without it)				
				float4 c = tex2D (_MainTex, i.uv);
				c.rgb = c.rgb * i.color * 2;
				return c;
			}
			ENDCG
		}
	} 
	FallBack "Diffuse"
}
