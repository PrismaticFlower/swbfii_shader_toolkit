#ifndef VERTEX_UTILS_INCLUDED
#define VERTEX_UTILS_INCLUDED

#include "constants_list.hlsl"

struct Near_scene
{
   float view_z;
   float fade;
};

float4 decompress_position(float4 position)
{
   position = position_decompress_min * position;
   return position_decompress_max + position;
}

float2 decompress_texcoords(float4 texcoords)
{
   return (texcoords * normaltex_decompress.zzzw).xy;
}

float4 get_material_color(float4 color)
{
   return (color * color_state.yyyw + color_state.xxxz) * material_diffuse_color;
}

float4 get_static_diffuse_color(float4 color)
{
   return color * color_state.xxxz + color_state.zzzz;
}

float4 pos_to_skinned_object(float4 position, uint4 indices)
{
   int index = (indices.xyz * constant_1.www).x;

   return float4(mul(position, bone_matrix[index]), constant_0.z);
}

float4 pos_to_world(float4 position)
{
   return float4(mul(position, world_matrix), constant_0.z);
}

float4 pos_project(float4 position)
{
   return mul(position, projection_matrix);
}

float4 pos_to_world_project(float4 position)
{
   return pos_project(pos_to_world(position));
}

float4 transform_unskinned(float4 position)
{
   return pos_to_world(decompress_position(position));
}

float4 transform_unskinned_project(float4 position)
{
   return pos_project(transform_unskinned(position));
}

float4 transform_skinned(float4 position, uint4 indices)
{
   return pos_to_world(pos_to_skinned_object(decompress_position(position), indices));
}

float4 transform_skinned_project(float4 position, uint4 indices)
{
   return pos_project(transform_skinned(position, indices));
}

Near_scene calculate_near_scene_fade(float4 world_position)
{
   Near_scene result;

   result.view_z = dot(world_position, projection_matrix[3]);
   result.fade = result.view_z * near_scene_fade.x + near_scene_fade.y;

   return result;
}

Near_scene clamp_near_scene_fade(Near_scene near_scene)
{
   near_scene.fade = max(near_scene.fade, constant_0.x);
   near_scene.fade = min(near_scene.fade, constant_0.z);
   near_scene.fade = near_scene.fade * near_scene.fade;

   return near_scene;
}

float calculate_fog(Near_scene near_scene, float4 world_position)
{
   float x = near_scene.view_z * fog_info.x + fog_info.y;
   float y = world_position.y * fog_info.z + fog_info.w;

   return min(x, y);
}

#endif