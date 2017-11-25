## Munge Process

The toolkit is setup to produce a new `core.lvl` for the game. However it is not setup to munge new files for everything
in `core.lvl` only the shaders, all other files are pulled from  `build/premunged`.

At a high level the build process is simply this.

```
for each shader

if not needs compiling shader then continue

compile shader

end

make core.lvl
```

PowerShell is used to implement the loop. It enumerates all JSON shader definitions in `definitions/`, determines if 
it needs compiling and, if it does, calls the compiler.

To let it determine if a shader needs compiling the build script stores checksums of the shader source files and 
key header files. (It places them in `build/checksums/`.) If a shader's `.fx` or `.json` file is changed it is
recompiled. If a key header file is changed then all shaders are recompiled. In this way the build script achieves a sort
of minimal rebuild feature.

Once the compiler is ran it reads the shader's definition and compiles are the required variations of each shader pass. 
If two passes require the same variation then they'll share it and the variation will only be compiled once. This saves
compile time and space in the resulting `.shader` file. (The modtools compiler did not do this, this even with debug 
information the shaders produced by the custom compiler are often smaller in size than their stock equivalent.)

After all variations have been compiled and the metadata for each state and their passes processed the shader is saved to
the output file the PowerShell script specified.