# Path to levelpack
$env:Path += ";../ToolsFL/bin/"

# Make sure we have a place to put checksum and munged files.
mkdir -Force build/checksums/ > $null
mkdir -Force build/munged/ > $null

function file_changed($file)
{
    $file_name = $file.Name;

    $checksum_path = "build/checksums/$file_name.checksum"

    $result = $true
    $hash = (Get-FileHash -Path $file -Algorithm MD5).hash

    if (Test-Path -Path $checksum_path) 
    {
        $result = ((Get-Content -Raw $checksum_path) -ne $hash)
    }

    $hash | Out-File -NoNewline -Encoding utf8 $checksum_path

    $result
}

function include_file_changed()
{
    $constants_list = file_changed (Get-Item "src/constants_list.hlsl")
    $ext_constants_list = file_changed (Get-Item "src/ext_constants_list.hlsl")
    $lighting_utilities = file_changed (Get-Item "src/lighting_utilities.hlsl")
    $transform_utilities = file_changed (Get-Item "src/transform_utilities.hlsl")
    $vertex_utilities = file_changed (Get-Item "src/vertex_utilities.hlsl")

    $constants_list -or $ext_constants_list -or $lighting_utilities -or $transform_utilities -or $vertex_utilities
}

$munge_all = include_file_changed

foreach ($file in Get-ChildItem -File -Path definitions\* -Include *.json)
{
   $srcname = $file.Name -replace ".json", ".fx"
   $outname = $file.Name -replace ".json", ".shader"

   $definition_changed = file_changed $file
   $source_changed = file_changed (Get-Item "src\$srcname")
   $munged_exists = Test-Path -Path "build\munged\$outname"
   
   if ((-not $munge_all) -and (-not $definition_changed) -and (-not $source_changed) -and $munged_exists) { continue }

   Write-Host Munging $file.Name

   ./build/bin/compiler $file.FullName "src\$srcname" "build\munged\$outname"
}

levelpack -inputfile "build/core.req" -sourcedir "build/munged/" "build/premunged/"