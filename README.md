# Generative Texting - Persistence Fork

This mod is a fork of jeanmichelthompson's generative texting mod for Cyberpunk 2077, currently supporting game version v2.2.

Mod on nexus:
https://www.nexusmods.com/cyberpunk2077/mods/17922

Original repo:
https://github.com/jeanmichelthompson/generative-texting


Only changes are to save and lod chat logs from this mod to file using RedFileSystem.
Character histories are found in following directories:
r6/storages/GenerativeTexting/[character_name].txt
Each new line is a new message, alternating with first line being V and next line being the character.
When loaded in, each line will be read into character arrays in that order. Only last 20 lines will be read into generative texting system).
