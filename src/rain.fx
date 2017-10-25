
#include "constants_list.hlsl"
#include "vertex_utilities.hlsl"

struct Vs_input
{
   float4 position : POSITION;
   float4 color : COLOR;
};

struct Vs_output
{
   float4 position : POSITION;
   float4 color : COLOR;
};

Vs_output rain_vs(Vs_input input)
{
   float4 position = decompress_position(input.position, position_decompress);
   position = pos_to_world(position, world_matrix);
    
   Vs_output output;
    
   output.position = pos_project(position, projection_matrix);
   output.color = get_material_color(input.color, color_state);

   return output;
}

float4 rain_ps(float4 color : COLOR) : COLOR
{
   return color;
}