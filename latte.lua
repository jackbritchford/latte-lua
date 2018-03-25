--[[
    __          __  __             __               
   / /   ____ _/ /_/ /____        / /   __  ______ _
  / /   / __ `/ __/ __/ _ \______/ /   / / / / __ `/
 / /___/ /_/ / /_/ /_/  __/_____/ /___/ /_/ / /_/ / 
/_____/\__,_/\__/\__/\___/     /_____/\__,_/\__,_/  
https://github.com/jackbritchford/latte-lua

A loader/dependency manager for projects in Lua for the 21st century.
Written by Jack Britchford (jackbritchford.com)



There is a lot to suggest, improve and be changed. Feel free to contact me and suggest ideas or submit pull requests through GitHub.

Do not use in production! Still in development, so contribute! You have been warned.

Todo: (move this to a different file)
	- figure out HTTP across Lua enviornments (openresty is the only environment I can think of with HTTP out of the box)
	- Files reading/writing. FFI bindings?
	- Make modular at least in terms of sources/"Cups"
	- If the GitHub ToS permits, figure out how to request directly from GitHub rather than these CDN's
	- Hammer out some standards/what "Cups" precisely are/etc
	- Also hammer out the standard of what a "package name" or whatever will look like
	- Further to the two above, taxonomy!
	- Dependencies, "Cup"'s should be able to have module requirements/other "Cup" requirements
	- Not quite sure how to set that up/repos? or?
	- Also, security, SHA256/CRC32 validation of downloads?
	- Restrict use of "master" branch on Git/warn against it as apposed to pinning a commit/version. Both security issues + compatbility issues
	- Updating/cache purging/other optimisations/code cleanup
	- Localise a number of global functions which shouldn't be global
	- Configuration, I guess at the minute just change _dir before you run any functions but has not been tested!


there's a number of todo: and other comments throughout this file. if you're interested search for [SECURITY] [CRITICAL]


oh, and a caramel latte.
]]


------ some fixes because urgh....
if not unpack then unpack = table.unpack end -- why???



local latte = latte or {}
--latte.repos = {}
latte.cups 	= latte.cups or {} -- "packages" of one or more Lua files
--[[
should be

latte.cups["github/jackbritchford/someluadepend"] = {
	["VERSION NUMBERS"] = cup,
	["VERSION NO OR GIT HASH"] = cup,
}


but currently
latte.cups["github/jackbritchford/someluadepend"] = latest_cup

]]


latte._dir 	= "latte/" -- eugujughrugh
latte._files=latte._files or {} -- file "cache" of sorts... (can set to latte._files = latte._files or {} as well as latte = latte or {} if you have a reloadable Lua environment)



local function ctag(cup) return cup.source .. "/" .. cup.author .. "/" .. cup.ref end -- todo: REWRITE/ETIEHJUH - make OOP or something
--local function fexists(l) local f = io.open(l) if f ~= nil then f:close() return true else return false end end

-- creds to fexists and 
local function fexists(file)
   local ok, err, code = os.rename(file, file)
   if not ok then
      if code == 13 then
         return true
      end
   end
   return ok, err
end

local function isdir(path)
   return fexists(path .. "/")
end
local function p(str)
	print("[Latte] " .. str)
end
--[[
latte._sources = {
	["github"] = {

	},
	["http"] = {

	}
}
]]

if odf then dofile = odf; odf = nil end
odf = dofile
function dofile(path) -- 'dofile' isn't relative. todo: clean all this up...
    local PATH = string.match(debug.getinfo(2,"S").source, "^@(.+/)[%a%-%d_]+%.lua$")

    if PATH then
        print(PATH .. path)
        if not fexists(path) and fexists(PATH .. path) then
        	return odf(PATH .. path)
        else
        	return odf(path)
        end
	else
        return odf(path)
    end
end


local httpDriver, execDriver

-- todo: find a better way of doing this. eurgh...
latte._drivers = {
	http = {
		["lua-nginx"] = { -- todo: currently untested
			name = "lua-nginx-module/openresty",
			detect = function()
				return ngx ~= nil -- p sure ngx.location.capture is in all openresty/"lua-nginx-module"
			end,
			get = function(url, callback)
				local res = ngx.location.capture(url)

				callback(res.status, res.body)
			end,
			-- post = ...
		},
		["lua-requests"] = {
			name = "Lua Requests module (lua-requests)",
			detect = function()
				-- todo: cleaner way of doing this. also stop looking once it's found one
				local status, res = pcall(require, "requests");
				requests = status and res or nil

				return status
			end,
			get = function(url, callback)
				local response = requests.get({url = url})

				callback(response.status_code, response.text)
			end
		}
	},
	exec = {
		["lua_loadstring"] = { -- todo: currently untested
			name = "Lua loadstring",
			detect = function() return loadstring ~= nil end,
			exec = function(code) return loadstring(code) end,
		},
		["lua_load"] = {
			name = "Lua load",
			detect = function() return load ~= nil end,
			exec = function(code) return load(code) end,
		},
	}
}


