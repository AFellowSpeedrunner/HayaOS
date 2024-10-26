-- SPDX-FileCopyrightText: 2017 Daniel Ratcliffe
--
-- SPDX-License-Identifier: LicenseRef-CCPL

-- Modified for HayaOS

--// replace old function to make way for kernel ===KERNEL VERSION ALWAYS HERE===
local hayaVersion = "0.0.4D"
_G["os"]["version"] = function()
	return "HayaOS v"..hayaVersion
end


local scr_w, scr_h = term.getSize()
local old_pullEvent = os.pullEvent --// To help make toggling termination easy...
local old_pullEventRaw = os.pullEventRaw 

local function formatFilePointer(name)
	if type(name) ~= "string" then error("bad argument #1, expected string (got "..type(name)..")", 2) end
	local t = name
	t = t:gsub("!%{curDir%}", (shell.dir():sub(0,1) == "/" and "" or "/")..shell.dir())
	t = t:gsub("!%[usrDir%}", "/Users/")
	return t
end

local function writeFile(fileDir, contents, ignoreErrors)
	if type(fileDir) ~= "string" then error("bad argument #1, expected string (got "..type(fileDir)..")", 2) end
	if type(contents) ~= "string"  then error("bad argument #2, expected string (got "..type(contents)..")", 2) end
	if not ignoreErrors then if fs.exists(formatFilePointer(fileDir)) then else error("file "..formatFilePointer(fileDir).." does not exist", 2) end end
	local f = fs.open(fileDir, "w+")
	if f then
		f.write(contents)
		f.close()
	else
		local loopInd = true
		while loopInd do
			local f = fs.open(fileDir, "w+")
			if f then
				f.write(contents)
				f.close()
				loopInd = false
			end
		end
	end
end

local function readFile(fileDir)
	if type(fileDir) ~= "string" then error("bad argument #1, expected string (got "..type(fileDir)..")", 2) end
	if fs.exists(formatFilePointer(fileDir)) then else error("file "..formatFilePointer(fileDir)" does not exist", 2) end
	local f = fs.open(fileDir, "r+")
	local rt = ""
	if f then
		rt = f.realAll()
		f.close()
	else
		local loopInd = true
		while loopInd do
			local f = fs.open(fileDir, "r+")
			if f then
				rt = f.realAll()
				f.close()
				loopInd = false
			end
		end
	end
	return rt
end
	

local function setShellTermination(bool)
	if bool then
		_G["os"]["pullEvent"] = old_pullEvent --// Enable termination via Ctrl+T
	else
		_G["os"]["pullEvent"] = old_pullEventRaw --// Disable termination via Ctrl+T
	end
end

local function showFailScreen(nLvl, sErr, sCustomLevelName)
	--// 3 argument passes when it's an unknown number. Don't pass it to show "unknown"
	if type(nLvl) == "number" then else error("bad argument #1, expected number (got "..type(nLvl)..")", 2) end
	if table.pack(pcall(tostring, sErr))[1] == false then error("bad argument #2, expected number (got "..type(sErr)..")", 2) end
	if type(sCustomLevelName) == "number" or type(sCustomLevelName) == "string" or type(sCustomLevelName) == "nil" then else error("bad argument #1, expected string (got "..type(sCustomLevelName)..")", 2) end
	local crashedBeforeReboot = false
	if fs.exists("/.tmpcrashmarker") then crashedBeforeReboot = true else writeFile("/.tmpcrashmarker", "--// You opened me. This is a crash marker, so you're welcome.", true) end
	setShellTermination(false)
	term.setTextColor(colors.red)
	term.setBackgroundColor(colors.black)
	term.setCursorPos(1,1)
	term.clear()
	print("EXCEPTION OCCURRED!")
	print("")
	print("\140 PANIC: "..("\140"):rep(scr_w-9))
	print("error \16 "..sErr)
	term.write("level: ")
	if nLvl == -2 then
		print("developer note or info")
	elseif nLvl == -1 then
		print("kernel halt")
	elseif nLvl == 0 then
		print("program script")
	elseif nLvl == 1 then
		print("program api thrown")
	else
		print((pcall(tostring, sCustomLevelName) and tostring(sCustomLevelName):lower() or "unknown"))
	end
	print(("\140"):rep(scr_w))
	print("")
	local _, tmp_y = term.getCursorPos()
	for i = 0, 5 do
		term.setCursorPos(1,tmp_y)
		term.clearLine()
		term.write("Wait "..(5-i).." secs...")
		sleep(1)
	end
	term.setCursorPos(1,tmp_y)
	term.clearLine()
	print("Press enter now to reboot.")
	while true do
		local ev = {os.pullEvent()} --// Use it like normal. Function turns it off and on when key pressed, either by numpad, or usual enter key.
		if ev[1] == "key_up" and (ev[2] == keys.enter or ev[2] == keys.numPadEnter) then
			os.reboot()
		end
	end
