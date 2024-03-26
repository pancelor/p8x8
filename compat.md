This project does not aim for perfect emulation of pico8. It aims to make it easier to quickly get a PICO-8 cart working in Picotron, but some assembly is required.

When p8x8 builds a .p64 file for you, the main.lua inside the p64 cart has a function `compat` at the top. This is used by the p8x8 translation layer to signal when the code realizes it is running incompatible behavior. Currently your p64 will print out a warning to the host console whenever this happens, but you could change it to do something else here, like `assert` or `notify`.

For more in-depth compatibility notes, search for "COMPAT" inside the baked/polyfill folder -- these files set up the environment that the PICO-8 code sees as its global environment

Here are the current areas where p8x8 does not emulate pico8 perfectly:

## wontfix

These areas will likely remain incompatible, and will require changes to get a cart working in Picotron:

- you can only draw inside the `_draw` function
	- carts that use `goto` loops are not supported
- memory (e.g. peek/poke/memcpy) is not emulated. The calls will still go through to Picotron's memory, but the effects will be different
- numbers -- Picotron uses a 64-bit float numeric type, while PICO-8 uses 16.16 fixed-point numbers. Anything relying on the exact format of PICO-8 numbers will probably have problems.
- p8scii special commands are not supported, beyond whatever zep has done to make the APIs similar (colors seem to work)
- `x = 13//2` -- two slashes now means "floor division", not the start of a comment. In PICO-8, `x==13`, but in Picotron, `x==6`.

## todo

These areas will hopefully become compatible in the future. For now, they require changes to get a cart working in Picotron:

- [custom fonts](https://github.com/pancelor/p8x8/issues/4) don't seem to work, I suspect the data format may be different?
- top-level local variables are not visible across different tabs. this can be changed inside main.lua of p8x8's output, but it will lead to worse error messages. I recommend making top-level locals global instead.