for driver, tbl in pairs(latte._drivers.http) do
	if tbl.detect() then
		httpDriver = driver
		p("Using " .. driver .. " for HTTP.")
	end
end

for driver, tbl in pairs(latte._drivers.exec) do
	if tbl.detect() then
		execDriver = driver
		p("Using " .. driver .. " for Lua execution.")
	end
end

if not httpDriver then
	p("WARNING! No HTTP driver was found! Please refer to the documentation for more information.\nThis script will stop.")
	return
end

if not execDriver then
	p("WARNING! No HTTP driver was found! Please refer to the documentation for more information.\nThis script will stop.")
	return
end

local _pendingFiles = {} -- todo: there's a better way than this, come on...
--[[
function latte.tick()
	for ct, pendingFiles in pairs(_pendingFiles) do
		if #pendingFiles == 0 then
			_pendingFiles[ct] = nil

			latte.initcup(latte.cups[ct])
		end
	end
end]]

function latte.tick() end -- nope nope nope, forget that

latte.http = {}

function latte.http.get(url, callback)
	--if httpDriver == nil then p("No driver for HTTP! Failing.") return end -- unnecessary check

	latte._drivers.http[httpDriver].get(url, function(s,b) callback(s, b) latte.tick() end)
end

function latte.http.post(url, callback)
	--if httpDriver == nil then p("No driver for HTTP! Failing.") return end

	latte._drivers.http[httpDriver].post(url, data, function(s,b) callback(s, b) latte.tick() end)
end

latte.exec = {}

function latte.exec.run(code)
	--if execDriver == nil then p("No driver for execution! Failing.") return end

	return latte._drivers.exec[execDriver].exec(code)
end

--[[
function latte.need(ref, repo, ver)

end
]]

function latte.initcup(cup)
	print("\t-> Initialising: " .. ctag(cup)) -- todo: nice names/descirptions for cups... also, oop?
	if cup.load ~= nil then
		cup.load() -- todo: should pcall but, eh, speed, eugh.
	end

	--printtable(latte._files)

	local ct = ctag(cup)

	local opp = package.path

	local startDir = latte._dir .. ct .. "/" .. cup.version .. "/src/" -- todo: generate this from a function...
	package.path = startDir .. "?.lua;" .. package.path .. ";" .. startDir .. "?/init.lua" -- very bad, very hacky

	for k, v in pairs(cup.files) do
		local filename = v[1] or v.filename

		if v.export_namespace then
			if filename == nil then
				p("Failed while loading cup " .. ct .. ". Filename nil. Printing errornous filetable:")
				printtable(v) -- todo: be careful! this doesnt exist! or potentially. yet, ah...
			else
				print("\t-> RUNNING\t" .. latte._dir .. ct .. "/" .. cup.version .. "/src/" .. filename ..".")
				--print(latte._dir .. ct .. "/" .. cup.version .. "/src/" .. filename)
				
				-- todo: export_namespace, there's gotta be a more sane way of doing this. most modules have data about them in a table.
				-- todo: make these run from memory when they can! saving to disk just to read them again with dofile...
				_G[v.export_namespace] = dofile(latte._dir .. ct .. "/" .. cup.version .. "/src/" .. filename) -- again should be pcall
				--_G[v.export_namespace] = latte.exec.run(latte._files[ct .. "/" .. cup.version]["/src/" .. filename])
			end
		elseif v.autoload then
			if filename == nil then
				p("Failed while loading cup " .. ct .. ". Filename nil. Printing errornous filetable:")
				printtable(v) -- todo: be careful! this doesnt exist! or potentially. yet, ah...
			else
				print("\t-> RUNNING\t" .. latte._dir .. ct .. "/" .. cup.version .. "/src/" .. filename ..".")
				dofile(latte._dir .. ct .. "/" .. cup.version .. "/src/" .. filename)
				--latte.exec.run(latte._files[ct .. "/" .. cup.version]["/src/" .. filename])
			end
		end
	end

	package.path = opp

end

-- todo: REPLACE, SO BAD [SECURITY] [CRITICAL]
-- a cross platform, no dependency solution doesn't seem likely.
local function createDir(dir)
	if dir:match(";") or dir:match("\"") then return end

	os.execute(string.format("mkdir -p %s;", dir))

end

