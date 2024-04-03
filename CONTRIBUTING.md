Hi, thanks for being interested in improving this tool!

TODO: I should write more guidelines here but haven't made the time for it yet

## Bug reports

Submitting a bug report, even a hastily-written one, is very helpful! I can't fix issues I don't know about.

Parts of a great bug report:
- what did you do
- what did you expect
- what happened instead
- include your p8 source file if you can

## Pull Requests

Thanks for submitting improvements!! Two things to note:

### legal stuff

When contributing to this project, you must agree that you have authored 100% of the content, that you have the necessary rights to the content and that the content you contribute may be provided under the project's [license](./LICENSE.md).

### emulation accuracy

p8x8 can be seen as a PICO-8 emulator, in a sense, and it is tempting to try to increase the "emulation accuracy". However, in many cases this would make the code very complicated, harder to maintain, and harder to understand. I am not interested in turning p8x8 into a magic emulator that Just Works, and I don't want to give off that impression to users. It is instead intended to be a "80%" tool -- doing a bunch of "easy" work, and leaving the final details to the user.

If you have a pull request that seems obviously good to you, adding features and increasing "emulation accuracy", please submit it! I might accept the changes, or I might reject some or all of the changes. But even if no changes are merged, the pull request still exists for others to benefit from. I'll be grateful that you suggested changes, and I hope you'll understand if I don't accept them -- we probably just have different visions for what p8x8 should be.

### how is the code organized?

Here's an overview of p8x8's parts:
- `./main.lua`, `./src/gui.lua` - the main interface for p8x8
- `./src/import.lua`, `./src/export.lua` - reading p8 files and writing p64 files
- `./warn.lua` - the system that reads imported code and produces compatibility warnings
- `./baked` - this folder is the template for exported p64 carts
	- `./baked/main.lua` - the main file for the exported cart. it sets up the `p8env` sandbox and handles fullscreen drawing and keyboard focus
	- `./baked/polyfill/` - every file in this folder is automatically loaded in exported carts. these files add functions to the `p8env` sandbox, which is the global environment for exported carts
- `./src/tool.lua`, `./lib/` - some generally helpful code libraries


---


_thanks to https://contributing.md/example/ for providing a base for this document_
