// unitygems.com/noobshader1/#prettyPhoto

Shader "Custom/Diffuse Texture" {
	Properties {
		// Property definitions follow this format:
		// _Name ("Display Name", type) = default value [{options}]
		//
		// * _Name : is the name that this property will be referred to in your program
		// * Display Name : will appear in the material editor
		// * type : is the type of property, your choices are;
		//		- Color : the value will be a single color for the whole program
		//		- 2D : the value is a power-of-2 sized texture that can be sampled by the program for a particular pixel based on the UVs of the model
		//		- Rect : the value is a texture that is not a power-of-2 size
		//		- Cube : the value is a 3D cube map texture used for reflections, this can be sampled by the program for a particular pixel
		//		- Range(min, max) : the value is a floating point between a minimum and maximum value
		//		- Float : the value is a floating point number with any value
		//		- Vector : the value is a 4 dimensional vector
		// * default vallue : is the default value for the propperty
		//		- Color : the color expressed as a floating point representation with four parts (r,g,b,a)
		//		- 2D / Rect / Cube : for the texture types the default can be: an empty string, or "white", "black", "gray", "bump"
		//		- Float / Range - the value to adopt
		//		- Vector - the 4D vector expressed as (x,y,z,w)
		// * {options} : only relates to the texture types 2D, Rect, and Cube - where it *must* be specified at least as {}
		//		You can combine multiple options by separating them with spaces, the choices are:
		//		- TexGen texgenmode : Automatiic texture coordinate generation mode for this texture. Can be one of ObjectLinear, EyeLinear,
		//			SphereMap, CubeReflecct, CubeNormal; these correspond directly to OpenGL texgen modes. Note that TexGen is ignoored iif you
		//			write a vertex function
		_MainTex ("Base (RGB)", 2D) = "white" {}
	}
	SubShader {
			// These tags define things that let the hardware decide when to call your shader - Unity defines a number of these things.
			// "RenderType"="Opaque" : instructs the system to call us when it is rendering Opaque gemoetry
			// "RenderType"="Transparent" : says that your shader is potentially goind to output semi-transparent or transparent pixels
			// "IgnoreProjector"="True" : means your object will not be affected by projjectors
			// "Queue"="xxxx"
			//
			// The Queue tak has some very interestiing effects and is used when the RenderType equals transparent. It basically says when your object will be rendered
			//		- Background : this render queue is rendered before any others. It is used for skyboxes and the like
			//		- Geometry (default) : this is used for most objects. Opaque geometry uses this queue
			//		- AlphaTest : alpha tested geometry uses this queue. It's a separate queue from the Geometry one since it's more efficient to render alpha-tested
			//			objects after all solid ones are drawn
			//		- Transparent : this render queue is rendered after Geometry and AlphaTest, in back-to-froont order. Anything alpha-based (ie. shaders that don't
			//			write to depth buffer) should go here (glass, particle effects).
			//		- Overlay - this render queue is meant for overlay effects. Anything rendered last should go here (eg. lens flares)
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
			// this says:
			//	- this is a surface shader
			//	- the function to call to get the output iis called surf
			//	- we want to use the Lambert (diffuse) lighting model
		#pragma surface surf Lambert

			// The _MainTex variable is a Sampler2D linked to the main texture - it can read a pixel out of that texture given a uv coordinate
		sampler2D _MainTex;

			// this deines our input structure. Simply by creating this structure we have told the system to get us the texture coordinate of MainTex for the current
			// pixel each time we call the surf funcition.
			// Our Input structure normally contains a whole set of uv or uv2 coordinates for all the textures we are using.
		struct Input {
			float2 uv_MainTex;
			
				// If we had a second texture called _OtherTexture we could get its uv coordinates simply by adding this:
				// 		float2 uv_OtherTexture;
				// If we had a second set of uvs for the other texture, we could get those too:
				//		float2 uv2_OtherTexture;
				//
				// If our shader was complicated and needed to know other things about the pixel being shaded then we can ask for these other variables just by including them here:
				//	* float3 viewDir - will contain veiw direction, for computing Parallax effects, rim lighting, etc
				//	* float4 with COLOR semantic - will contain interpolated per-vertex color
				//	* float4 screenPos - will contain screen space position for reflection effects
				//	* float3 worldPos - will contain world space position
				// 	* float3 worldRefl - will contain world reflection vector (if surface shader does not write to o.Normal)
				//	* float3 worldNormal - will contain world normal vector (if surface shader does not write to o.Normal)
				//	* INTERNAL_DATA - a structure used by some functions like WorldNormalVector to compute things when we write to o.Normal
		};

			// our surface function is going to be called once per pixel - the system has worked out the current values of our input structure for the single pixel we are
			// working on. It's basically interpolating values in the Input structure across every face of our mesh
		void surf (Input IN, inout SurfaceOutput o) {
		
				// tex2D sanokes _MainTex at the uv coordinates we got from the system. Because that texture is a float4 (including alpha) we need to just get the .rgb
				// values of it for o.Albedo
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			
				// we are returning something in o.Albedo - which is in our SurfaceOutput structure that Unity has defined for us. That structure looks like this:
				// 		struct SurfaceOutput {
				//			half4 Albedo;			// the color of the pixel
				//			half4 Normal;			// the normal of the pixel
				//			half4 Emission;			// the emissive color of the pixel
				//			half4 Specular;			// the specular power of the pixel
				//			half4 Gloss;			// the gloss intensity of the pixel
				//			half4 Alpha;			// the alpha value for the pixel
				// The Albedo is the color of the pixel. You just need to return values in this structure and Unity will work out what it needs to do when it generates
				// the actual passes behind the scenes.
			o.Albedo = c.rgb;
			o.Alpha = c.a;
		}
		ENDCG
	} 
	FallBack "Diffuse"
}
