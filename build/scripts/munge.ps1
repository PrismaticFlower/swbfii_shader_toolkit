pc_shadermunge -inputfile "build/xml/*.xml" -outputdir "build/munged/"
levelpack -inputfile "build/core.req" -sourcedir "build/premunged/" "build/munged/"