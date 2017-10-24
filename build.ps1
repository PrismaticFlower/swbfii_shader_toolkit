# Path to the directory with fxc in it, edit this if you have it somewhere else.
$env:path += ";${env:ProgramFiles(x86)}\Windows Kits\8.1\bin\x86"

# Path to the directory with pc_ShaderMunge and levelpack in it.
$env:Path += ";../ToolsFL/bin"


.\build\scripts\compile.ps1
.\build\scripts\munge.ps1
