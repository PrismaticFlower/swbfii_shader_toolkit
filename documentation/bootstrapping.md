## Bootstrapping
The toolkit should be fairly straightforward to get working, that said it won't work
out of the box. In order to get it working you need to build the compiler and acquire the munged files 
from `core.lvl` the toolkit doesn't use.

### Building the Compiler

You'll need to grab [Visual Studio Community Edition](https://www.visualstudio.com/). Obivously you'll need to make sure
when you install it that you install the C++ components and Windows 8.1 SDK.

After that open `compiler/compiler.sln`, make sure the configuration is set to Release and then build. This will make
`compiler.exe` in `build/bin/`.

### Acquiring the Munged Files

The toolkit also needs these files to be placed into `build/premunged/`.

```
gamefont_large.font
gamefont_medium.font
gamefont_small.font
gamefont_super_tiny.font
gamefont_tiny.font

english.loc
french.loc
german.loc
italian.loc
spanish.loc

uk_english.loc
chunk_0.munged
chunk_1.munged

bump.shader
detail.shader
normalmapadder.shader
pervertexdiffuselighting.shader
scroll.shader
specmap.shader

attenuation_volume.texture
cube_normalizationmap.texture
default_spotlight.texture
hemisphere_normalizationmap.texture
linear_ramp.texture
null_detailmap.texture
specularcubemap.texture
specularspot.texture
white.texture
```

To get them easilly you can use [this](https://github.com/SleepKiller/swbf-unmunge) on your `core.lvl`.