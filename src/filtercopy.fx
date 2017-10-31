
#include "vertex_utilities.hlsl"

float4 texcoord_offsets[4] : register(vs, c[CUSTOM_CONST_MIN]);

sampler textures[4];

struct Vs_input
{
   float4 position : POSITION;
   float4 texcoord : TEXCOORD;
};

struct Vs_output
{
   float4 position : POSITION;
   float2 texcoord_0 : TEXCOORD0;
   float2 texcoord_1 : TEXCOORD1;
   float2 texcoord_2 : TEXCOORD2;
   float2 texcoord_3 : TEXCOORD3;
};

Vs_output filtercopy_vs(Vs_input input)
{
   Vs_output output;

   output.position.xy = input.position.xy;
   output.position.zw = constant_0.yz;

   float2 texcoords = decompress_texcoords(input.texcoord);

   output.texcoord_0 = texcoords + texcoord_offsets[0].xy;
   output.texcoord_1 = texcoords + texcoord_offsets[1].xy;
   output.texcoord_2 = texcoords + texcoord_offsets[2].xy;
   output.texcoord_3 = texcoords + texcoord_offsets[3].xy;

   return output;
}

struct Ps_input
{
   float4 position : POSITION;
   float2 texcoord_0 : TEXCOORD0;
   float2 texcoord_1 : TEXCOORD1;
   float2 texcoord_2 : TEXCOORD2;
   float2 texcoord_3 : TEXCOORD3;
};

float4 filtercopy_1tex_ps(Ps_input input) : COLOR
{
   return tex2D(textures[0], input.texcoord_0) * constant_0;
}

float4 filtercopy_2tex_ps(Ps_input input) : COLOR
{
   float4 color = tex2D(textures[0], input.texcoord_0) * constant_0;
   color += (tex2D(textures[1], input.texcoord_1) * constant_1);

   return color;
}

float4 filtercopy_3tex_ps(Ps_input input) : COLOR
{
   float4 color = tex2D(textures[0], input.texcoord_0) * constant_0;
   color += (tex2D(textures[1], input.texcoord_1) * constant_1);
   color += (tex2D(textures[2], input.texcoord_2) * get_projection_matrix_row(0));

   return color;
}

float4 filtercopy_4tex_ps(Ps_input input) : COLOR
{
   float4 color = tex2D(textures[0], input.texcoord_0) * constant_0;
   color += (tex2D(textures[1], input.texcoord_1) * constant_1);
   color += (tex2D(textures[2], input.texcoord_2) * get_projection_matrix_row(0));
   color += (tex2D(textures[3], input.texcoord_3) * get_projection_matrix_row(1));

   return color;
}