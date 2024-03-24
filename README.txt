--[[pod_format="raw",created="2024-03-19 21:51:33",modified="2024-03-21 08:50:53",revision=17]]
# p8x8

p8x8, by pancelor. (pronounced "p-eight-by-eight")

A tool to convert PICO-8 cartridges into Picotron cartridges

Drag a p8 cart in, export a p64 cart, make some minor edits to the code, and voila! you can play PICO-8 games on your Picotron desktop!

![screenshot of 3 games being played at once. each was converted using this tool](https://github.com/pancelor/p8x8/assets/11308928/c2a1c36c-ac4d-43b1-8e92-b1e7b5fbaade)

The goal here is NOT perfect emulation of pico8 -- instead, the tool attempts to convert things well enough, and expects the user to make manual tweaks afterwards.

## quickstart

- inside picotron, `load p8x8` then ctrl-r to run
- drag mygame.p8 from your picotron desktop
	- to get a game from your host OS into picotron, type `folder` in the terminal and copy the file using your host OS
- press the export button
	- this will probably generate warnings; `load mygame.p64` to view the warnings in detail
- double-click the exported cart to run it

## how does it work

PICO-8 carts expect various things to be in the global environment, things like `spr`, `mget`, etc. Some of these exist in Picotron's global environment, but many are slightly different, and some are missing altogether. (Picotron does many things differently from PICO-8, so there's no reason to expect everything would stay exactly the same)

The goal of this tool is to let you run carts written in "pico8 lua" inside of Picotron. This is achieved by sandboxing the pico8 code, and giving it a specially crafted global environment that has all of the normal functions it expects.

## License

Modified [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/) - p8x8 can be used in non-commerical projects of any kind, *excluding* projects related to NFTs or LLM/genAI promotion or model training.

## TODO
- [ ] sfx/music - help welcome
- [ ] CONTRIBUTORS.md
- [ ] set better scope expectations. how much emulation accuracy are we shooting for (not much)
- [x] `#include` lint
- [ ] `99do` lint
- [ ] better UI
- [ ] auto filename, but overrideable? (save backup?)
