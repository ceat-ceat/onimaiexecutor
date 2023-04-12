local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local ECC = require("EllipticCurveCryptography")

local HANDSHAKE_RANDOMSTRING = "QWERTYUIOPASDFGHJKLZXCVBNMqwertyuiopasdfghjklzxcvbnm0123456789"
function GetHandkeshakeName()
	local seed = 0
	seed = seed + Players.LocalPlayer.UserId

	if not RunService:IsStudio() then
		game.JobId:gsub(".", function(char)
			seed += char:byte()
		end)
	end

	local rand = Random.new(seed)
	local returnString = ("."):rep(rand:NextInteger(32, 100)):gsub(".", function()
		local charPos = rand:NextInteger(1, #HANDSHAKE_RANDOMSTRING)
		return HANDSHAKE_RANDOMSTRING:sub(charPos, charPos)
	end)

	return returnString
end

local RemoteName = GetHandkeshakeName()
local HandshakeRemote

for _, Remote in ReplicatedStorage:GetChildren() do
	if Remote:IsA("RemoteFunction") and Remote.Name == RemoteName then
		HandshakeRemote = Remote
		break
	end
end

if not HandshakeRemote then
	repeat
		HandshakeRemote = ReplicatedStorage.ChildAdded:Wait()
	until HandshakeRemote and HandshakeRemote:IsA("RemoteFunction") and HandshakeRemote.Name == RemoteName
end

local clientPrivate, clientPublic = ECC.keypair(ECC.random.random())
local serverPublic, remoteName = HandshakeRemote:InvokeServer(clientPublic)
local sharedSecret = ECC.exchange(clientPrivate, serverPublic)


function Wrap(Remote)
	local Wrapper = setmetatable({ Connections = {} }, { __index = Remote })

	-- Event

	function Wrapper:SendToServer(...)
		local args = table.pack(...)
		local data = HttpService:JSONEncode(args)

		local encryptedData = ECC.encrypt(data, sharedSecret)
		local signature = ECC.sign(clientPrivate, data)

		return Remote:FireServer(encryptedData, signature)
	end

	function Wrapper:Connect(callback)
		local OnClientEvent = Remote.OnClientEvent:Connect(function(encryptedData, signature)
			-- Metatables get lost in transit
			setmetatable(encryptedData, ECC._byteMetatable)
			setmetatable(signature, ECC._byteMetatable)

			local data = ECC.decrypt(encryptedData, sharedSecret)
			local verified = ECC.verify(serverPublic, data, signature)

			if not verified then
				warn("Could not verify signature", Remote.instance.Name)
				return
			end

			local args = HttpService:JSONDecode(tostring(data))
			callback(table.unpack(args))
		end)

		table.insert(Wrapper.Connections, OnClientEvent)

		return OnClientEvent
	end

	-- AsyncFunction

	function Wrapper:CallServerAsync(...)
		local args = table.pack(...)
		local data = HttpService:JSONEncode(args)

		local encryptedData = ECC.encrypt(data, sharedSecret)
		local signature = ECC.sign(clientPrivate, data)

		return Remote:InvokeServer(encryptedData, signature)
	end

	function Wrapper:SetCallback(callback)
		Remote.OnClientInvoke = function(encryptedData, signature)
			-- Metatables get lost in transit
			setmetatable(encryptedData, ECC._byteMetatable)
			setmetatable(signature, ECC._byteMetatable)

			local data = ECC.decrypt(encryptedData, sharedSecret)
			local verified = ECC.verify(serverPublic, data, signature)

			if not verified then
				warn("Could not verify signature", Remote.instance.Name)
				return
			end

			local args = HttpService:JSONDecode(tostring(data))
			local success, response = pcall(callback, table.unpack(args))

			if not success then
				warn("Error in callback", Remote.instance.Name, response)
				return
			end

			return response
		end
	end

	-- Destroy

	function Wrapper:Destroy()
		for _, Connection in next, Wrapper.Connections do
			Connection:Disconnect()
		end

		Remote:Destroy()
	end

	return Wrapper
end

return {
	wrap = Wrap,
	remoteName = remoteName
}
