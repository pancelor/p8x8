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
	- this will probably generate warnings; a notepad will open showing you the warnings. Manually change your p8 file, reimport and export until there are no warnings when exported
- double-click the exported cart to run it

## compatibility

not everything will work. This is meant as a starting point, requiring manual changes after converting. Two major areas that are unsupported:
1. memory (e.g. peek/poke/memcpy) is not emulated. The calls will still go through to Picotron's memory, but the effects will be different
2. numbers -- Picotron uses a 64-bit float numeric type, while PICO-8 uses 16.16 fixed-point numbers. Anything relying on PICO-8's numeric type will probably have problems
3. custom fonts don't seem to work, I suspect the data format may be different?

## how does it work

PICO-8 carts expect various things to be in the global environment, things like `spr`, `mget`, etc. Some of these exist in Picotron's global environment, but many are slightly different, and some are missing altogether. (Picotron does many things differently from PICO-8, so there's no reason to expect everything would stay exactly the same)

The goal of this tool is to let you run carts written in "pico8 lua" inside of Picotron. This is achieved by sandboxing the pico8 code, and giving it a specially crafted global environment that has all of the normal functions it expects.

## License

Modified [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/) - p8x8 can be used in non-commerical projects of any kind, *excluding* projects related to NFTs or LLM/genAI promotion or model training.

## HELP WANTED
- [ ] open an [issue](https://github.com/pancelor/p8x8/issues) or message me if you tried to use this tool and got confused -- then I can try to smooth off that corner and help others in the future be less confused
- [ ] sfx/music
- [ ] tline emulation -- see [baked/polyfill/draw.lua](./baked/polyfill/draw.lua#L17)

## TODO
- [x] show lint errors easier
- [ ] set better scope expectations. how much emulation accuracy are we shooting for (not much)
- [ ] make CONTRIBUTORS.md
- [ ] put list of chars that need replacing in docs somewhere, for easy searching: `[█▒🐱⬇️░✽●♥☉웃⌂⬅️😐♪🅾️◆…➡️★⧗⬆️ˇ∧❎▤▥あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをんっゃゅょアイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲンッャュョ◜◝]`
- [x] `#include` lint
- [x] `99do` lint
- [ ] better UI
- [x] basic mouse support
- [x] auto filename, but overrideable? backups are saved to `/ram/temp`