end 

local function log(nType, sText, ...)
	--[[
	  || Dev note: "color" or "colour" will work. The devs of CraftOS aka Dan200 set it this way.
	  ||           Check https://tweaked.cc/, it contains the API docs for the base that this kernel
	  ||           will function like.
	--]]
	local types = {
		["err"] = {colors.red, "error"},
		["wa"] = {colors.yellow, "warn"},
		["i"] = {colors.purple, "info"},
		["log"] = {colors.purple, "log"},
		["sys"] = {colors.purple, "system"},
	}
	local notInvalid = true
	for key, _ in pairs(types) do
		if nType:sub(0,#key) == key then notInvalid = false end 
	end
	if notInvalid then error("bad argument #1, no type found for key given (check code)", 2) end 
	term.setTextColor(colors.purple) 
	term.setBackgroundColor(colors.black)
	term.write("[COM"..os.getComputerID().."] ")
	for key, data in pairs(types) do
		if nType:sub(0,#key) == key then
			term.setTextColor(data[1]) 
			term.setBackgroundColor(colors.black)
			term.write("["..data[2]:upper().."] ")
			break
		end
	end
	term.setTextColor(colors.white)
	print(sText, ...) --// Pass all other arguments except the first for normal print function
end

_G.hayaOS = {}

_G.hayaOS.crash = function(reason)
	showFailScreen(2, reason, "system halt")
end

_G.hayaOS.log = log

_G.hayaOS.setShellTermination = setShellTermination

_G.hayaOS.formatFilePointer = formatFilePointer

local completion = (type(loadfile("/sys/modules/main/cc/shell/completion.lua")()) == "table" and loadfile("/sys/modules/main/cc/shell/completion.lua")() or showFailScreen(-1, "failed to load required module, please reboot"))

log("i", "Setup paths for kernel")
-- Setup paths
local sPath = ".:/sys/programs:/sys/programs/http"
if term.isColor() then
    sPath = sPath .. ":/sys/programs/advanced"
end
if turtle then
    sPath = sPath .. ":/sys/programs/turtle"
else
    sPath = sPath .. ":/sys/programs/rednet:/sys/programs/fun"
    if term.isColor() then
        sPath = sPath .. ":/sys/programs/fun/advanced"
    end
end
if pocket then
    sPath = sPath .. ":/sys/programs/pocket"
end
if commands then
    sPath = sPath .. ":/sys/programs/command"
end
shell.setPath(sPath)

log("i", "Setup manual")
help.setPath("/sys/help")

-- Setup aliases
log("i", "Setup commands for kernel")
shell.setAlias("ls", "list")
shell.setAlias("dir", "list")
shell.setAlias("cp", "copy")
shell.setAlias("mv", "move")
shell.setAlias("rm", "delete")
shell.setAlias("clr", "clear")
shell.setAlias("rs", "redstone")
shell.setAlias("sh", "shell")
shell.setAlias("man", "help")
if term.isColor() then
    shell.setAlias("background", "bg")
    shell.setAlias("foreground", "fg")
end

-- Setup completion functions
log("i", "Setup command autocompletion")
local function completePastebinPut(shell, text, previous)
    if previous[2] == "put" then
        return fs.complete(text, shell.dir(), true, false)
    end
end

local function completeConfigPart2(shell, text, previous)
    if previous[2] == "get" or previous[2] == "set" then
        return completion.choice(shell, text, previous, config.list(), previous[2] == "set")
    end
end

local function completeConfigPart3(shell, text, previous)
    if previous[2] == "set" then
        if config.getType(previous[3]) == "boolean" then return completion.choice(shell, text, previous, {"true", "false"})
        elseif previous[3] == "mount_mode" then return completion.choice(shell, text, previous, {"none", "ro", "ro_strict", "rw"}) end
    end
end

shell.setCompletionFunction("sys/programs/alias.lua", completion.build(nil, completion.program))
shell.setCompletionFunction("sys/programs/cd.lua", completion.build(completion.dir))
shell.setCompletionFunction("sys/programs/clear.lua", completion.build({ completion.choice, { "screen", "palette", "all" } }))
shell.setCompletionFunction("sys/programs/copy.lua", completion.build(
    { completion.dirOrFile, true },
    completion.dirOrFile
))
shell.setCompletionFunction("sys/programs/delete.lua", completion.build({ completion.dirOrFile, many = true }))
shell.setCompletionFunction("sys/programs/drive.lua", completion.build(completion.dir))
shell.setCompletionFunction("sys/programs/edit.lua", completion.build(completion.file))
shell.setCompletionFunction("sys/programs/eject.lua", completion.build(completion.peripheral))
shell.setCompletionFunction("sys/programs/gps.lua", completion.build({ completion.choice, { "host", "host ", "locate" } }))
shell.setCompletionFunction("sys/programs/help.lua", completion.build(completion.help))
shell.setCompletionFunction("sys/programs/id.lua", completion.build(completion.peripheral))
shell.setCompletionFunction("sys/programs/label.lua", completion.build(
    { completion.choice, { "get", "get ", "set ", "clear", "clear " } },
    completion.peripheral
))
shell.setCompletionFunction("sys/programs/list.lua", completion.build(completion.dir))
shell.setCompletionFunction("sys/programs/mkdir.lua", completion.build({ completion.dir, many = true }))

local complete_monitor_extra = { "scale" }
shell.setCompletionFunction("sys/programs/monitor.lua", completion.build(
    function(shell, text, previous)
        local choices = completion.peripheral(shell, text, previous, true)
        for _, option in pairs(completion.choice(shell, text, previous, complete_monitor_extra, true)) do
            choices[#choices + 1] = option
        end
        return choices
    end,
    function(shell, text, previous)
        if previous[2] == "scale" then
            return completion.peripheral(shell, text, previous, true)
        else
            return completion.programWithArgs(shell, text, previous, 3)
        end
    end,
    {
        function(shell, text, previous)
            if previous[2] ~= "scale" then
                return completion.programWithArgs(shell, text, previous, 3)
            end
        end,
        many = true,
    }
))

shell.setCompletionFunction("sys/programs/move.lua", completion.build(
    { completion.dirOrFile, true },
    completion.dirOrFile
))
shell.setCompletionFunction("sys/programs/redstone.lua", completion.build(
    { completion.choice, { "probe", "set ", "pulse " } },
    completion.side
))
shell.setCompletionFunction("sys/programs/rename.lua", completion.build(
    { completion.dirOrFile, true },
    completion.dirOrFile
))
shell.setCompletionFunction("sys/programs/shell.lua", completion.build({ completion.programWithArgs, 2, many = true }))
shell.setCompletionFunction("sys/programs/type.lua", completion.build(completion.dirOrFile))
shell.setCompletionFunction("sys/programs/set.lua", completion.build({ completion.setting, true }))
shell.setCompletionFunction("sys/programs/advanced/bg.lua", completion.build({ completion.programWithArgs, 2, many = true }))
shell.setCompletionFunction("sys/programs/advanced/fg.lua", completion.build({ completion.programWithArgs, 2, many = true }))
shell.setCompletionFunction("sys/programs/fun/dj.lua", completion.build(
    { completion.choice, { "play", "play ", "stop " } },
    completion.peripheral
))
shell.setCompletionFunction("sys/programs/fun/speaker.lua", completion.build(
    { completion.choice, { "play ", "sound ", "stop " } },
    function(shell, text, previous)
        if previous[2] == "play" then return completion.file(shell, text, previous, true)
        elseif previous[2] == "stop" then return completion.peripheral(shell, text, previous, false)
        end
    end,
    function(shell, text, previous)
        if previous[2] == "play" then return completion.peripheral(shell, text, previous, false)
        end
    end
))
shell.setCompletionFunction("sys/programs/fun/advanced/paint.lua", completion.build(completion.file))
shell.setCompletionFunction("sys/programs/http/pastebin.lua", completion.build(
    { completion.choice, { "put ", "get ", "run " } },
    completePastebinPut
))
shell.setCompletionFunction("sys/programs/http/gist.lua", completion.build(
    { completion.choice, { "put ", "get ", "run ", "edit ", "info ", "delete " } },
    completePastebinPut
))
shell.setCompletionFunction("sys/programs/rednet/chat.lua", completion.build({ completion.choice, { "host ", "join " } }))
shell.setCompletionFunction("sys/programs/command/exec.lua", completion.build(completion.command))
shell.setCompletionFunction("sys/programs/http/wget.lua", completion.build({ completion.choice, { "run " } }))

if periphemu and config and mounter then
    shell.setCompletionFunction("sys/programs/attach.lua", completion.build(
        completion.peripheral,
        { completion.choice, periphemu.names() }
    ))
    shell.setCompletionFunction("sys/programs/detach.lua", completion.build(completion.peripheral))
    shell.setCompletionFunction("sys/programs/config.lua", completion.build(
        { completion.choice, { "get ", "set ", "list " } },
        completeConfigPart2,
        completeConfigPart3
    ))
    shell.setCompletionFunction("sys/programs/mount.lua", completion.build(completion.dir))
    shell.setCompletionFunction("sys/programs/unmount.lua", completion.build(completion.dir))
end

if turtle then
    shell.setCompletionFunction("sys/programs/turtle/go.lua", completion.build(
        { completion.choice, { "left", "right", "forward", "back", "down", "up" }, true, many = true }
    ))
    shell.setCompletionFunction("sys/programs/turtle/turn.lua", completion.build(
        { completion.choice, { "left", "right" }, true, many = true }
    ))
    shell.setCompletionFunction("sys/programs/turtle/equip.lua", completion.build(
        nil,
        { completion.choice, { "left", "right" } }
    ))
    shell.setCompletionFunction("sys/programs/turtle/unequip.lua", completion.build(
        { completion.choice, { "left", "right" } }
    ))
end

-- Run autorun files
if fs.exists("/sys/autorun") and fs.isDir("/sys/autorun") then
    local tFiles = fs.list("/sys/autorun")
    for _, sFile in ipairs(tFiles) do
        if string.sub(sFile, 1, 1) ~= "." then
            local sPath = "/sys/autorun/" .. sFile
            if not fs.isDir(sPath) then
                shell.run(sPath)
            end
        end
    end
end

local function findStartups(sBaseDir)
    local tStartups = nil
    local sBasePath = "/" .. fs.combine(sBaseDir, "startup")
    local sStartupNode = shell.resolveProgram(sBasePath)
    if sStartupNode then
        tStartups = { sStartupNode }
    end
    -- It's possible that there is a startup directory and a startup.lua file, so this has to be
    -- executed even if a file has already been found.
    if fs.isDir(sBasePath) then
        if tStartups == nil then
            tStartups = {}
        end
        for _, v in pairs(fs.list(sBasePath)) do
            local sPath = "/" .. fs.combine(sBasePath, v)
            if not fs.isDir(sPath) then
                tStartups[#tStartups + 1] = sPath
            end
        end
    end
    return tStartups
end



-- Run startup passed with --script if available
if _CCPC_STARTUP_SCRIPT then
    local fn, err = load(_CCPC_STARTUP_SCRIPT, "@startup.lua", "t", _ENV)
    if fn then
        local args = {}
        if _CCPC_STARTUP_ARGS then for n in _CCPC_STARTUP_ARGS:gmatch("[^ ]+") do table.insert(args, n) end end
        local oldpath
        if shell then
            local dir = shell.dir()
            if dir:sub(1, 1) ~= "/" then dir = "/" .. dir end
            if dir:sub(-1) ~= "/" then dir = dir .. "/" end

            local strip_path = "?;?.lua;?/init.lua;"
            local path = package.path
            if path:sub(1, #strip_path) == strip_path then
                path = path:sub(#strip_path + 1)
            end

            oldpath = package.path
            package.path = dir .. "?;" .. dir .. "?.lua;" .. dir .. "?/init.lua;" .. path
        end
        fn(table.unpack(args))
        if oldpath then package.path = oldpath end
    else printError("Could not load startup script: " .. err) end
end

-- Run the user created startup, either from disk drives or the root
local tUserStartups = nil
if settings.get("shell.allow_startup") then
    tUserStartups = findStartups("/usr/autostart/")
end
if settings.get("shell.allow_disk_startup") then
    for _, sName in pairs(peripheral.getNames()) do
        if disk.isPresent(sName) and disk.hasData(sName) then
            local startups = findStartups(disk.getMountPath(sName))
            if startups then
                tUserStartups = startups
                break
            end
        end
    end
end
if mobile and _CCPC_FIRST_RUN then
    tUserStartups = {"/sys/programs/mobile/onboarding.lua"}
end

if _CCPC_PLUGIN_ERRORS and settings.get("shell.report_plugin_errors") then
    log("wa", "Some plugins failed to load on CraftOS-PC")
	local i = 0
    for k,v in pairs(_CCPC_PLUGIN_ERRORS) do
		i=i+1
        log("wa", i.." \16 "..k..": "..v)
    end
end

if tUserStartups then
    for _, v in pairs(tUserStartups) do
        shell.run(v)
    end
end

