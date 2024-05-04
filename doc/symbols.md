# Symbols

p8x8: some assembly required!

## Explanation

When you paste PICO-8's extended characters into Picotron,
they break the parser. They also can't be used as variable names: `btnp(❎)` will
throw a syntax error. They also get all unicode-y, each one turning into 3 to 6
separate characters, so they can't be drawn or used to store binary data.

It might be possible to write a tool to automatically replace the symbols,
but the tool would need to guess the context+purpose of the symbols.
If it found a down-arrow character in your code, it could mean many things:

1. the number 3 (`if btnp(⬇️)`)
2. the image of an arrow (`print("use ⬇️/⬆️ to move!")`)
3. the binary encoding of 131 (`poke(font_address,ord("...あつてと⬇️エ...",1234))`
4. irrelevant characters in a comment (`--⬆️⬆️⬇️⬇️`)

It seems possible to make heuristics to decide which one to choose,
but that sounds like a huge rabbithole. This choice can be made easily
by users of p8x8, who have the context to know what their code means.

## Helper functions

Automatic conversion is out-of-scope for this tool,
but I've added some things to make things easier to convert.
If you're using a symbol as:

1. a number, you can replace `if btnp(⬇️)` with `if btnp(p8x8_symbol"⬇️")`
2. an image, you can replace `print("⬇️ down")` with `print(p8x8_symbol_visual"⬇️".." down")` or `print("\131")` (the number needed, e.g. 131, is printed by the warning system)
3. a binary encoding, you can replace `ord("あつてと⬇️エ")` with `ord(p8x8_datastring"あつてと⬇️エ")`
4. a comment, you can leave it alone, or delete it

These new functions (`p8x8_symbol()`, `p8x8_symbol_visual()`, and `p8x8_datastring()`)
are new global functions that are added to your cart's global environment

Additionally, `p8x8_datastring()` will print to the host console (printh) the first time it is called, automatically converting the string into a Picotron-safe equivalent string. If wanted, you can take this string and replace the original string in your code.

## Re-encoding custom fonts

Custom fonts are supported by p8x8 (and Picotron) -- poke() your font data to 0x5600, just like how PICO-8 handled fonts.

However, Picotron can't handle PICO-8's special characters, so you'll need to re-encode your font if it looks like `?"⁶!5600⁸⁸\n\0\0\0\0\0\0\0\0...ᶜᵉᶜᶜᶜ゛\0\0..."`, or the equivalent `poke(0x5600,ord("...",len))`.

You can either use `p8x8_datastring()` (described above), or you can re-encode your font:

1. Open PICO-8, and open the .p8 file. Find the part of the code that sets up the font -- search for "0x5600", "5600", or "22016".
1. Immediately after the code that pokes the font data into memory, add this code:
```lua
local data='poke(unpack(split\"0x5600'
for addr=0x5600,0x5dff do  data..=","..@addr  end
printh(data..'"))',"@clip")
stop("copied")
```
1. Run the cart. It should stop early and print "copied".
1. Delete the existing font setup code and replace it with the generated code on your clipboard. It should look like this: `poke(unpack(split" <lots of numbers here> "))`
1. Save your .p8 cart. The font setup code now sets up the same font, but only uses ascii characters, so it will now work with p8x8.
