# p8x8

(pronounced "p-eight-by-eight")

A tool to convert PICO-8 cartridges into Picotron cartridges (some assembly required)

Drag a p8 cart in, export a p64 cart, make some minor edits to the code, and voila! you can play PICO-8 games on your Picotron desktop!

![screenshot of 3 games being played at once. each was converted using this tool](https://github.com/pancelor/p8x8/assets/11308928/e3f6ae5e-24e3-4a98-a6c2-9aa8086ce299)

The goal here is not to perfectly emulate PICO-8 -- instead, the tool attempts to convert things well enough, and expects the user to make manual tweaks afterwards.

## photosensitivity warning

Carts may flash rapidly, particularly 30fps carts that fade-out using a flip()-loop. Use at your own risk, and test your converted carts before distributing them.

## quickstart

- Inside Picotron, `load p8x8` then ctrl-r to run
- Drag mygame.p8 from your Picotron desktop
	- To get a game from your host OS into Picotron, type `folder` in the terminal and copy the file using your host OS
- Press the export button
	- this will probably generate warnings; a notepad will open showing you the warnings. Manually change your p8 file, reimport and export
	- the warning system is not too smart, so it might report warnings for things you've already fixed, or for things that aren't a problem (like code inside comments)
- Double-click the exported cart to run it
- `load my-exported-cart.p64` and check out `main.lua` for more info. There's an option in there to run the game at fullscreen with a border image!

## compatibility

Not everything will work. This is meant as a starting point, requiring manual changes after converting. Two major areas that are unsupported:
1. memory (e.g. peek/poke/memcpy) is not emulated. The calls will still go through to Picotron's memory, but the effects will be different
2. numbers -- Picotron uses a 64-bit float numeric type, while PICO-8 uses 16.16 fixed-point numbers. Anything relying on the exact format of PICO-8 numbers will probably have problems.

For more notes, see [compat.md](./compat.md)

## how does it work

PICO-8 carts expect various things to be in the global environment, things like `spr`, `mget`, etc. Some of these exist in Picotron's global environment, but many are slightly different, and some are missing altogether. (Picotron does many things differently from PICO-8, so there's no reason to expect everything would stay exactly the same)

The goal of this tool is to let you run carts written in "PICO-8 lua" inside of Picotron. This is achieved by sandboxing the PICO-8 code, and giving it a specially crafted global environment that has all of the standard functions it expects.

## Picotron API

This converter is a great if you want to get a cart working in Picotron quickly. If you plan to continue working on your cart, you should consider ignoring this tool, learning the [Picotron API](https://www.lexaloffle.com/picotron.php?page=faq), and porting your cart directly. (The code in the [polyfills folder](./baked/polyfill) might help you learn some of the differences)

However, if you need access to the Picotron API from inside your PICO-8 code, it's available under the `p64env` table. For example, `fetch` is nil, because the PICO-8 code is sandboxed in a separate environment, but `p64env.fetch` will give you access to Picotron's `fetch` function.

## License

Modified [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/) - p8x8 can be used in non-commerical projects of any kind, *excluding* projects related to NFTs or LLM/genAI promotion or model training.

## HELP WANTED
- open an [issue](https://github.com/pancelor/p8x8/issues) or message me if you tried to use this tool and got confused -- then I can try to smooth off that corner and help others in the future be less confused
- sfx/music
- basic `tline()` support -- see [baked/polyfill/draw.lua](./baked/polyfill/draw.lua#L20). It might be as simple as passing 1 in to the `w` params; I haven't tried it

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
