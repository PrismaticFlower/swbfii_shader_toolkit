
#include "constants_list.hlsl"
#include "vertex_utilities.hlsl"
#include "transform_utilities.hlsl"
#include "lighting_utilities.hlsl"

float4 texture_transforms[2] : register(vs, c[CUSTOM_CONST_MIN]);

float4 light_constants[7] : register(vs, c[21]);

// helper functions for constants

float4 get_light_position(const uint light)
{
   if (light == 0) return light_constants[0];
   if (light == 1) return light_constants[2];
   if (light == 2) return light_constants[4];

   return float4(0.0, 0.0, 0.0, 1.0);
}

float4 get_light_params(const uint light)
{
   if (light == 0) return light_constants[1];
   if (light == 1) return light_constants[3];
   if (light == 2) return light_constants[5];

   return float4(0.0, 0.0, 0.0, 1.0);
}

float4 get_spotlight_position()
{
   return light_constants[0];
}

float4 get_spotlight_params()
{
   return light_constants[1];
}

float4 get_spotlight_direction()
{
   return light_constants[2];
}

Binormals generate_birnormals(float3 world_normal)
{
   Binormals binormals;

   //Pandemic's note: we rely on the fact that the object is world axis aligned
   binormals.s = -world_normal.x * world_normal + constant_0.zxx;
   binormals.s *= rsqrt(binormals.s.x);

   binormals.t = -world_normal.z * world_normal + constant_0.xxz;
   binormals.t *= rsqrt(binormals.t.z);

   return binormals;
}

float get_light_radius(float4 light_params)
{
   return (1.0 / light_params.x) * light_params.y;
}

struct Vs_input
{
   float4 position : POSITION;
   float3 normals : NORMAL;
   float3 binormal : BINORMAL;
   float3 tangent : TANGENT;
   uint4 blend_indices : BLENDINDICES;
   float4 weights : BLENDWEIGHT;
   float4 texcoords : TEXCOORD;
   float4 color : COLOR;
};

struct Vs_3lights_output
{
   float4 position : POSITION;
   float1 fog : FOG;
   float3 ambient_color : COLOR;
   float2 texcoords : TEXCOORD0;

   float3 normal : TEXCOORD1;
   float3 binormal : TEXCOORD2;
   float3 tangent : TEXCOORD3;

   float3 world_position : TEXCOORD4;

   float4 light_position_0 : TEXCOORD5;
   float4 light_position_1 : TEXCOORD6;
   float4 light_position_2 : TEXCOORD7;
};

Vs_3lights_output lights_3_vs(Vs_input input)
{
   Vs_3lights_output output;

   float4 world_position = transform::position(input.position, input.blend_indices,
                                               input.weights);

   output.world_position = world_position.xyz;
   output.position = position_project(world_position);
   output.fog = calculate_fog(world_position);

   output.texcoords = decompress_transform_texcoords(input.texcoords,
                                                     texture_transforms[0],
                                                     texture_transforms[1]);

   float3 world_normals = normals_to_world(transform::normals(input.normals,
                                           input.blend_indices,
                                           input.weights));

   Binormals world_binormals = binormals_to_world(transform::binormals(input.binormal,
                                                  input.tangent,
                                                  input.blend_indices,
                                                  input.weights));

   output.normal = world_normals;
   output.binormal = world_binormals.s;
   output.tangent = world_binormals.t;

   float4 static_diffuse_color = get_static_diffuse_color(input.color);

   float3 ambient_light = light::ambient(world_normals);
   ambient_light += static_diffuse_color.rgb;
   output.ambient_color = ambient_light * light_ambient_color_top.a;

   output.light_position_0.xyz = get_light_position(0).xyz;
   output.light_position_0.w = get_light_radius(get_light_params(0));

   output.light_position_1.xyz = get_light_position(1).xyz;
   output.light_position_1.w = get_light_radius(get_light_params(1));

   output.light_position_2.xyz = get_light_position(2).xyz;
   output.light_position_2.w = get_light_radius(get_light_params(2));

   return output;
}

Vs_3lights_output lights_3_genbinormals_vs(Vs_input input)
{
   Vs_3lights_output output = lights_3_vs(input);

   Binormals world_binormals = generate_birnormals(output.normal);

   output.binormal = world_binormals.s;
   output.tangent = world_binormals.t;

   return output;
}

Vs_3lights_output lights_3_genbinormals_terrain_vs(Vs_input input)
{
   Vs_3lights_output output = lights_3_genbinormals_vs(input);

   output.texcoords.x = dot(float4(output.world_position, 1.0), texture_transforms[0].xzyw);
   output.texcoords.y = dot(float4(output.world_position, 1.0), texture_transforms[1].xzyw);

   return output;
}

float get_spotlight_range()
{
   return (1.0 / get_spotlight_params().x) * get_spotlight_params().y;
}

float4 transform_spotlight_projection(float4 world_position)
{
   float4 projection_coords;

   projection_coords.x = dot(world_position, light_constants[3]);
   projection_coords.y = dot(world_position, light_constants[4]);
   projection_coords.z = dot(world_position, light_constants[5]);
   projection_coords.w = dot(world_position, light_constants[6]);

   return projection_coords;
}

