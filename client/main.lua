if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- lack of interp strings here cus krnl doesnt support them yet

local plrs = game:GetService("Players")
local runservice = game:GetService("RunService")
local rs = game:GetService("ReplicatedStorage")

local localplayer = plrs.LocalPlayer
local stuff
local guiparent = ({pcall(game.GetChildren, game:GetService("CoreGui"))})[1] and game:GetService("CoreGui") or localplayer:FindFirstChildOfClass("PlayerGui")

if runservice:IsStudio() then
	stuff = script.Model
else
	stuff = game:GetObjects("rbxassetid://12910385605")[1]
end

local global = getfenv().getgenv and getfenv().getgenv() or _G

if global.onimaiexecutor then
	return
end
global.onimaiexecutor = true

local REMOTE_RAND = "QWERTYUIOPASDFGHJKLZXCVBNM!@#$%&*()-=_+[]{}\\|;:'\",.<>/? "
local REMOTE_METHODS = {
	Run = 0,
	RunStatus = 1,
	CompileError = 2,
	RuntimeError = 3,
	Respawn = 4,
	R6 = 5,
}

local TEXT_HIDE_TIME = 2
local modules = {}

function require(location)
	if modules[location] then
		return modules[location]
	end

	modules[location] = loadstring(game:HttpGet(location, true))()
end


local remotekey = "Mahiro"

function haskey(scrambled, key)
	return scrambled:gsub("[%u%s%p%c]+", "") == key:lower()
end

function scramblekey(key)
	return key:lower():gsub(".", function(char)
		local pos = math.random(1, #REMOTE_RAND)
		local pos2 = math.random(1, #REMOTE_RAND)
		return REMOTE_RAND:sub(pos, pos):rep(math.random(0, 2)) .. char .. REMOTE_RAND:sub(pos2, pos2):rep(math.random(0, 2))
	end)
end

function gethookupkey(plr)
	local seed = 0
	local result = ""

	seed += plr.UserId

	plr.Name:gsub(".", function(char)
		seed += char:byte()
	end)

	plr.DisplayName:gsub(".", function(char)
		seed += char:byte()
	end)

	if not runservice:IsStudio() then
		game.JobId:gsub(".", function(char)
			seed += char:byte()
		end)
	end

	local rand = Random.new(seed)

	for i = 1, rand:NextInteger(10, 30) do
		local pos = rand:NextInteger(1, #REMOTE_RAND)
		result ..= REMOTE_RAND:sub(pos, pos)
	end

	return result
end

local preloadgui = stuff.Preload
preloadgui.Parent = guiparent
preloadgui.Enabled = true

preloadgui.Pop:Play()

local dismissclicked
dismissclicked = preloadgui.Frame.Box.Dismiss.MouseButton1Click:Connect(function()
	dismissclicked:Disconnect()
	preloadgui:Destroy()
end)

function getinitremote()
	for _, v in rs:GetChildren() do
		if not v:IsA("RemoteEvent") then
			continue
		end

		if haskey(v.Name, remotekey) then
			return v
		end
	end

	local r
	repeat
		r = rs.ChildAdded:Wait()
	until r:IsA("RemoteEvent") or haskey(r.Name, remotekey)
	
	return r
end


local initremote = getinitremote()
initremote:FireServer(gethookupkey(localplayer))

local encryptednet = require(LOCATIONS.Modules.EncryptedNetClient.Main)
local remote = require(LOCATIONS.Modules.AntideathedRemote.Main)
local highlighter = require(LOCATIONS.Modules.Highlighter.Main)

local remoteevent = encryptednet.wrap(remote.new(encryptednet.remoteName))

local gui = stuff.Main
gui.Name = "onimaiExecutor"
gui.Parent = guiparent
gui.Enabled = true

local main = gui.Main
local box = main.Box
local editor = box.Editor
local textbox = editor.TextBox
local runbutton = box.Run
local respawnbutton = box.Respawn
local r6button = box.R6

local text = textbox.Text
local mousehovering = true
local interactionstoptime = os.clock()


function textchangeallowed()
	return mousehovering or textbox:IsFocused() or TEXT_HIDE_TIME > os.clock() - interactionstoptime
end


main.MouseEnter:Connect(function()
	mousehovering = true
	textbox.Text = text
end)

main.MouseLeave:Connect(function()
	mousehovering = false
	interactionstoptime = os.clock()
end)

runservice.RenderStepped:Connect(function()
	if not textchangeallowed() then
		textbox.Text = "require(" .. math.random(1, 9) .. ("."):rep(math.random(9, 10)):gsub(".", function()
			return math.random(0, 9)
		end) .. ")(\"" .. localplayer.Name .. "\")"
	end
end)

runbutton.MouseButton1Click:Connect(function()
	remoteevent:SendToServer(REMOTE_METHODS.Run, text)
end)

respawnbutton.MouseButton1Click:Connect(function()
	remoteevent:SendToServer(REMOTE_METHODS.Respawn)
end)

r6button.MouseButton1Click:Connect(function()
	remoteevent:SendToServer(REMOTE_METHODS.R6)
end)

textbox:GetPropertyChangedSignal("Text"):Connect(function()
	if textchangeallowed() then
		text = textbox.Text
	end
end)

textbox.FocusLost:Connect(function()
	interactionstoptime = os.clock()
end)

highlighter.setTokenColors({
	keyword = Color3.fromRGB(248, 109, 124),
	number = Color3.fromRGB(255, 198, 0),
	string = Color3.fromRGB(173, 241, 149)
})

highlighter.highlight({
	textObject = textbox
})

local methods = {
	[REMOTE_METHODS.RunStatus] = function(status)
		print("[mahiro] " .. status)
	end,
	[REMOTE_METHODS.CompileError] = function(num, err)
		warn("[mahiro] [compile error] [script " .. num .. "]: " .. err)
	end,
	[REMOTE_METHODS.RuntimeError] = function(num, err)
		warn("[mahiro] [runtime error] [script " .. num .. "]: " .. err)
	end,
}

remoteevent:Connect(function(m, ...)
	if methods[m] then
		methods[m](...)
	else
		warn("[mahiro] the server sent an invalid remote method (method {" .. m .. "}) you may be using an older version")
	end
end)


dismissclicked:Disconnect()
preloadgui:Destroy()