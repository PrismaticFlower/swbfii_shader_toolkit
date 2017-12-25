#ifndef EXT_CONSTANTS_LIST_INCLUDED
#define EXT_CONSTANTS_LIST_INCLUDED

// the resolution of the render target
float2 render_target_resolution : register(ps, c[10]);

//static const float directional_lights = active_lights[0][0];
//static const float point_light_0 = active_lights[0][1];
//static const float point_light_1 = active_lights[0][2];
//static const float point_light_23 = active_lights[0][3];
//static const float spot_light = active_lights[1][0];

bool directional_lights : register(b0);
bool point_light_0 : register(b1);
bool point_light_1 : register(b2);
bool point_light_23 : register(b3);
bool spot_light : register(b4);


#endif