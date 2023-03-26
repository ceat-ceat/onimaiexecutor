-- ceat_ceat 2022

--[[

----------------------------------------------------------------
		Constructor
----------------------------------------------------------------

	Methods ----------------------------------------------------------------------------
		<BindableEvent> new(<string> name)
			creates a new bindable event with the given name
			name is not required, it just allows an event (BindableEvent.Event) to print its name
			if given one to match the name it is given in a fake instance
			for example
			
				print(Constructor.new("Hi"))
				
			prints "BindableEvent" but
			
				print(Constructor.new("Hi").Event)
				
			prints "Signal Hi"
			

]]
local bindableevent = {}
local event = {}
local connection = {}

bindableevent.__index = bindableevent
event.__index = event
connection.__index = connection

bindableevent.__tostring = function()
	return "BindableEvent"
end

event.__tostring = function(self)
	return "Signal" .. (self.Name and " " .. self.Name or "")
end

connection.__tostring = function()
	return "Connection"
end

-- connections

function connection:Disconnect()
	self.Connected = false
	self.Callback = nil
	
	table.remove(self.Parent.Connections, table.find(self.Parent.Connections, self))
end

connection.disconnect = connection.Disconnect

function connection.new(parent, callback): RBXScriptConnection
	local new = setmetatable({
		Parent = parent,
		Connected = true,
		Callback = callback
	}, connection)
	
	return new
end

-- event

function event:Connect(callback): RBXScriptConnection
	local newconnection = connection.new(self, callback)
	table.insert(self.Connections, newconnection)
	return newconnection
end

function event:Wait()
	local currentparams = self.Params
	
	repeat
		task.wait()
	until self.Params ~= currentparams
	
	return unpack(self.Params)
end

event.connect = event.Connect
event.wait = event.Wait

function event.new(name: string?): RBXScriptSignal
	local new = setmetatable({
		Name = name,
		Params = {},
		Connections = {}
	}, event)
	
	return new
end

-- bindable

function bindableevent:Fire(...)
	local params = {...}
	
	for _, connection in next, self.Event.Connections do
		spawn(function()
			connection.Callback(unpack(params))
		end)
	end
	
	self.Event.Params = params
end

function bindableevent:Destroy()
	for _, c in self.Event.Connections do
		c:Disconnect()
	end
end

bindableevent.fire = bindableevent.Fire
bindableevent.destroy = bindableevent.Destroy

function bindableevent.new(eventname: string?): BindableEvent
	local new = setmetatable({
		Event = event.new(eventname)
	}, bindableevent)
	
	return new
end

return bindableevent
