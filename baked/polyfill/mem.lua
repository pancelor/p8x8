--[[pod_format="raw",created="2024-03-20 01:20:21",modified="2024-03-20 01:21:21",revision=2]]
--COMPAT: mem layout is certainly different. what else is going to break here?
--TODO: translation layer for the internal API stuff? e.g. video modes etc
--  the stuff from http://pico8wiki.com/index.php?title=Memory

p8env.memcpy=memcpy
p8env.memset=memset
p8env.peek=peek
p8env.peek2=peek2
p8env.peek4=peek4
p8env.poke=poke
p8env.poke2=poke2
p8env.poke4=poke4
