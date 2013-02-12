push
====

Lua library implementing knockout.js-like observable properties.

So... what exactly?
====
When dealing with keeping multiple data layers in sync as common in GUIs (View-ViewModel or View-Model relations), 
it is easy to introduce bugs and a clumsy syntax. 
The actual intent of the code is shadowed by syncing for all form fields/model bindings. 
This is especially true for HTML applications, where databinding is additionally complicated by DOM access. This is where [knockout.js](http://knockoutjs.com/) kicks in. This javascript library only aims to implement the observable part to provide a modular core for other usages. It is actually written in [MoonScript](http://moonscript.org/) and as such the lua files are a nice autogenerated byproduct.

Zzz...
====
By now your eyes pretty much fast forwarded to the code samples... Anyway, assume `local push = require "push"` has happened before each snippet.
(I'm tired... look into push_test for now to get a feel)
