
#include "vertex_utilities.hlsl"

float4 texcoord_transforms[4] : register(vs, c[CUSTOM_CONST_MIN]);

sampler normal_map;
sampler base_normal_map;

struct Vs_input
{
   float4 position : POSITION;
   float4 texcoord : TEXCOORD;
   float4 binormal : BINORMAL;
   float4 tangent : TANGENT;
   float4 color : COLOR;
};

struct Vs_output
{
   float4 position : POSITION;
   float2 texcoord_0 : TEXCOORD0;
   float2 texcoord_1 : TEXCOORD1;
};

struct Vs_output_binormals
{
   float4 position : POSITION;
   float2 texcoord_0 : TEXCOORD0;
   float4 texcoord_1 : TEXCOORD1;
   float4 texcoord_2 : TEXCOORD2;
   float4 color : COLOR;
};

Vs_output normalmapadder_vs(Vs_input input)
{
   Vs_output output;
    
   output.position = transform_unskinned_project(input.position);
   output.texcoord_0 = decompress_transform_texcoords(input.texcoord,
                                                      texcoord_transforms[0], 
                                                      texcoord_transforms[1]);
   output.texcoord_1 = decompress_transform_texcoords(input.texcoord,
                                                      texcoord_transforms[2],
                                                      texcoord_transforms[3]);

   return output;
}

Vs_output_binormals normalmapadder_binormals_vs(Vs_input input)
{
   Vs_output_binormals output;

   output.position = transform_unskinned_project(input.position);

   Binormals binormals = transform_binormals_unskinned(input.binormal, input.tangent);

   float3 binormal_s;
   binormal_s.x = dot(get_world_matrix_row(0).xyz, binormals.s);
   binormal_s.y = dot(get_world_matrix_row(0).xyz, binormals.t);
   binormal_s.z = constant_0.y;

   float3 binormal_t;
   binormal_t.x = dot(get_world_matrix_row(2).xyz, binormals.s);
   binormal_t.y = dot(get_world_matrix_row(2).xyz, binormals.t);
   binormal_t.z = constant_0.y;

   output.texcoord_0 = decompress_texcoords(input.texcoord);

   output.texcoord_1.xyz = binormal_s.xyz * constant_0.yyy;
   output.texcoord_1 = constant_0.z;
   output.texcoord_2.xyz = binormal_t.xyz * constant_0.yyy;
   output.texcoord_2 = constant_0.z;

   output.color = input.color.w;

   return output;
}

struct Ps_input
{
   float4 position : POSITION;
   float2 texcoord_0 : TEXCOORD0;
   float4 texcoord_1 : TEXCOORD1;
   float4 texcoord_2 : TEXCOORD1;
   float4 color : COLOR;
};

// Not going to lie, everything below in the pixel shaders
// is probably hilariously incorrect. I don't do maths. (or Englishes)

float4 normalmapadder_ps(Ps_input input) : COLOR
{
   float4 tex0_biased = (tex2D(normal_map, input.texcoord_0) - 0.5) * 2.0;
   float4 tex1_biased = (tex2D(base_normal_map, input.texcoord_1.xy) - 0.5) * 2.0;

   const float4 lerp_value = get_projection_matrix_row(1).a;

   float4 color = lerp(lerp_value, tex1_biased, tex0_biased);

   float3 temp = dot(color, color) * 0.5;
   color.rgb = mad(-color.rgb, (temp - 0.5), color.rgb);

   color = (color + 1.0) * 0.5;

   return color;
}

float4 normalmapadder_binormals_ps(Ps_input input) : COLOR
{
   float4 tex_color = tex2D(normal_map, input.texcoord_0);
   float3 tex0_biased = (tex_color - 0.5).xyz * 2.0;

   float2 coords;

   coords.x = (tex0_biased.rgb * input.texcoord_1.xyz).x;
   coords.y = (tex0_biased.rgb * input.texcoord_2.xyz).x;

   float4 color = tex2D(base_normal_map, coords);

   color.a = input.color.a * tex_color.a;

   return color;
}