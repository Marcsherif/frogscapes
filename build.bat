@echo off
sokol-shdc -i shaders\shader.glsl -o code\shader.odin -l glsl430:hlsl5 -f sokol_odin
odin run code -out:build/frogscapes.exe
