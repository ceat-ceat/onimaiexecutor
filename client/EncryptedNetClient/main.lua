local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local ECC = require("EllipticCurveCryptography")

local HandshakeRemote = Players.LocalPlayer:WaitForChild("Handshake")

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
