# Compatibility

This project does not aim for perfect emulation of PICO-8. It aims to make it easier to quickly get a PICO-8 cart working in Picotron, but some assembly is required.

p8x8 will not edit your code for you, but it will suggest changes that you should make
to make your cart run successfully.

p8x8 will generate warnings at import time if it notices code that might not convert properly. The warning system might report warnings for things you've already fixed, or for things that aren't a problem (like code inside comments), but each warning is a place that may break your game.

For a list of the problems it looks for, see `function lint_all` in [warn.lua](https://github.com/pancelor/p8x8/blob/main/src/warn.lua#L74-L89)

## Compatibility differences

When p8x8 builds a .p64 file for you, the cart's `main.lua` file has a function `compat` at the top. This is called by the p8x8 sandbox/translation-layer (`p8env`) whenever p8x8 realizes it is running incompatible behavior. By default, `compat` will print these warnings to the host console, but you could change it to `assert` or `notify` in addition.

For more in-depth compatibility notes, search for "COMPAT" inside the [baked/polyfill](https://github.com/pancelor/p8x8/tree/main/baked/polyfill) folder. These files set up the "p8env" environment -- this is the sandbox that PICO-8 code sees as its global environment.

Here's a list of the high-level areas where p8x8 does not emulate PICO-8 perfectly:

### Wontfix

These areas will likely remain incompatible, and will require changes to get a cart working in Picotron:

- special symbols (like pressing shift-X in PICO-8 to create ❎) are not supported
	- p8x8 generates warnings every time it notices these special symbols, and the warnings suggest an easy upgrade path for the btn/fillp use case: `WARN(3): 1.lua#102 (p8:234) special chars (shift-X / chr(151)) are not supported. use this, for example: fillp(p8x8_symbol"❎") instead of fillp(❎)`
	- p8x8 doesn't know what your intent for the symbol is (is it a printed visual? is it a btn/fillp-like argument? is it part of encoded binary data?) and it prefers not to guess, leaving the decision to the user who knows their code much better than p8x8 does anyway.
	- for more info, including **helper functions for easy converting**, see [symbols.md](./symbols.md)
- memory (e.g. peek/poke/memcpy) is not emulated. The calls will still go through to Picotron's memory, but the effects will be different
- numbers -- Picotron uses 64-bit floats as numbers, but PICO-8 uses 16.16 fixed-point numbers. Anything relying on the exact format of PICO-8 numbers will probably have problems.
	- binary operations like `&` will error if the number has decimals -- Picotron will say "number has no integer representation"
- p8scii special commands are not supported, beyond whatever zep has done to make the APIs similar (color codes seem to work)
- `x = 13//2` -- two slashes now means "floor division", not the start of a comment. In PICO-8, this would set x to 13, but in Picotron, x gets set to 6.
- you can only draw inside the `_draw` function ([explanation](https://github.com/pancelor/p8x8/issues/9#issuecomment-2029468833))
	- carts that use `goto` loops are not supported
- `pal(2)` is unsupported - it's very complicated. But these effects can be done using Picotron's API (instead of p8x8's API); for more info see [colors.md](./colors.md)

### Todo

These areas will hopefully become compatible in the future. For now, they require changes to get a cart working in Picotron:

- [top-level local variables](https://github.com/pancelor/p8x8/issues/2) are not visible across different tabs. this can be changed inside main.lua of p8x8's output, but it will lead to worse error messages. I recommend making top-level locals global instead.
- [pausing the game](https://github.com/pancelor/p8x8/issues/7) is a bit awkward -- menuitems show up in the window's menu, but PICO-8's ingame pause menu is not supported. When the window loses focus it will pause automatically (configurable -- see `pause_when_unfocused` inside main.lua in your exported cart)
