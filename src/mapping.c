#include "lib_math.h"

t_vec3 map_spherical(float u, float v) {
	t_vec2 phi;
	float cos_theta = 1.0f - 2.0f * v;
	float sin_theta = sqrtf(fmaxf(0.0f, 1.0f - cos_theta * cos_theta));
	sincosf(M_TAU * u, &phi.sin, &phi.cos);
	return vec3(sin_theta * phi.cos, sin_theta * phi.sin, cos_theta);
}

t_vec2 spherical_uv(t_vec3 dir) {
	return (t_vec2){ //
		.u = (fast_atan2f(dir.z, dir.x) + (float)M_PI) * M_1_2PI,
		.v = fast_acosf(clampfn11(dir.y)) * M_1_PI
	};
}