struct Vs_spotlight_output
{
   float4 position : POSITION;
   float1 fog : FOG;
   float3 ambient_color : COLOR;
   float2 texcoords : TEXCOORD0;

   float3 normal : TEXCOORD1;
   float3 binormal : TEXCOORD2;
   float3 tangent : TEXCOORD3;

   float3 world_position : TEXCOORD4;

   float4 light_position : TEXCOORD5;
   float3 light_direction : TEXCOORD6;
   float4 projection_coords : TEXCOORD7;
};

Vs_spotlight_output spotlight_vs(Vs_input input)
{
   Vs_spotlight_output output;

   float4 world_position = transform::position(input.position, input.blend_indices,
                                               input.weights);

   output.world_position = world_position.xyz;
   output.position = position_project(world_position);
   output.fog = calculate_fog(world_position);

   output.texcoords = decompress_transform_texcoords(input.texcoords,
                                                     texture_transforms[0],
                                                     texture_transforms[1]);

   float3 world_normals = normals_to_world(transform::normals(input.normals,
                                           input.blend_indices,
                                           input.weights));

   Binormals world_binormals = binormals_to_world(transform::binormals(input.binormal,
                                                  input.tangent,
                                                  input.blend_indices,
                                                  input.weights));

   output.normal = world_normals;
   output.binormal = world_binormals.s;
   output.tangent = world_binormals.t;

   float4 static_diffuse_color = get_static_diffuse_color(input.color);

   float3 ambient_light = light::ambient(world_normals);
   ambient_light += static_diffuse_color.rgb;
   output.ambient_color = ambient_light * light_ambient_color_top.a;

   output.light_position.xyz = get_spotlight_position().xyz;
   output.light_position.w = get_spotlight_range();  
   output.light_direction.xyz = get_spotlight_direction().xyz;

   output.projection_coords = transform_spotlight_projection(world_position);

   return output;
}

Vs_spotlight_output spotlight_genbinormals_vs(Vs_input input)
{
   Vs_spotlight_output output = spotlight_vs(input);

   Binormals world_binormals = generate_birnormals(output.normal);

   output.binormal = world_binormals.s;
   output.tangent = world_binormals.t;

   return output;
}

Vs_spotlight_output spotlight_genbinormals_terrain_vs(Vs_input input)
{
   Vs_spotlight_output output = spotlight_genbinormals_vs(input);

   output.texcoords.x = dot(float4(output.world_position, 1.0), texture_transforms[0].xzyw);
   output.texcoords.y = dot(float4(output.world_position, 1.0), texture_transforms[1].xzyw);

   return output;
}

struct Ps_3lights_input
{
   float3 ambient_color : COLOR;
   float2 texcoords : TEXCOORD0;

   float3 normal : TEXCOORD1;
   float3 binormal : TEXCOORD2;
   float3 tangent : TEXCOORD3;

   float3 world_position : TEXCOORD4;

   float4 light_position_0 : TEXCOORD5;
   float4 light_position_1 : TEXCOORD6;
   float4 light_position_2 : TEXCOORD7;
};

float4 light_colors[3] : register(ps, c[0]);

sampler2D normal_map : register(ps, s[0]);

float3 calculate_light_normalmap(float3 world_position, float3 texel_normal,
                                 float3 world_normal, float4 light_position,
                                 float4 light_color)
{
   float3 light_normal = normalize(light_position.xyz - world_position);

   float light_distance = distance(world_position, light_position.xyz);
   float radius = light_position.w;

   float attenuation = 1.0 - light_distance * light_distance / (radius * radius);
   attenuation = saturate(attenuation);
   attenuation *= attenuation;

   float difference = saturate(dot(light_normal, texel_normal));

   if (light_position.w == 0.0) attenuation = saturate(dot(light_normal, world_normal));

   return attenuation * (light_color.rgb * difference);
}

float3 calculate_light(float3 world_position, float3 world_normal, float4 light_position,
                       float4 light_color)
{
   float3 light_normal = normalize(light_position.xyz - world_position);

   float light_distance = distance(world_position, light_position.xyz);
   float radius = light_position.w;

   float attenuation = 1.0 - light_distance * light_distance / (radius * radius);
   attenuation = saturate(attenuation);
   attenuation *= attenuation;

   if (light_position.w == 0.0) attenuation = saturate(dot(light_normal, world_normal));

   return attenuation * light_color.rgb;
}

