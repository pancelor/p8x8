# p8x8

(pronounced "p-eight-by-eight")

A tool to convert [PICO-8](https://www.lexaloffle.com/pico-8.php) cartridges into [Picotron](https://www.lexaloffle.com/picotron.php) cartridges (some assembly required)

Created by [pancelor](https://pancelor.com/website2022-12)

Drag a p8 cart in, export a p64 cart, make some minor edits to the code, and voila! you can play PICO-8 games on your Picotron desktop!

![screenshot of 3 games being played at once. each was converted using this tool](https://github.com/pancelor/p8x8/assets/11308928/e3f6ae5e-24e3-4a98-a6c2-9aa8086ce299)

The goal here is not to perfectly emulate PICO-8 -- instead, the tool attempts to convert things well enough, and expects the user to make manual tweaks afterwards.

## Table of Contents
<!-- https://github.com/derlin/bitdowntoc -->
- [USAGE GUIDE](#usage-guide)
  - [Quickstart](#quickstart)
  - [Compatibility](#compatibility)
  - [Symbols](#symbols)
  - [Photosensitivity warning](#photosensitivity-warning)
  - [License](#license)
- [Details, more info](#details-more-info)
  - [How p8x8 works](#how-p8x8-works)
  - [Picotron API](#picotron-api)
  - [Updating your cart when p8x8 updates](#updating-your-cart-when-p8x8-updates)
  - [Help wanted](#help-wanted)
  - [TODO](#todo)



# USAGE GUIDE

## Quickstart

- Install p8x8 into your Picotron
	- `load #p8x8`
	- `save /desktop/p8x8`
- Put your PICO-8 cartridge into Picotron's filesystem
	- Type `folder` in the Picotron terminal to open the current folder using your host OS
- Inside Picotron, `load p8x8` and ctrl-r to run
- Drag mygame.p8 onto the p8x8 window
- Press the export button
	- A notepad will likely open up, showing the warnings that p8x8 generated. Manually change your p8 file, reimport and export. See [doc/compat.md](./doc/compat.md) for more info.
	- 
- Double-click the exported cart to run it!
	- `load mygame.p64` and check out `main.lua` for more info/options

Fullscreen mode: edit `main.lua` in your generated p64 cart -- there's an option to run the game fullscreen with a border image! But make sure that all of your cart's drawing functions are called from `_draw` (or some function called by `_draw`, recursively). If your cart runs any drawing functions during `_init` or `_update`, the fullscreen border will [look wrong](https://github.com/pancelor/p8x8/issues/9).

## Compatibility

Not everything will work. This tool is designed to give you a starting point, and requires manual changes after converting. Three major areas are unsupported:
1. **memory** (e.g. peek/poke/memcpy) is not emulated. The calls will still go through to Picotron's memory, but the effects will be different
2. **numbers** -- Picotron uses a 64-bit float numeric type, while PICO-8 uses 16.16 fixed-point numbers. Anything relying on the exact format of PICO-8 numbers (e.g. bitwise operators) will probably have problems.
3. **sfx/music** - this is not supported [yet](https://github.com/pancelor/p8x8/issues/5).

For more notes, see [compat.md](./doc/compat.md)

## Symbols

You will likely need to make changes related to PICO-8's special symbols. For instance, you will need to change `btnp(⬇️)` to `btnp(p8x8_symbol"⬇️")` or `btnp(3)`. For much more info, including custom fonts, see [doc/symbols.md](./doc/symbols.md)

## Photosensitivity warning

~~Carts that change the palette may rapidly flash the colors on the Picotron desktop.~~ This seems fixed as of Picotron 0.1.0e! But it seems worth noting still. Use at your own risk, and test your converted carts before distributing them.

## License

Modified [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/) - p8x8 can be used in non-commerical projects of any kind, *excluding* projects related to NFTs/cryptocoins, or projects related to LLM/genAI promotion or model training.

Just say something like "converted using p8x8: https://lexaloffle.com/bbs/?pid=p8x8" in your description or credits, don't sell your game, and you're good to go. See the [license](https://creativecommons.org/licenses/by-nc/4.0/) for full details.



# Details, more info

## How p8x8 works

PICO-8 carts expect various things to be in the global environment, things like `spr`, `mget`, etc. Some of these exist in Picotron's global environment, but many are slightly different, and some are missing altogether. (Picotron does many things differently from PICO-8, so there's no reason to expect everything would stay exactly the same)

The goal of this tool is to let you run carts written in "PICO-8 lua" inside of Picotron. This is achieved by sandboxing the PICO-8 code, and giving it a specially crafted global environment that has all of the standard functions it expects.

## Picotron API

This converter is a great if you want to get a cart working in Picotron quickly. If you plan to continue working on your cart, you should consider ignoring this tool, learning the [Picotron API](https://www.lexaloffle.com/picotron.php?page=faq), and porting your cart directly. (The code in the [polyfills folder](./baked/polyfill) might help you learn some of the differences)

However, if you need access to the Picotron API from inside your PICO-8 code, it's available under the `p64env` table. For example, `fetch` is nil inside your PICO-8 code, because that code is run in a sandboxed environment. Use `p64env.fetch` to access Picotron's `fetch` function.

I encourage you to read the [main.lua file](./baked/main.lua) of your generated cart -- it's the main file that Picotron runs, and you can see how it sets up the `p8env` sandbox environment. Also, there are some options in there that you can change -- fullscreen (with image border!) and `pause_when_unfocused`.

## Updating your cart when p8x8 updates

[TODO](https://github.com/pancelor/p8x8/issues/10)

## Help wanted
- open an [issue](https://github.com/pancelor/p8x8/issues) or leave a comment on the [BBS thread](https://www.lexaloffle.com/bbs/?pid=p8x8#p) if you tried to use this tool and got confused -- then I can try to smooth off that corner and help others in the future be less confused
- add support for importing [sfx/music](https://github.com/pancelor/p8x8/issues/5)
- add basic support for [tline()](https://github.com/pancelor/p8x8/issues/8)
- more info in [CONTRIBUTING.md](./CONTRIBUTING.md)

## TODO
- [x] show lint errors easier
- [x] set better scope expectations. how much "emulation accuracy" are we aiming for (not much)
- [x] make CONTRIBUTING.md
- [ ] put list of chars that need replacing in docs somewhere, for easy searching: `[¹²³⁴⁵⁶⁷⁸ᵇᶜᵉᶠ▮■□⁙⁘‖◀▶「」¥•、。゛゜█▒🐱⬇️░✽●♥☉웃⌂⬅️😐♪🅾️◆…➡️★⧗⬆️ˇ∧❎▤▥あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをんっゃゅょアイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲンッャュョ◜◝]`
- [x] `#include` lint
- [x] `99do` lint
- [ ] better UI
- [x] basic mouse support
- [x] auto filename, but overrideable? backups are saved to `/ram/temp`
