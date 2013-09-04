Shader "GLSL_Programming/1. Basics/Minimal" { 	// defines the name of the shader 
   SubShader { 									// Unity chooses the subshader that fits the GPU best
      Pass { 									// some shaders require multiple passes
         // GLSL combinations: 1
Program "vp" {
SubProgram "opengl " {
Keywords { }
"!!GLSL

#ifndef SHADER_API_OPENGL
    #define SHADER_API_OPENGL 1
#endif
#ifndef SHADER_API_DESKTOP
    #define SHADER_API_DESKTOP 1
#endif
#define highp
#define mediump
#define lowp
#line 5
 							// here begins the part in Unity's GLSL
 
         #ifdef VERTEX // here begins the vertex shader
 
         void main() 							// all vertex shaders define a main() function
         {
            gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
               // this line transforms the predefined attribute 
               // gl_Vertex of type vec4 with the predefined
               // uniform gl_ModelViewProjectionMatrix of type mat4
               // and stores the result in the predefined output 
               // variable gl_Position of type vec4.
               
               // or we could flatten the input geometry by multiplying the y co-ordinate by 0.1
			//gl_Position = gl_ModelViewProjectionMatrix * (vec4(1.0, 0.1, 1.0, 1.0) * gl_Vertex);
         }
 
         #endif // here ends the definition of the vertex shader
 
 
         #ifdef FRAGMENT // here begins the fragment shader
 
         void main() // all fragment shaders define a main() function
         {
            gl_FragColor = vec4(0.6, 1.0, 0.0, 1.0); 
               // this fragment shader just sets the output color 
               // to opaque red (red = 1.0, green = 0.0, blue = 0.0, 
               // alpha = 1.0)
         }
 
         #endif // here ends the definition of the fragment shader
 
         "
}
SubProgram "gles " {
Keywords { }
"!!GLES

#ifndef SHADER_API_GLES
    #define SHADER_API_GLES 1
#endif
#ifndef SHADER_API_MOBILE
    #define SHADER_API_MOBILE 1
#endif
#line 5
 							// here begins the part in Unity's GLSL
 
         // here ends the definition of the vertex shader
 
 
         // here ends the definition of the fragment shader
 
         
#ifdef VERTEX
#define gl_ModelViewProjectionMatrix glstate_matrix_mvp
uniform highp mat4 glstate_matrix_mvp;
#define gl_Vertex _glesVertex
attribute vec4 _glesVertex;
 // here begins the vertex shader
 
         void main()        // all vertex shaders define a main() function
         {
            gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
               // this line transforms the predefined attribute 
               // gl_Vertex of type vec4 with the predefined
               // uniform gl_ModelViewProjectionMatrix of type mat4
               // and stores the result in the predefined output 
               // variable gl_Position of type vec4.
               
               // or we could flatten the input geometry by multiplying the y co-ordinate by 0.1
   //gl_Position = gl_ModelViewProjectionMatrix * (vec4(1.0, 0.1, 1.0, 1.0) * gl_Vertex);
         }
 
         
#endif
#ifdef FRAGMENT
 // here begins the fragment shader
 
         void main() // all fragment shaders define a main() function
         {
            gl_FragColor = vec4(0.6, 1.0, 0.0, 1.0); 
               // this fragment shader just sets the output color 
               // to opaque red (red = 1.0, green = 0.0, blue = 0.0, 
               // alpha = 1.0)
         }
 
         
#endif"
}
SubProgram "glesdesktop " {
Keywords { }
"!!GLES

#ifndef SHADER_API_GLES
    #define SHADER_API_GLES 1
#endif
#ifndef SHADER_API_DESKTOP
    #define SHADER_API_DESKTOP 1
#endif
#line 5
 							// here begins the part in Unity's GLSL
 
         // here ends the definition of the vertex shader
 
 
         // here ends the definition of the fragment shader
 
         
#ifdef VERTEX
#define gl_ModelViewProjectionMatrix glstate_matrix_mvp
uniform highp mat4 glstate_matrix_mvp;
#define gl_Vertex _glesVertex
attribute vec4 _glesVertex;
 // here begins the vertex shader
 
         void main()        // all vertex shaders define a main() function
         {
            gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
               // this line transforms the predefined attribute 
               // gl_Vertex of type vec4 with the predefined
               // uniform gl_ModelViewProjectionMatrix of type mat4
               // and stores the result in the predefined output 
               // variable gl_Position of type vec4.
               
               // or we could flatten the input geometry by multiplying the y co-ordinate by 0.1
   //gl_Position = gl_ModelViewProjectionMatrix * (vec4(1.0, 0.1, 1.0, 1.0) * gl_Vertex);
         }
 
         
#endif
#ifdef FRAGMENT
 // here begins the fragment shader
 
         void main() // all fragment shaders define a main() function
         {
            gl_FragColor = vec4(0.6, 1.0, 0.0, 1.0); 
               // this fragment shader just sets the output color 
               // to opaque red (red = 1.0, green = 0.0, blue = 0.0, 
               // alpha = 1.0)
         }
 
         
#endif"
}
}

#LINE 36
 // here ends the part in GLSL 
      }
   }
}