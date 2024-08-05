--[[>----------------------------------------------<|

    --[ HayaOS ]--
	A new start for a kernel, for CraftOS-PC
	and ComputerCraft!
	
	--[ NOTE ]--
	Licensed under CC BY-SA 4.0. This does apply,
	however please contact Keyboard via discord
	at QuickMuffin8782's discord server via a
	contact ticket. Make sure to let him know
	you want to help!
	tinyurl.com/QM8782-DISCORD
	
	--[ PROJECT LINK ]--
	github.com/AFellowSpeedRunner/HayaOS
	
	Contributors:
	- MrMasterKeyboard [CREATOR]
	- QuickMuffin8782
	- KosmiCat42

|>------------------------------------------------<]]

term.setTextColor(colors.white)
term.setBackgroundColor(colors.black)
term.setCursorPos(1,1)
term.clear()

if not term.isColor() then
	print("HayaOS does not support standard computers")
	print("Install on a colored computer instead...")
	while true do os.pullEventRaw() end
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
	sleep(0.05)
end

local function playSound(snd)
	if peripheral.find("speaker") then 
		pcall(function() peripheral.find("speaker").playLocalMusic("/sys/snd/"..(snd or "ding")..".dfpwm") end)
	end
end

local expect = (type(loadfile("/sys/modules/main/cc/expect.lua")()) == "table" and loadfile("/sys/modules/main/cc/expect.lua")().expect or showFailScreen(-1, "failed to load required module, please reboot"))
_G["require"] = (type(loadfile("/sys/modules/main/cc/require.lua")()) == "table" and loadfile("/sys/modules/main/cc/require.lua")().make(_ENV, "/sys/modules/") or showFailScreen(-1, "failed to load required module, please reboot"))

if periphemu then
	log("i", "Init audio driver")
	if not peripheral.find("speaker") then
		os.run(_ENV, "/sys/programs/attach.lua", "back", "speaker")
	end
end

if _G.config then --// CraftOS-PC checks for CC compatibility	
	if config.get("keepOpenOnShutdown") == false then
		log("wa", "Hey, to make it better, we fixed the close on shutdown for you! It will no longer shutdown. To reboot, hold Ctrl+R for 3 seconds!")
		config.set("keepOpenOnShutdown", true)
	end
	if config.get("useDFPWM") == false then
		log("wa", "Found invalid configuration for audio systems, fixing!")
		config.set("useDFPWM", true)
	end
	if config.get("snapToSize") == false then
		log("wa", "Found invalid configuration for computer window, fixing!")
		config.set("useDFPWM", true)
	end
	if config.get("monitorsUseMouseEvents") == false then
		log("wa", "Found invalid configuration for potential monitors, fixing!")
		config.set("monitorsUseMouseEvents", true)
	end
	--[[if settings.get("bios.use_multishell") == true then
		log("err", "CRITICAL COMPONENT WAS FOUND MISCONFIGURED! FIXING NOW!")
		settings.set("bios.use_multishell", false)
	end]]--// I have no clue why it doesn't set. Commented for now!
end
local r_success, r_err = pcall(function()
	os.run(_ENV, "/sys/init.lua")
	log("sys", "Init kernel")
	sleep(0.5)
	term.setTextColor(colors.white)
	term.setBackgroundColor(colors.black)
	term.setCursorPos(1,1)
	term.clear()
	term.setTextColor(colors.purple)
	playSound("startup")
	print("")
	print("Hi master! :3")
	print("What should we do together?")
	print("-HayaOS")
	print("")
	term.setTextColor(colors.white)

	if settings.get("motd.enable") then
		os.run(_ENV, "/sys/programs/motd.lua")
	end
	print("")
	os.run(_ENV, "/sys/programs/shell.lua")
end)
if not r_success then
	showFailScreen(-1, r_err)
else
	term.setTextColor(colors.white)
	term.setBackgroundColor(colors.black)
	term.setCursorPos(1,1)
	term.clear()
	log("sys", "System exited with no errors. Now entering into developer LUA module...")
	os.run(_ENV, "/sys/programs/lua.lua")
	log("sys", "Lua program exited. Shutting down...")
	os.shutdown()
end
