
#include "constants_list.hlsl"
#include "vertex_utilities.hlsl"
#include "transform_utilities.hlsl"

float4 x_texcoord_transform : register(vs, c[CUSTOM_CONST_MIN + 0]);
float4 y_texcoord_transform : register(vs, c[CUSTOM_CONST_MIN + 1]);
float2 linear_z : register(vs, c[100]);

sampler diffuse_map_sampler;

struct Vs_input
{
   float4 position : POSITION;
   float4 weights : BLENDWEIGHT;
   uint4 blend_indices : BLENDINDICES;
   float4 texcoords : TEXCOORD;
};

struct Vs_output
{
   float4 position : POSITION;
   float2 texcoords : TEXCOORD0;
   float4 color : COLOR;
   float depth : DEPTH;
};

Vs_output main_vs(Vs_input input)
{
   Vs_output output;
   
   output.position = transform::position_project(input.position, input.blend_indices, 
                                                 input.weights);

   float depth = saturate(output.position.z / output.position.w);

   const float z_max = 1.0;
   const float z_min = 0.0;

   // const float z_near = 0.5;
   const float z_near = 0.3;
   const float z_far = 500.0;

   // The hardware depths are linearized in two steps:
   // 1. Inverse viewport from [zmin,zmax] to [0,1]: z' = (z - zmin) / (zmax - zmin)
   // 2. Inverse projection from [0,1] to [znear,zfar]: w = 1 / (a z' + b)

   // w = 1 / [(1/zfar - 1/znear) * z' + 1/znear]
   float lin_a = 1.0f / z_far - 1.0f / z_near;
   float lin_b = 1.0f / z_near;

   // w = 1 / [(1/zfar - 1/znear) * (z - zmin)/(zmax - zmin) + 1/znear]
   float z_range = z_max - z_min;
   lin_a /= z_range;
   lin_b -= z_min * lin_a;

   output.depth = 1.0f / (depth * linear_z.x + linear_z.y);

   output.texcoords = decompress_transform_texcoords(input.texcoords, x_texcoord_transform,
                                                     y_texcoord_transform);
   output.color = material_diffuse_color;

   return output;
}

// Pixel Shaders

float4 opaque_ps(float depth : DEPTH) : COLOR
{
   return depth;
}

struct Ps_hardedged_input
{
   float depth : DEPTH;
   float2 texcoords : TEXCOORD0;
   float4 color : COLOR;
};

float4 hardedged_ps(Ps_hardedged_input input) : COLOR
{
   float4 color = tex2D(diffuse_map_sampler, input.texcoords) * input.color;

   if (color.a < 0.5) return 0;

   return float4(input.depth.xxx, 1.0);
}