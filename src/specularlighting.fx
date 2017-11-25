
#include "constants_list.hlsl"
#include "vertex_utilities.hlsl"
#include "transform_utilities.hlsl"
#include "lighting_utilities.hlsl"

float4 texture_transforms[2] : register(vs, c[CUSTOM_CONST_MIN]);

struct Vs_input
{
   float4 position : POSITION;
   float3 normals : NORMAL;
   float3 binormal : BINORMAL;
   float3 tangent : TANGENT;
   uint4 blend_indices : BLENDINDICES;
   float4 weights : BLENDWEIGHT;
   float4 texcoords : TEXCOORD;
};

struct Vs_normalmapped_ouput
{
   float4 position : POSITION;
   float1 fog : FOG;

   float2 texcoords : TEXCOORD0;

   float3 normal : TEXCOORD1;
   float3 binormal : TEXCOORD2;
   float3 tangent : TEXCOORD3;

   float3 world_position : TEXCOORD4;
   float4 light_position : TEXCOORD5;
};

Vs_normalmapped_ouput normalmapped_vs(Vs_input input,
                                      uniform float4 light_position : register(vs, c[CUSTOM_CONST_MIN + 2]))
{
   Vs_normalmapped_ouput output;

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

   output.light_position = light_position;

   // get squared light radius if the light is a point light
   if (light_position.w != 0.0) output.light_position.w = (1.0 / light_position.w);

   return output;
}

struct Vs_blinn_phong_ouput
{
   float4 position : POSITION;
   float1 fog : FOG;

   float2 texcoords : TEXCOORD0;

   float3 world_position : TEXCOORD1;
   float3 normal : TEXCOORD2;

   float4 light_position_0 : TEXCOORD3;
   float4 light_position_1 : TEXCOORD4;
   float4 light_position_2 : TEXCOORD5;

   float1 specular_power : TEXCOORD6;

   float3 envmap_coords : TEXCOORD7;
};

Vs_blinn_phong_ouput blinn_phong_vs(Vs_input input,
                                    uniform float4 specular_power : register(vs, c[CUSTOM_CONST_MIN + 2]),
                                    uniform float4 light_positions[3] : register(vs, c[CUSTOM_CONST_MIN + 3]))
{
   Vs_blinn_phong_ouput output;

   float4 world_position = transform::position(input.position, input.blend_indices,
                                               input.weights);

   output.world_position = world_position.xyz;
   output.position = position_project(world_position);
   output.fog = calculate_fog(world_position);

   output.texcoords = decompress_transform_texcoords(input.texcoords,
                                                     texture_transforms[0],
                                                     texture_transforms[1]);

   float3 world_normal = normals_to_world(transform::normals(input.normals,
                                                             input.blend_indices,
                                                             input.weights));

   output.normal = world_normal;

   output.light_position_0 = light_positions[0];
   output.light_position_1 = light_positions[1];
   output.light_position_2 = light_positions[2];

   // get the squared light radius for each light if they are point lights
   if (light_positions[0].w != 0.0) output.light_position_0.w = (1.0 / light_positions[0].w);
   if (light_positions[1].w != 0.0) output.light_position_1.w = (1.0 / light_positions[1].w);
   if (light_positions[2].w != 0.0) output.light_position_2.w = (1.0 / light_positions[2].w);

   output.specular_power = specular_power.w;

   float3 camera_direction = normalize(world_view_position.xyz - world_position.xyz);
   output.envmap_coords = normalize(reflect(world_normal, camera_direction));

   return output;
}

struct Vs_normalmapped_envmap_ouput
{
   float4 position : POSITION;
   float1 fog : FOG;

   float2 texcoords : TEXCOORD0;
   float3 envmap_coords : TEXCOORD1;
   float3 normal : TEXCOORD2;
   float3 binormal : TEXCOORD3;
   float3 tangent : TEXCOORD4;
   float3 world_position : TEXCOORD5;
   float3 world_view_position : TEXCOORD6;
};

