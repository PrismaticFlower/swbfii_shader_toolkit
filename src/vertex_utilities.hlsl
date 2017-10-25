#ifndef VERTEX_UTILS_INCLUDED
#define VERTEX_UTILS_INCLUDED

#include "constants_list.hlsl"

float4 decompress_position(float4 position)
{
   position = position_decompress_min * position;
   return position_decompress_max + position;
}

float2 decompress_texcoords(float4 texcoord)
{
   return (texcoord * normaltex_decompress.zzzw).xy;
}

float4 get_material_color(float4 color)
{
   return color * color_state.yyyw + color_state.xxxz;
}

float4 get_static_diffuse_color(float4 color)
{
   return color * color_state.xxxz + color_state.zzzz;
}

float4 pos_to_world(float4 position)
{
   return float4(mul(position, world_matrix), 1.0);
}

float4 pos_project(float4 position)
{
   return mul(position, projection_matrix);
}

float4 pos_to_world_project(float4 position)
{
   return pos_project(pos_to_world(position));
}

#endif