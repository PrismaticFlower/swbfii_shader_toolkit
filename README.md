# metadata branch
This branch contains a special version of the compiler that embeds metadata into each shader it compiles.
This metadata can be used to identify and learn things about the shader at runtime. It is stored as serialized json in 
the [MessagePack](https://msgpack.org/index.html) format and is stored as the first comment in the shader's assembly.

| Key  | Type | Value |
| ------------- | ------------- | ------------- |
| name  | `string` | The filename of the fx file the shader was compiled from. Without the `.fx` component.  |
| entry_point  | `string` | The name of the entry point used for the shader. |
| target  | `string` | The target profile used for the shader. |
| vs_flags  | `uint` | (optional) The Vertex Shader flags used for this variation of the shader. |

In addition a shader may define objects named "metadata" in it's json description. Any members of this objects
will also be added to the embedded metadata. These objects can occur at the shader's root level, state level or
pass level. With each level overriding keys from earlier levels. In all cases the keys listed in the above table
always override any custom metadata set.