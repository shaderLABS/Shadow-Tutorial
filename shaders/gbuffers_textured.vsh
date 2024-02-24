#version 120

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec3 shadowPos; //normals don't exist for particles

#include "/distort.glsl"

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;

	vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
	vec4 playerPos = gbufferModelViewInverse * viewPos;
	shadowPos = (shadowProjection * (shadowModelView * playerPos)).xyz; //convert to shadow ndc space.
	float bias = computeBias(shadowPos);
	shadowPos = distort(shadowPos); //apply shadow distortion.
	shadowPos = shadowPos * 0.5 + 0.5; //convert from shadow ndc space to shadow screen space.
	shadowPos.z -= bias; //apply shadow bias.

	gl_Position = gl_ProjectionMatrix * viewPos;
}