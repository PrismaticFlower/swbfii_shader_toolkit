#ifndef VERTEX_UTILS_INCLUDED
#define VERTEX_UTILS_INCLUDED

#include "types.hlsl"

float4 decompress_position(float4 position, Position_decompress position_decompress)
{
   position = position_decompress.min_pos * position;
   return position_decompress.max_pos + position; 
}

float4 get_material_color(float4 color, float4 color_state)
{
   return color * color_state.yyyw + color_state.xxxz;
}

float4 get_static_diffuse_color(float4 color, float4 color_state)
{
   return color * color_state.xxxz + color_state.zzzz;
}

float4 pos_to_world(float4 position, float4x3 world)
{
   return float4(mul(position, world), 1.0);
}

float4 pos_project(float4 position, float4x4 projection)
{
   return mul(position, projection);
}

#endif