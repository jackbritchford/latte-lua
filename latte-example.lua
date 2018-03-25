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


local cup = {
	name = "Lua QR Code library",
	source = "github",
	author = "speedata",
	ref = "luaqrcode",
	version = "6f48c2f990d0e2a2d0964c299a3a8b38bdcc4370",
	files = {
		{"qrencode.lua", export_namespace="qrencode"},
		--{"qrcode.lua"}
	}
}
latte.get(cup) -- "qrencode" library now available


-- There you are! Two .lua "modules" and a .lua "script" loaded straight from the internet, cached to disk
-- Ready for next use/etc. Any suggestions/improvements to the concept are welcome.