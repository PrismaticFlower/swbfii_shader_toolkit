#ifndef EXT_CONSTANTS_LIST_INCLUDED
#define EXT_CONSTANTS_LIST_INCLUDED

// the resolution of the render target
//float2 render_target_resolution : register(ps, c[10]);

float2 fog_range : register(ps, c[51]);
float3 fog_color : register(ps, c[52]);

float2 resolution : register(ps, c[53]);

bool directional_lights : register(b0);
bool point_light_0 : register(b1);
bool point_light_1 : register(b2);
bool point_light_23 : register(b3);
bool spot_light : register(b4);
bool fog_enabled : register(b5);

#endif