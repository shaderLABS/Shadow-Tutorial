#version 120

#define DRAW_SHADOW_MAP gcolor //Configures which buffer to draw to the screen [gcolor shadowcolor0 shadowtex0 shadowtex1]

uniform float frameTimeCounter;
uniform sampler2D gcolor;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;

varying vec2 texcoord;

void main() {
	vec3 color = texture2D(DRAW_SHADOW_MAP, texcoord).rgb;

/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0); //gcolor
}