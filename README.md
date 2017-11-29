# swbfii_shader_toolkit
A (mostly complete) toolkit targetting Star Wars Battlefront II (2005) and it's modtools. Enables the creation and development of shaders for the game in HLSL.

See the documentation folder for information about it's internal workings, structure and how to bootstrap the tool.

### Getting Started
If you have a ready-to-go version of the toolkit you can skip this step. See [here](https://github.com/SleepKiller/swbfii_shader_toolkit/blob/master/documentation/bootstrapping.md) for instructions on how to get the toolkit working from the repo.

Once you've done that you can run [build.ps1](https://github.com/SleepKiller/swbfii_shader_toolkit/blob/master/build.ps1) or [build.bat](https://github.com/SleepKiller/swbfii_shader_toolkit/blob/master/build.bat) to produce a core.lvl using the shaders contained in the toolkit. It'll be placed in this directory.

After that you'll probably want to edit the shaders which you can find in the [src](https://github.com/SleepKiller/swbfii_shader_toolkit/tree/master/src) folder. And if you want to get really fancy you can even edit the shader definitions to mess around with adding multiple shader passes and such. You can find them in the [definitions](https://github.com/SleepKiller/swbfii_shader_toolkit/tree/master/definitions) folder and you can find documentation for them [here](https://github.com/SleepKiller/swbfii_shader_toolkit/blob/master/documentation/definitions.md).

Be sure to quickly look over the known [issues](https://github.com/SleepKiller/swbfii_shader_toolkit/issues) as well, so you're aware of the toolkit's shortcomings and workarounds for them. 

### Spotted a Problem?
I'm not a graphics programmer and I barely understand the math behind 3D rendering. As a result I am almost certain there
are mistakes present in the shaders. If you happen to be lucky and spot one feel free to tell me about [it](https://github.com/SleepKiller/swbfii_shader_toolkit/issues/new).