local function strtok(source, delimiters)
    local elements = {}
    local pattern = '([^'..delimiters..']+)'
    string.gsub(source, pattern, function(value) elements[#elements + 1] = value end)
    
    return elements
end

function explodePath(path)
	return strtok(path, "/")
end

-- (should) return "path", "filename" and "ext".
-- untested, temporary. todo: needs to be replaced 
local function SplitFilename(strFilename)
	-- Returns the Path, Filename, and Extension as 3 values
	if isdir(strFilename) then
		local strPath = strFilename:gsub("[\\/]$","")
		return strPath.."\\","",""
	end
	return strFilename:match("(.-)([^\\/]-([^\\/%.]+))$")
end

local function cfdir(cup, filename)
	return latte._dir .. ctag(cup) .. "/" .. cup.version .. "/src/" .. filename
end

-- todo: rewrite this function and restructure the loading order of everything.
-- also todo: dependencies. so handle that here, somehow..... ugh....
function latte.grabfile(cup, filetbl)
	local filename

	if type(filetbl) == "string" then
		filename = filetbl
	else
		filename = filetbl[1] or filetbl.filename --- uggghhhh, todo: fix this

		--[[if not filename.filename and not filetbl.url then -- todo: fix this/clean this
			local exPath = explodePath(filename)
			filename = exPath[#exPath]
			print("\t->No filename! Guessing from URL... " .. filename)
		end]]
	end

	local ct = ctag(cup)
	local ctv = ct .. "/" .. cup.version -- todo: sort this the fuck out....
	if _pendingFiles[ct] == nil then _pendingFiles[ct] = {} end
	
	if latte._files[ctv] and latte._files[ctv][filename] then
		filedata = latte._files[ctv][filename]
		--print(ctv, filename)
		print("\t-> " .. filename .. "\tMEMORY")
	elseif fexists(cfdir(cup, filename)) then
		local fo = io.open(cfdir(cup, filename), "r")
		filedata = fo:read("*all")
		if latte._files[ctv] == nil then latte._files[ctv] = {} end
		latte._files[ctv][filename] = filedata
		--print(ctv, filename)
		fo:close()
		print("\t-> " .. filename .. "\tDISK")
	else
		_pendingFiles[ct][filename] = true
		--print(ctv, filename)
		local dlURL
		-- todo: modularity!
		if cup.source == "github" then

			dlURL = "https://cdn.rawgit.com/" .. cup.author .. "/" .. cup.ref .. "/" .. cup.version .. "/" .. (filetbl[1] or filetbl.url or filetbl.filename or "test")
			--p(dlURL)
		elseif cup.source == "http" then
			dlURL = filetbl.url
			print(filename .. " <-- FROM " .. filetbl.url)
		else 
			p("Unhandled cup source! " .. cup.source)
		end

		latte.http.get(dlURL, function(status, body)
			if status == 200 then
				--print("isdir: " .. tostring(cfdir(cup, "")), tostring(isdir(cfdir(cup, ""))))
				--if not isdir(cfdir(cup, "")) then createDir(cfdir(cup, "")) end -- ugh, line below was quick fix, this is now redundant
				if latte._files[ctv] == nil then latte._files[ctv] = {} end
				latte._files[ctv][filename] = body

				if not filetbl.nocache then
					local path, file, ext = SplitFilename(filename)
					--print("isdir2: " .. tostring(cfdir(cup, path)), tostring(isdir(cfdir(cup, path))))
					if not isdir(cfdir(cup, path)) then createDir(cfdir(cup, path)) end


					local fo = io.open(cfdir(cup, filename), "w")
					fo:write(body)
					fo:close()
				end

				print("\t-> " .. filename .. "\tDL'd!")
				_pendingFiles[ct][filename] = nil
			else
				print("\t-> " .. filename .. "\tDL FAILED! Status: " .. status)
				print(body)
			end
		end)
	end
end

function latte.get(cup)
	local ct = ctag(cup)

	p("Getting Cup: " .. ct)
	
	--[[if latte.cups[ct] == nil then -- todo: metadata/local cache/etc
		if fexists(latte._dir .. ct .. "/latte.json") then
			latte.cups[ct] ]]

	latte.cups[ct] = cup

	if cup.source == "github" or cup.source == "http" then
		for k, v in pairs(cup.files) do
			if type(v) == "string" then
				latte.grabfile(cup, v)
			else
				if v[1] or v.filename then
					latte.grabfile(cup, v)
				else
					p("Cup with file that's invalid!")
					printtable(cup)
					return
				end
			end
		end
	else
		p("Cup with source type " .. cup.source .. " with no handler! Todo: make this modular")
	end

	-- todo: async?
	for ct, pendingFiles in pairs(_pendingFiles) do
		if #pendingFiles == 0 then
			_pendingFiles[ct] = nil

			latte.initcup(latte.cups[ct])
		end
	end
end

return latte