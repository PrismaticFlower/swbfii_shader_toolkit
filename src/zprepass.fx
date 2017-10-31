
#include "constants_list.hlsl"
#include "vertex_utilities.hlsl"

float4 x_texcoord_transform : register(vs, c[CUSTOM_CONST_MIN + 0]);
float4 y_texcoord_transform : register(vs, c[CUSTOM_CONST_MIN + 1]);

sampler diffuse_map_sampler;

struct Vs_opaque_skinned_in
{
   float4 position : POSITION;
   float4 weights : BLENDWEIGHT;
   uint4 blend_indices : BLENDINDICES;
};

float4 opaque_hard_skinned_vs(Vs_opaque_skinned_in input) : POSITION
{
   return transform_hard_skinned_project(input.position, input.blend_indices);
}

float4 opaque_soft_skinned_vs(Vs_opaque_skinned_in input) : POSITION
{
   return transform_skinned_project(input.position, input.weights,
                                    input.blend_indices);
}

float4 opaque_unskinned_vs(float4 position : POSITION) : POSITION
{
   return transform_unskinned_project(position);
}

struct Vs_hardedged_output
{
   float4 position : POSITION;
   float2 texcoords : TEXCOORD;
   float4 color : COLOR;
};

struct Vs_hardedged_input
{
   float4 position : POSITION;
   float4 weights : BLENDWEIGHT;
   uint4 blend_indices : BLENDINDICES;
   float4 texcoords : TEXCOORD;
   float4 color : COLOR;
};

Vs_hardedged_output hardedged_vs(Vs_hardedged_input input)
{
   Vs_hardedged_output output;

   output.position = input.position;
   output.texcoords = decompress_transform_texcoords(input.texcoords, x_texcoord_transform,
                                                     y_texcoord_transform);
   output.color = material_diffuse_color;

   return output;
}

Vs_hardedged_output hardedged_hard_skinned_vs(Vs_hardedged_input input)
{
   input.position = transform_hard_skinned_project(input.position, input.blend_indices);

   return hardedged_vs(input);
}

Vs_hardedged_output hardedged_soft_skinned_vs(Vs_hardedged_input input)
{
   input.position = transform_skinned_project(input.position, input.weights, 
                                              input.blend_indices);

   return hardedged_vs(input);;
}

Vs_hardedged_output hardedged_unskinned_vs(Vs_hardedged_input input)
{
   input.position = transform_unskinned_project(input.position);

   return hardedged_vs(input);;
}

// Pixel Shaders

float4 opaque_ps() : COLOR
{
   return float4(0.0, 0.0, 0.0, 1.0);
}

struct Ps_hardedged_input
{
   float2 texcoords : TEXCOORD;
   float4 color : COLOR;
};

float4 hardedged_ps(Ps_hardedged_input input) : COLOR
{
   return tex2D(diffuse_map_sampler, input.texcoords) * input.color;
}