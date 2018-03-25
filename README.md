# latte-lua
Loader for light Lua libraries/dependencies

Still in development, feature suggestions/contributions/pull req's welcome.

Requirements: 
  HTTP Library: lua-requests or lua-nginx-module (openresty)
  Execution Rights: loadstring/load in Lua5.3/5.1
If you've got an environment not immediately supported then write a "driver" for what's required.

Optional:
  LuaFFI: will be making more use of FFI bindings (especially for file libraries)

Example from latte-example.lua
```lua
local latte = require("latte")

local cup = {
	name = "prettyprint test",
	source = "http", -- can currently dl from any http url as long as your Lua libraries support it.
	author = "jackbritchford",
	ref = "prettyprint-test",
	version = "1", -- can really be anything as long as it's unique!
	files = {
		{
			filename = "prettyprint.lua",
			url = "https://cdn.rawgit.com/jackbritchford/5f0d5f6dbf694b44ef0cd7af952070c9/raw/f4ac0dc20ee82fcf7e0cb431d54dca1c776fa627/cb-tablepretty.lua",
			autoload = true,
		}
	}
}
latte.get(cup) -- "table.tostring" and "printtable" now available


local cup = {
	name = "rxi's pure json.lua library",
	source = "github",
	author = "rxi",
	ref = "json.lua",
	version = "eb6e343c53d25b24bfe0e05ecbb1d29297dfcb6d", -- DO NOT USE "master" HERE! currently doesn't check revision and, even when it does will be for development purposes only! do not execute code that could be changed not just due to breaking but the security implications.
	files = {
		{"json.lua", export_namespace="json"} -- export_namespace used so it uses "require". _G[cup.export_namespace] = require("thatcode")
	}
}
latte.get(cup) -- "json" library now available
```
