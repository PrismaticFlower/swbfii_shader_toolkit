#ifndef TRANSFORM_UTILS_INCLUDED
#define TRANSFORM_UTILS_INCLUDED

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

namespace hard_skinned
{

float4 position(float4 position, uint4 indices, float4 weights)
{
   int index = (indices.xyz * constant_1.www).x;

   position = decompress_position(position);

   float4 obj_position;

   obj_position.x = dot(position, bone_matrices[0 + index]);
   obj_position.y = dot(position, bone_matrices[1 + index]);
   obj_position.z = dot(position, bone_matrices[2 + index]);
   obj_position.w = constant_0.z;

   return obj_position;
}

float3 normals(float3 normals, uint4 indices, float4 weights)
{
   normals = decompress_normals(normals);

   int index = indices.x * constant_1.w;

   float3 obj_normal;

   obj_normal.x = dot(normals, bone_matrices[0 + index].xyz);
   obj_normal.y = dot(normals, bone_matrices[1 + index].xyz);
   obj_normal.z = dot(normals, bone_matrices[2 + index].xyz);

   float normalizer = dot(obj_normal, obj_normal);
   normalizer = rsqrt(normalizer);
   obj_normal *= normalizer;

   return obj_normal;
}

Binormals binormals(float3 binormal, float3 tangent, uint4 indices, float4 weights)
{
   Binormals binormals = decompress_binormals(binormal, tangent);

   Binormals obj_binormals;

   int index = indices.x * constant_1.w;

   obj_binormals.s.x = dot(binormals.s, bone_matrices[0 + index].xyz);
   obj_binormals.s.y = dot(binormals.s, bone_matrices[1 + index].xyz);
   obj_binormals.s.z = dot(binormals.s, bone_matrices[2 + index].xyz);

   obj_binormals.t.x = dot(binormals.t, bone_matrices[0 + index].xyz);
   obj_binormals.t.y = dot(binormals.t, bone_matrices[1 + index].xyz);
   obj_binormals.t.z = dot(binormals.t, bone_matrices[2 + index].xyz);

   float normalizer = dot(obj_binormals.s, obj_binormals.s);
   normalizer = rsqrt(normalizer);
   obj_binormals.s *= normalizer;

   normalizer = dot(obj_binormals.t, obj_binormals.t);
   normalizer = rsqrt(normalizer);
   obj_binormals.t *= normalizer;

   return obj_binormals;
}

}

namespace soft_skinned
{

void calculate_skin(float4 weights, uint4 vertex_indices, out float4 skin[3])
{
   int3 indices = vertex_indices.xyz * constant_1.www;

   skin[0] = weights.x * bone_matrices[0 + indices.x];
   skin[1] = weights.x * bone_matrices[1 + indices.x];
   skin[2] = weights.x * bone_matrices[2 + indices.x];

   skin[0] += (weights.y *  bone_matrices[0 + indices.y]);
   skin[1] += (weights.y *  bone_matrices[1 + indices.y]);
   skin[2] += (weights.y *  bone_matrices[2 + indices.y]);

   float z_weight = dot(weights, constant_0.wwxz);

   skin[0] += (z_weight *  bone_matrices[0 + indices.y]);
   skin[1] += (z_weight *  bone_matrices[1 + indices.y]);
   skin[2] += (z_weight *  bone_matrices[2 + indices.y]);
}

float4 position(float4 position, uint4 indices, float4 weights)
{
   position = decompress_position(position);

   float4 skin[3];

   calculate_skin(weights, indices, skin);

   float4 obj_position;

   obj_position.x = dot(position, skin[0]);
   obj_position.y = dot(position, skin[1]);
   obj_position.z = dot(position, skin[2]);
   obj_position.w = constant_0.z;

   return obj_position;
}

float3 normals(float3 normals, uint4 indices, float4 weights)
{
   normals = decompress_normals(normals);

   float4 skin[3];

   calculate_skin(weights, indices, skin);

   float3 obj_normal;

   obj_normal.x = dot(normals, skin[0].xyz);
   obj_normal.y = dot(normals, skin[1].xyz);
   obj_normal.z = dot(normals, skin[2].xyz);

   float normalizer = dot(obj_normal, obj_normal);
   normalizer = rsqrt(normalizer);
   obj_normal *= normalizer;

   return obj_normal;
}

Binormals binormals(float3 binormal, float3 tangent, uint4 indices, float4 weights)
{
   Binormals binormals = decompress_binormals(binormal, tangent);

   float4 skin[3];

   calculate_skin(weights, indices, skin);

   Binormals obj_binormals;

   int index = indices.x * constant_1.w;

   obj_binormals.s.x = dot(binormals.s, skin[0].xyz);
   obj_binormals.s.y = dot(binormals.s, skin[1].xyz);
   obj_binormals.s.z = dot(binormals.s, skin[2].xyz);

   obj_binormals.t.x = dot(binormals.t, skin[0].xyz);
   obj_binormals.t.y = dot(binormals.t, skin[1].xyz);
   obj_binormals.t.z = dot(binormals.t, skin[2].xyz);

   float normalizer = dot(obj_binormals.s, obj_binormals.s);
   normalizer = rsqrt(normalizer);
   obj_binormals.s *= normalizer;

   normalizer = dot(obj_binormals.t, obj_binormals.t);
   normalizer = rsqrt(normalizer);
   obj_binormals.t *= normalizer;

   return obj_binormals;
}

}

#ifdef TRANSFORM_HARD_SKINNED
#define skin_type_position hard_skinned::position
#define skin_type_normals hard_skinned::normals
#define skin_type_binormals hard_skinned::binormals
#elif defined(TRANSFORM_SOFT_SKINNED)
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

#endif