# swbfii_shader_toolkit
A (mostly complete) toolkit targetting Star Wars Battlefront II (2005) and it's modtools. Enables the creation and development of shaders for the game in HLSL.

See the documentation folder for information about it's internal workings, structure and how to bootstrap the tool.

### Getting Started
If you have a ready-to-go version of the toolkit you can skip this step. See [here](https://github.com/SleepKiller/swbfii_shader_toolkit/blob/master/documentation/bootstrapping.md) for instructions on how to get the toolkit working from the repo.

Once you've done that you can run [build.ps1](https://github.com/SleepKiller/swbfii_shader_toolkit/blob/master/build.ps1) or [build.bat](https://github.com/SleepKiller/swbfii_shader_toolkit/blob/master/build.bat) to produce a core.lvl using the shaders contained in the toolkit. It'll be placed in this directory.

After that you'll probably want to edit the shaders which you can find in the [src](https://github.com/SleepKiller/swbfii_shader_toolkit/tree/master/src) folder. And if you want to get really fancy you can even edit the shader definitions to mess around with adding multiple shader passes and such. You can find them in the [definitions](https://github.com/SleepKiller/swbfii_shader_toolkit/tree/master/definitions) folder and you can find documentation for them [here](https://github.com/SleepKiller/swbfii_shader_toolkit/blob/master/documentation/definitions.md).

Be sure to quickly look over the known [issues](https://github.com/SleepKiller/swbfii_shader_toolkit/issues) as well, so you're aware of the toolkit's shortcomings and workarounds for them. 

### Key Differences
I've tried to keep closely to the game's original shaders and their look. However there are a couple places were I was unable to do this. It is likely worth while to be aware of those places.

#### Normal Mapping & Per Pixel Shader
Because of problems I encounterd (which I believe related to Shader Model 1) while porting the shaders to HLSL I ended up having to rewrite them. As a result they will be slightly visually different, however I don't think it'll be in anyway that breaks the game's or any mod's art style. 

#### Specular Shader
Again because of problems I had to rewrite the specular lighting shader. This is likely the biggest visual difference between these shaders and the game's stock shaders. The game would normally sample a specular spot texture to do it's specular highlighting. Unfortunately once again that same texture slot could also be an environment map (cube texture) instead, which because of the way Shader Model 2 works means we can't use it the game was using it. 

The specular shaders instead all use the [Blinn-Phong reflection model](https://en.wikipedia.org/wiki/Blinn%E2%80%93Phong_shading_model) with fixed exponents. (Because for the life of me I couldn't find where/if the actual exponent specified in a model's material was being passed in.) This seems to give good results but it is visibly different from the game's stock shader.

### Spotted a Problem?
I'm not a graphics programmer and I barely understand the math behind 3D rendering. As a result I am almost certain there
are mistakes present in the shaders. If you happen to be lucky and spot one feel free to tell me about [it](https://github.com/SleepKiller/swbfii_shader_toolkit/issues/new).
