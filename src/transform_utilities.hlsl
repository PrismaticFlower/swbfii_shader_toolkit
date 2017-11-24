#ifndef TRANSFORM_UTILS_INCLUDED
#define TRANSFORM_UTILS_INCLUDED

#pragma warning(disable : 3206)

#include "constants_list.hlsl"
#include "vertex_utilities.hlsl"

namespace transform
{

namespace unskinned
{

float4 position(float4 position, uint4 indices, float4 weights)
{
   return decompress_position(position);
}

float3 normals(float3 normals, uint4 indices, float4 weights)
{
   return decompress_normals(normals);
}

Binormals binormals(float3 binormal, float3 tangent, uint4 indices, float4 weights)
{
   return decompress_binormals(binormal, tangent);
}

}

namespace soft_skinned
{

float3x4 get_bone_matrix(int index)
{
   float3x4 mat;

   mat[0] = bone_matrices[0 + index];
   mat[1] = bone_matrices[1 + index];
   mat[2] = bone_matrices[2 + index];

   return mat;
}

float3x4 calculate_skin(float4 weights, uint4 vertex_indices)
{
   int3 indices = vertex_indices.xyz * constant_1.www;
   
   float3x4 skin;

   skin = weights.x * get_bone_matrix(indices.x);

   skin += (weights.y *  get_bone_matrix(indices.y));

   float z_weight = 1 - weights.x - weights.y;

   skin += (z_weight *  get_bone_matrix(indices.z));

   return skin;
}

float4 position(float4 position, uint4 indices, float4 weights)
{
   position = decompress_position(position);

   float3x4 skin = calculate_skin(weights, indices);

   return float4(mul(skin, position), constant_0.z);
}

float3 normals(float3 normals, uint4 indices, float4 weights)
{
   normals = decompress_normals(normals);
   
   float3x4 skin = calculate_skin(weights, indices);

   float3 obj_normal = mul(skin, normals);

   return normalize(obj_normal);
}

Binormals binormals(float3 binormal, float3 tangent, uint4 indices, float4 weights)
{
   Binormals binormals = decompress_binormals(binormal, tangent);

   float3x4 skin = calculate_skin(weights, indices);

   Binormals obj_binormals;

   obj_binormals.s = mul(skin, binormals.s);
   obj_binormals.t = mul(skin, binormals.t);

   obj_binormals.s = normalize(obj_binormals.s);
   obj_binormals.t = normalize(obj_binormals.t);
   
   return obj_binormals;
}

}

namespace hard_skinned
{

float4 position(float4 position, uint4 indices)
{
   int index = indices.x * constant_1.w;

   position = decompress_position(position);

   float3x4 skin = soft_skinned::get_bone_matrix(index);

   return float4(mul(skin, position), constant_0.z);
}

float3 normals(float3 normals, uint4 indices)
{
   int index = indices.x * constant_1.w;

   normals = decompress_normals(normals);

   float3x4 skin = soft_skinned::get_bone_matrix(index);

   float3 obj_normal = (float3) mul(skin, normals);

   return normalize(obj_normal);
}

Binormals binormals(float3 binormal, float3 tangent, uint4 indices)
{
   int index = indices.x * constant_1.w;

   Binormals binormals = decompress_binormals(binormal, tangent);

   float3x4 skin = soft_skinned::get_bone_matrix(index);

   Binormals obj_binormals;

   obj_binormals.s = mul(skin, binormals.s);
   obj_binormals.t = mul(skin, binormals.t);

   obj_binormals.s = normalize(obj_binormals.s);
   obj_binormals.t = normalize(obj_binormals.t);

   return obj_binormals;
}

}

#if defined(TRANSFORM_SOFT_SKINNED)
#define skin_type_position soft_skinned::position
#define skin_type_normals soft_skinned::normals
#define skin_type_binormals soft_skinned::binormals
#else
#define skin_type_position unskinned::position
#define skin_type_normals unskinned::normals
#define skin_type_binormals unskinned::binormals
#endif

float4 position(float4 position, uint4 indices, float4 weights)
{
   float4 obj_position = skin_type_position(position, indices, weights);

   return position_to_world(obj_position);
}

float4 position_obj(float4 position, uint4 indices, float4 weights)
{
   return skin_type_position(position, indices, weights);
}

float4 position_project(float4 world_position, uint4 indices, float4 weights)
{
   return ::position_project(position(world_position, indices, weights));
}

float3 normals(float3 normals, uint4 indices, float4 weights)
{
   return skin_type_normals(normals, indices, weights);
}

Binormals binormals(float3 binormal, float3 tangent, uint4 indices, float4 weights)
{
   return skin_type_binormals(binormal, tangent, indices, weights);
}

#undef skin_type_position
#undef skin_type_normals
#undef skin_type_binormals

// decompress and transform an unskinned vertex to it's world position
float4 position(float4 position)
{
   return position_to_world(decompress_position(position));
}

// decompress, transform an unskinned vertex to it's world position and project it
float4 position_project(float4 world_position)
{
   return ::position_project(position(world_position));
}

}

#pragma warning(default : 3206)

#endif