# swbfii_shader_toolkit
A (mostly) toolkit targetting Star Wars Battlefront II (2005) and it's modtools. 
Enables the creation and development of shaders for the game in HLSL.

See the documentation folder for information about it's internal workings, structure and how to bootstrap the tool.

### Shortcomings

#### No Support for Projected Cubemaps
Due to the way Shader Models 2.0+ work a sampler slot can not be treated as having a runtime texture type. 
(Well as far as I know. Please correct me if I'm wrong!) As a result we must choose a texture type to use
and stick with in sampler slots. For the projected texture slot the shaders are setup to use 2D textures only. 
However the perpixel shader does contain logic to prevent a pixel from going black as a result of failed texture lookups.

#### No Water Shader Implementation
(Yet.) There are two main reasons for this the first is that honestly I lack the skill to make a good replacement for 
Pandemic's water shader and the second is that I didn't really feel like just rewriting their's in HLSL once I got to it. 
(It was the last shader I got to.)

As a result both `normalmapadder` and `water` have no implementations present in the toolkit.

#### Likely other things...
I'm not a graphics programmer and I barely understand the math behind 3D rendering. As a result I am almost certain there
are mistakes present in the shaders. (I know of a couple outstanding bugs/problems myself that I haven't fixed yet.) 