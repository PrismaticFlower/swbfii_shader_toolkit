#ifndef VERTEX_UTILS_INCLUDED
#define VERTEX_UTILS_INCLUDED

#include "constants_list.hlsl"

struct Near_scene
{
   float view_z;
   float fade;
};

struct Binormals
{
   float3 s;
   float3 t;
};

float4 get_projection_matrix_row(const uint i)
{
   if (i == 0) {
      return float4(projection_matrix[0].x, projection_matrix[1].x,
         projection_matrix[2].x, projection_matrix[3].x);
   }
   else if (i == 1) {
      return float4(projection_matrix[0].y, projection_matrix[1].y,
         projection_matrix[2].y, projection_matrix[3].y);
   }
   else if (i == 2) {
      return float4(projection_matrix[0].z, projection_matrix[1].z,
         projection_matrix[2].z, projection_matrix[3].z);
   }
   else if (i == 3) {
      return float4(projection_matrix[0].w, projection_matrix[1].w,
         projection_matrix[2].w, projection_matrix[3].w);
   }

   return float4(0, 0, 0, 0);
}

float4 get_world_matrix_row(const uint i)
{
   if (i == 0) {
      return float4(world_matrix[0].x, world_matrix[1].x,
                    world_matrix[2].x, world_matrix[3].x);
   }
   else if (i == 1) {
      return float4(world_matrix[0].y, world_matrix[1].y,
                    world_matrix[2].y, world_matrix[3].y);
   }
   else if (i == 2) {
      return float4(world_matrix[0].z, world_matrix[1].z,
                    world_matrix[2].z, world_matrix[3].z);
   }

   return float4(0, 0, 0, 0);
}

float4 decompress_position(float4 position)
{
   position = position_decompress_min * position;
   return position_decompress_max + position;
}

float2 decompress_texcoords(float4 texcoords)
{
   return (texcoords * normaltex_decompress.zzzw).xy;
}

float2 decompress_transform_texcoords(float4 texcoords, float4 x_transform, 
                                      float4 y_transform)
{
   texcoords *= normaltex_decompress.zzzw;

   float2 transformed;

   transformed.x = dot(texcoords, x_transform);
   transformed.y = dot(texcoords, y_transform);

   return transformed;
}

float3 decompress_normals(float3 normals)
{
   return normals.xyz * normaltex_decompress.xxx + normaltex_decompress.yyy;
}

float3 decompress_transform_normals(float3 normals)
{
   normals = decompress_normals(normals);

   float3 world_normals;

   world_normals.x = dot(normals, get_world_matrix_row(0).xyz);
   world_normals.y = dot(normals, get_world_matrix_row(1).xyz);
   world_normals.z = dot(normals, get_world_matrix_row(2).xyz);

   return world_normals;
}

float4 get_material_color(float4 color)
{
   return (color * color_state.yyyw + color_state.xxxz) * material_diffuse_color;
}

float4 get_static_diffuse_color(float4 color)
{
   return color * color_state.xxxz + color_state.zzzz;
}

float4 pos_to_hard_skinned_object(float4 position, uint4 indices)
{
   int index = (indices.xyz * constant_1.www).x;

   float4 result;

   result.x = dot(position, bone_matrices[0 + index]);
   result.y = dot(position, bone_matrices[1 + index]);
   result.z = dot(position, bone_matrices[2 + index]);
   result.w = constant_0.z;

   return result;
}

float4 pos_to_skinned_object(float4 position, float4 weights, uint4 vertex_indices)
{
   int3 indices = vertex_indices.xyz * constant_1.www;

   float4 skin_0 = weights.x * bone_matrices[0 + indices.x];
   float4 skin_1 = weights.x * bone_matrices[1 + indices.x];
   float4 skin_2 = weights.x * bone_matrices[2 + indices.x];

   skin_0 += (weights.y *  bone_matrices[0 + indices.y]);
   skin_1 += (weights.y *  bone_matrices[1 + indices.y]);
   skin_2 += (weights.y *  bone_matrices[2 + indices.y]);

   float z_weight = dot(weights, constant_0.wwxz);

   skin_0 += (z_weight *  bone_matrices[0 + indices.y]);
   skin_1 += (z_weight *  bone_matrices[1 + indices.y]);
   skin_2 += (z_weight *  bone_matrices[2 + indices.y]);

   float4 result;

   result.x = dot(position, skin_0);
   result.y = dot(position, skin_1);
   result.z = dot(position, skin_2);
   result.w = constant_0.z;

   return result;
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

float4 transform_hard_skinned(float4 position, uint4 indices)
{
   return pos_to_world(pos_to_hard_skinned_object(decompress_position(position), indices));
}

float4 transform_hard_skinned_project(float4 position, uint4 indices)
{
   return pos_project(transform_hard_skinned(position, indices));
}

float4 transform_skinned(float4 position, float4 weights, uint4 indices)
{
   return pos_to_world(pos_to_skinned_object(decompress_position(position), weights, indices));
}

float4 transform_skinned_project(float4 position, float4 weights, uint4 indices)
{
   return pos_project(transform_skinned(position, weights, indices));
}

float3 transform_normals_unskinned(float4 normals)
{
   return normals.xyz * normaltex_decompress.xxx + normaltex_decompress.yyy;
}

Binormals transform_binormals_unskinned(float4 binormal, float4 tangent)
{
   Binormals binormals;

   binormals.s = binormal.xyz * normaltex_decompress.xxx + normaltex_decompress.yyy;
   binormals.t = tangent.xyz * normaltex_decompress.xxx + normaltex_decompress.yyy;

   return binormals;
}

float4 transform_shadowmap_coords(float4 world_position)
{
   float4 coords;

   coords.x = dot(world_position, shadow_map_transform[0]);
   coords.y = dot(world_position, shadow_map_transform[1]);
   coords.z = dot(world_position, shadow_map_transform[2]);
   coords.w = constant_0.x;

   return coords;
}

Near_scene calculate_near_scene_fade(float4 world_position)
{
   Near_scene result;

   result.view_z = dot(world_position, get_projection_matrix_row(3));
   result.fade = result.view_z * near_scene_fade.x + near_scene_fade.y;

   return result;
}

Near_scene clamp_near_scene_fade(Near_scene near_scene)
{
   near_scene.fade = max(near_scene.fade, constant_0.x);
   near_scene.fade = min(near_scene.fade, constant_0.z);

   return near_scene;
}

float calculate_fog(Near_scene near_scene, float4 world_position)
{
   float x = near_scene.view_z * fog_info.x + fog_info.y;
   float y = world_position.y * fog_info.z + fog_info.w;

   return min(x, y);
}

float calculate_fog(float4 world_position)
{
   float view_z = dot(world_position, get_projection_matrix_row(3));

   float x = view_z * fog_info.x + fog_info.y;
   float y = world_position.y * fog_info.z + fog_info.w;

   return min(x, y);
}

#endif