Vs_normalmapped_envmap_ouput normalmapped_envmap_vs(Vs_input input)
{
   Vs_normalmapped_envmap_ouput output;

   float4 world_position = transform::position(input.position, input.blend_indices,
                                               input.weights);

   output.world_position = world_position.xyz;
   output.world_view_position = world_view_position.xyz;
   output.position = position_project(world_position);
   output.fog = calculate_fog(world_position);

   output.texcoords = decompress_transform_texcoords(input.texcoords,
                                                     texture_transforms[0],
                                                     texture_transforms[1]);

   float3 world_normal = normals_to_world(transform::normals(input.normals,
                                          input.blend_indices,
                                          input.weights));

   Binormals world_binormals = binormals_to_world(transform::binormals(input.binormal,
                                                                       input.tangent,
                                                                       input.blend_indices,
                                                                       input.weights));

   output.normal = world_normal;
   output.binormal = world_binormals.s;
   output.tangent = world_binormals.t;

   float3 camera_direction = normalize(world_view_position.xyz - world_position.xyz);
   output.envmap_coords = normalize(reflect(world_normal, camera_direction));

   return output;
}

struct Ps_normalmapped_input
{
   float2 texcoords : TEXCOORD0;
   float3 normal : TEXCOORD1;
   float3 binormal : TEXCOORD2;
   float3 tangent : TEXCOORD3;
   float3 world_position : TEXCOORD4;

   // squared light radius in w or w = 0 if directional light
   float4 light_position : TEXCOORD5;
};

float4 normalmapped_ps(Ps_normalmapped_input input,
                       uniform sampler2D normal_map,
                       uniform float4 specular_color : register(ps, c[0]),
                       uniform float3 light_color : register(ps, c[2])) : COLOR
{
   float4 normal_map_color = tex2D(normal_map, input.texcoords);

   // calculate texel normal
   float3 texel_normal = normal_map_color.rgb - float3(0.5, 0.5, 0.5);

   texel_normal = normalize(texel_normal.x * input.tangent -
                            texel_normal.y * input.binormal +
                            texel_normal.z * input.normal);

   float3 light_normal = input.light_position.xyz - input.world_position;
   float attenuation;

   if (input.light_position.w == 0) {
      light_normal = input.light_position.xyz;
      attenuation = 1.0;
   }
   else {
      float distance = length(light_normal);
         
      attenuation = 1.0 - distance * distance / input.light_position.w;
      attenuation = saturate(attenuation);
      attenuation *= attenuation;
   }

   light_normal = normalize(light_normal);

   float3 view_normal = normalize(-input.world_position);

   float specular = saturate(dot(normalize(light_normal - view_normal), texel_normal));
   specular = pow(specular, 128);

   float gloss = lerp(1.0, normal_map_color.a, specular_color.a);

   float3 blended_specular_color = saturate((specular_color.rgb + light_color) / 2);
   float3 color = attenuation * (gloss * blended_specular_color * specular);

   return float4(color, normal_map_color.a);
}

struct Ps_blinn_phong_input
{
   float2 texcoords : TEXCOORD0;

   float3 world_position : TEXCOORD1;
   float3 normal : TEXCOORD2;

   float4 light_position_0 : TEXCOORD3;
   float4 light_position_1 : TEXCOORD4;
   float4 light_position_2 : TEXCOORD5;

   float1 specular_power : TEXCOORD6;

   float3 envmap_coords : TEXCOORD7;
};

void calculate_blinn_phong(float3 normal, float3 view_normal, float3 world_position,
                           float4 light_position, float3 light_color, 
                           float3 specular_color, float specular_power, float gloss,
                           inout float3 diffuse_out, inout float3 specular_out)
{
   float3 light_direction = normalize(light_position.xyz - world_position);

   float distance = length(light_direction);

   float attenuation = 1.0 - distance * distance / light_position.w;
   attenuation = saturate(attenuation);
   attenuation *= attenuation;

   if (light_position.w == 0) {
      light_direction = light_position.xyz;
      attenuation = max(dot(normal, light_direction), 0.0);
   }

   float3 half_vector = normalize(light_direction + view_normal);
   float specular_angle = max(dot(half_vector, normal), 0.0);
   float specular = pow(specular_angle, 18.86 * specular_power);

   float3 blended_specular_color = saturate((specular_color + light_color) / 2);

   diffuse_out += attenuation * light_color;
   specular_out += attenuation * (blended_specular_color * specular);
}

