# Colors, palettes

PICO-8 has a "secret palette", accessed using indices 128..143 of the screen palette (`pal(1)`)

Picotron has an editable 64-color palette, compared to PICO-8's 16-color palette. p8x8 loads the secret colors into indices 48..63 and [hijacks](https://github.com/pancelor/p8x8/blob/main/baked/polyfill/draw.lua) `pal()` to make things "Just Work" (hopefully)

This may be confusing if you're trying to learn Picotron, so feel free to avoid p8x8's hijacked globals and use the Picotron globals directly: by writing `p64env.pal()` you will access the original Picotron `pal()` function, without any of my edits.

There's more info about Picotron's graphics system [online](https://www.lexaloffle.com/picotron.php?page=faq) -- see [picotron_gfx_pipeline.html](https://www.lexaloffle.com/dl/docs/picotron_gfx_pipeline.html) in particular.

## Conversion tips

- to read the i-th entry of pal(0), use `p64env.peek(0x8000+i*0x40)&0xf` instead of `peek(0x5f00+i)`
- to read the i-th entry of pal(1), use `p64env.peek(0x5480+i)` instead of `peek(0x5f10+i)`
