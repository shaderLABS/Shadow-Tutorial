#define SHADOW_DISTORT_ENABLED //Toggles shadow map distortion
#define SHADOW_DISTORT_FACTOR 0.10 //Distortion factor for the shadow map. Has no effect when shadow distortion is disabled. [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]
#define SHADOW_BIAS 1.00 //Increase this if you get shadow acne. Decrease this if you get peter panning. [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.60 0.70 0.80 0.90 1.00 1.50 2.00 2.50 3.00 3.50 4.00 4.50 5.00 6.00 7.00 8.00 9.00 10.00]
#define NORMAL_BIAS //Offsets the shadow sample position by the surface normal instead of towards the sun
#define EXCLUDE_FOLIAGE //If true, foliage will not cast shadows.
#define SHADOW_BRIGHTNESS 0.75 //Light levels are multiplied by this number when the surface is in shadows [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]

const int shadowMapResolution = 1024; //Resolution of the shadow map. Higher numbers mean more accurate shadows. [128 256 512 1024 2048 4096 8192]

#ifdef SHADOW_DISTORT_ENABLED
	vec3 distort(vec3 pos) {
		float factor = length(pos.xy) + SHADOW_DISTORT_FACTOR;
		return vec3(pos.xy / factor, pos.z * 0.5);
	}

	//returns the reciprocal of the derivative of our distort function,
	//multiplied by SHADOW_BIAS.
	//if a texel in the shadow map contains a bigger area,
	//then we need more bias. therefore, we need to know how much
	//bigger or smaller a pixel gets as a result of applying sistortion.
	float computeBias(vec3 pos) {
		//square(length(pos.xy) + SHADOW_DISTORT_FACTOR) / SHADOW_DISTORT_FACTOR
		float numerator = length(pos.xy) + SHADOW_DISTORT_FACTOR;
		numerator *= numerator;
		return SHADOW_BIAS / shadowMapResolution * numerator / SHADOW_DISTORT_FACTOR;
	}
#else
	vec3 distort(vec3 pos) {
		return vec3(pos.xy, pos.z * 0.5);
	}

	float computeBias(vec3 pos) {
		return SHADOW_BIAS / shadowMapResolution;
	}
#endif