float4 blinn_phong_ps(Ps_blinn_phong_input input, sampler2D diffuse_map,
                      samplerCUBE envmap, float4 specular_color, float3 light_colors[3],
                      const uint light_count)
{
   float diffuse_alpha = tex2D(diffuse_map, input.texcoords).a;
   float gloss = lerp(1.0, diffuse_alpha, specular_color.a);

   float3 normal = normalize(input.normal);
   float3 view_normal = normalize(-input.world_position);

   float3 diffuse_color = float3(0.0, 0.0, 0.0);
   float3 spec_color = float3(0.0, 0.0, 0.0);

   if (light_count >= 1) {
      calculate_blinn_phong(normal, view_normal, input.world_position, 
                            input.light_position_0, light_colors[0], 
                            specular_color.rgb, input.specular_power, gloss,
                            diffuse_color, spec_color);
   }
   if (light_count >= 2) {
      calculate_blinn_phong(normal, view_normal, input.world_position,
                            input.light_position_1, light_colors[1], 
                            specular_color.rgb, input.specular_power, gloss,
                            diffuse_color, spec_color);
   }
   if (light_count >= 3) {
      calculate_blinn_phong(normal, view_normal, input.world_position,
                            input.light_position_2, light_colors[2], 
                            specular_color.rgb, input.specular_power, gloss,
                            diffuse_color, spec_color);
   }

   float3 envmap_color = texCUBE(envmap, input.envmap_coords).rgb;

   float3 reflection = (envmap_color * envmap_color);

   float3 color = saturate(gloss * ((diffuse_color * envmap_color) + spec_color));

   return float4(color, diffuse_alpha);
}

float4 blinn_phong_lights_3_ps(Ps_blinn_phong_input input,
                               uniform sampler2D diffuse_map, uniform samplerCUBE envmap,
                               uniform float4 specular_color : register(ps, c[0]),
                               uniform float3 light_colors[3] : register(ps, c[2])) : COLOR
{
   return blinn_phong_ps(input, diffuse_map, envmap, specular_color, light_colors, 3);
}

float4 blinn_phong_lights_2_ps(Ps_blinn_phong_input input,
                               uniform sampler2D diffuse_map, uniform samplerCUBE envmap,
                               uniform float4 specular_color : register(ps, c[0]),
                               uniform float3 light_colors[3] : register(ps, c[2])) : COLOR
{
   return blinn_phong_ps(input, diffuse_map, envmap, specular_color, light_colors, 2);
}

float4 blinn_phong_lights_1_ps(Ps_blinn_phong_input input,
                               uniform sampler2D diffuse_map, uniform samplerCUBE envmap,
                               uniform float4 specular_color : register(ps, c[0]),
                               uniform float3 light_colors[3] : register(ps, c[2])) : COLOR
{
   return blinn_phong_ps(input, diffuse_map, envmap, specular_color, light_colors, 1);
}

struct Ps_normalmapped_envmap_input
{
   float2 texcoords : TEXCOORD0;
   float3 envmap_coords : TEXCOORD1;

   float3 normal : TEXCOORD2;
   float3 binormal : TEXCOORD3;
   float3 tangent : TEXCOORD4;
   float3 world_position : TEXCOORD5;
   float3 world_view_position : TEXCOORD6;
};

float4 normalmapped_envmap_ps(Ps_normalmapped_envmap_input input,
                              uniform sampler2D normal_map, uniform samplerCUBE envmap,
                              uniform float4 specular_color : register(ps, c[0]),
                              uniform float3 light_color : register(ps, c[2])) : COLOR
{
   float4 normal_map_color = tex2D(normal_map, input.texcoords);

   float3 texel_normal = normal_map_color.rgb - float3(0.5, 0.5, 0.5);

   texel_normal = normalize(texel_normal.x * input.tangent -
                            texel_normal.y * input.binormal +
                            texel_normal.z * input.normal);

   float3 view_dir = normalize(-input.world_position);

   float difference = saturate(dot(view_dir, texel_normal));

   float gloss = lerp(1.0, normal_map_color.a, specular_color.a);

   float3 envmap_color = texCUBE(envmap, input.envmap_coords).rgb;

   float3 color = envmap_color * light_color * gloss * difference;

   return float4(color, normal_map_color.a);
}

float4 debug_vertexlit_ps() : COLOR
{
   return float4(1.0, 1.0, 0.0, 1.0);
}
