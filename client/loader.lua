LOCATIONS = loadstring(game:HttpGet("https://raw.githubusercontent.com/ceat-ceat/onimaiexecutor/main/locations.lua", true))()

local global = getgenv()

if global.onimaiexecutor then
	return
end
global.onimaiexecutor = {
    Locations = LOCATIONS
}

local success, err = pcall(loadstring, game:HttpGet(LOCATIONS.Main, true))

if not success then
    warn("[Mahiro] " .. err)
    global.onimaiexecutor = nil
end