float4 lights_normalmap_ps(Ps_3lights_input input, const uint light_count)
{
   float3 texel_normal = tex2D(normal_map, input.texcoords).rgb - float3(0.5, 0.5, 0.5);

   texel_normal = normalize(texel_normal.x * input.tangent -
                            texel_normal.y * input.binormal +
                            texel_normal.z * input.normal);

   float3 color = input.ambient_color;

   // This code depends on the compilers dead code elimination
   // in theory it should work all the time. If it doesn't
   // then lights_*_normalmap_ps will need to have this code
   // hoisted out into it.

   if (light_count >= 1) {
      color += calculate_light_normalmap(input.world_position, texel_normal,
                                         input.normal, input.light_position_0, 
                                         light_colors[0]);
   }
   if (light_count >= 2) {
      color += calculate_light_normalmap(input.world_position, texel_normal,
                                         input.normal, input.light_position_1, 
                                         light_colors[1]);
   }
   if (light_count >= 3) {
      color += calculate_light_normalmap(input.world_position, texel_normal,
                                         input.normal, input.light_position_2, 
                                         light_colors[2]);
   }

   color = saturate(color);

   return float4(color, 1.0);
}

float4 lights_3_normalmap_ps(Ps_3lights_input input) : COLOR
{
   return lights_normalmap_ps(input, 3);
}

float4 lights_2_normalmap_ps(Ps_3lights_input input) : COLOR
{
   return lights_normalmap_ps(input, 2);
}

float4 lights_1_normalmap_ps(Ps_3lights_input input) : COLOR
{
   return lights_normalmap_ps(input, 1);
}

float4 lights_ps(Ps_3lights_input input, const uint light_count)
{
   float3 color = input.ambient_color;

   // This code depends on the compilers dead code elimination
   // in theory it should work all the time. If it doesn't
   // then lights_*_ps will need to have this code
   // hoisted out into it.

   if (light_count >= 1) {
      color += calculate_light(input.world_position, input.normal, 
                               input.light_position_0, light_colors[0]);
   }
   if (light_count >= 2) {
      color += calculate_light(input.world_position, input.normal, 
                               input.light_position_1, light_colors[1]);
   }
   if (light_count >= 3) {
      color += calculate_light(input.world_position, input.normal, 
                               input.light_position_2, light_colors[2]);
   }

   color = saturate(color);

   return float4(color, 1.0);
}

float4 lights_3_ps(Ps_3lights_input input) : COLOR
{
   return lights_normalmap_ps(input, 3);
}

float4 lights_2_ps(Ps_3lights_input input) : COLOR
{
   return lights_normalmap_ps(input, 2);
}

float4 lights_1_ps(Ps_3lights_input input) : COLOR
{
   return lights_ps(input, 1);
}

sampler2D projection_map : register(ps, s[2]);

struct Ps_spotlight_input
{
   float3 ambient_color : COLOR;
   float2 texcoords : TEXCOORD0;

   float3 normal : TEXCOORD1;
   float3 binormal : TEXCOORD2;
   float3 tangent : TEXCOORD3;

   float3 world_position : TEXCOORD4;

   float4 light_position : TEXCOORD5;
   float3 light_direction : TEXCOORD6;
   float4 projection_coords : TEXCOORD7;
};

float3 calculate_spotlight_normalmap(float3 world_position, float3 texel_normal,
                                     float3 world_normal, float4 light_position,
                                     float3 light_direction, float4 light_color,
                                     float3 projection_color)
{
   float3 light_normal = normalize(light_position.xyz - world_position);

   float light_distance = distance(world_position, light_position.xyz);
   float range = light_position.w;

   float attenuation = dot(light_direction, -light_normal);
   attenuation -= light_distance * light_distance / (range * range);
   attenuation = saturate(attenuation);

   float difference = saturate(dot(light_normal, texel_normal));

   return attenuation * (projection_color * (light_color.rgb * difference));
}

float3 calculate_spotlight(float3 world_position, float3 world_normal, 
                           float4 light_position, float3 light_direction,
                           float4 light_color, float3 projection_color)
{
   float3 light_normal = normalize(light_position.xyz - world_position);

   float light_distance = distance(world_position, light_position.xyz);
   float range = light_position.w;

   float attenuation = dot(light_direction, -light_normal);
   attenuation -= light_distance * light_distance / (range * range);
   attenuation = saturate(attenuation);

   return attenuation * (projection_color * light_color.rgb);
}

float4 spotlight_normalmap_ps(Ps_spotlight_input input) : COLOR
{
   float3 texel_normal = tex2D(normal_map, input.texcoords).rgb - float3(0.5, 0.5, 0.5);

   texel_normal = normalize(texel_normal.x * input.tangent -
                            texel_normal.y * input.binormal +
                            texel_normal.z * input.normal);

   float3 projection_color = tex2Dproj(projection_map, input.projection_coords).rgb;

   float3 color = input.ambient_color;

   color += calculate_spotlight_normalmap(input.world_position, texel_normal,
                                          input.normal, input.light_position,
                                          input.light_direction, light_colors[0],
                                          projection_color);
   color = saturate(color);

   return float4(color, 1.0);
}

float4 spotlight_ps(Ps_spotlight_input input) : COLOR
{
   float3 projection_color = tex2Dproj(projection_map, input.projection_coords).rgb;

   float3 color = input.ambient_color;

   color += calculate_spotlight(input.world_position, input.normal, input.light_position, 
                                input.light_direction, light_colors[0], projection_color);
   color = saturate(color);

   return float4(color, 1.0);
}
