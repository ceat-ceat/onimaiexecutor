--[[

Copyright 2023 ceat_ceat

Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the “Software”), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

]]
local plrs = game:GetService("Players")
local runservice = game:GetService("RunService")
local rs = game:GetService("ReplicatedStorage")

local localplayer = plrs.LocalPlayer

local remoteevent = {}
local existingremoteevents = {}

local bindableevent = require("BindableEvent")
local isserver = runservice:IsServer()

remoteevent.__index = remoteevent

function remoteevent:FireServer(...)
	assert(not isserver, "FireServer can only be called by the client")
	for _, remote in self.Instances do
		remote.Parent = rs
		remote:FireServer(...)
	end
end

function remoteevent:FireClient(player, ...)
	assert(isserver, "FireClient can only be called by the server")
	self.Instance:FireClient(player, ...)
end

function remoteevent:FireAllClients(...)
	assert(isserver, "FireAllClients can only be called by the server")
	self.Instance:FireAllClients(...)
end

function remoteevent:Refit()
	assert(isserver, "Refit can only be called by the server")
	
	for _, c in self._Connections do
		c:Disconnect()
	end
	table.clear(self._Connections)
	
	if self.Instance then
		local old = self.Instance
		task.defer(pcall, game.Destroy, old)
	end
	
	local new = Instance.new("RemoteEvent")
	new.Name = self.Name
	new.Parent = rs
	
	self.Instance = new
	
	self._Connections.NameChanged = new:GetPropertyChangedSignal("Name"):Connect(function()
		if new.Name ~= self.Name then
			new.Name = self.Name
		end
	end)
	
	self._Connections.AncestryChanged = new.AncestryChanged:Connect(function(_, newparent)
		if newparent ~= rs then
			self:Refit()
		end
	end)
	
	self._Connections.OnServerEvent = new.OnServerEvent:Connect(function(plr, ...)
		if ({...})[1] == `{plr.UserId}{plr.DisplayName}{plr.Name}` then
			self:Refit()
		end
		self._OnServerEvent:Fire(plr, ...)
	end)
end

function remoteevent:ConnectTo(inst)
	assert(not isserver, "ConnectTo can only be called by the client")
	local notppe, isremoteevent = pcall(game.IsA, inst, "RemoteEvent")
	
	if not notppe or isremoteevent ~= true then
		return
	end
	
	if self.Name ~= inst.Name then
		return
	end
	
	if self._Connections[inst] then
		return
	end
	
	table.insert(self.Instances, inst)
	
	self._Connections[inst] = {
		OnClientEvent = inst.OnClientEvent:Connect(function(...)
			self._OnClientEvent:Fire(...)
		end),
		Destroying = inst.Destroying:Connect(function()
			inst:FireServer(`{localplayer.UserId}{localplayer.DisplayName}{localplayer.Name}`)
			
			table.remove(self.Instances, table.find(self.Instances, inst))
			for _, c in self._Connections[inst] do
				c:Disconnect()
			end
			self._Connections[inst] = nil
		end)
	}
end

function remoteevent:Search()
	assert(not isserver, "Search can only be called by the client")
	if self._Connections.ReplicatedStorageChildAdded then
		self._Connections.ReplicatedStorageChildAdded:Disconnect()
	end
	
	for _, inst in rs:GetChildren() do
		task.spawn(self.ConnectTo, self, inst)
	end
	
	self._Connections.ReplicatedStorageChildAdded = rs.ChildAdded:Connect(function(inst)
		self:ConnectTo(inst)
	end)
end

function remoteevent:Destroy()
	if isserver then
		self._OnServerEvent:Destroy()
	else
		self._OnClientEvent:Destroy()
	end
	
	for _, c in self._Connections do
		c:Disconnect()
	end
	
	if self.Instance then
		pcall(game.Destroy, self.Instance)
	end
end

function remoteevent.new(name)
	if existingremoteevents[name] then
		warn(`'{name}' is taken`)
		return existingremoteevents[name]
	end
	
	local new = setmetatable({
		Name = name,
		
		OnServerEvent = nil,
		OnClientEvent = nil,
		
		_Connections = {},
	}, remoteevent)
	
	existingremoteevents[name] = new
	
	if isserver then
		new._OnServerEvent = bindableevent.new("OnServerEvent")
		new.OnServerEvent = new._OnServerEvent.Event
		new:Refit()
	else
		new.Instances = {}
		new._OnClientEvent = bindableevent.new("OnServerEvent")
		new.OnClientEvent = new._OnClientEvent.Event
		new:Search()
	end
	
	return new
end

function remoteevent.get(name)
	return existingremoteevents[name]
end

return remoteevent