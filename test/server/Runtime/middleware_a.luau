--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Service
local senders: { [Player]: number } = {}
local NetworkService = Weaver.CreateService{
	Name = "NetworkService";
	Client =
	{
		-- This will be a receiver for our middleware
		Receiver = Weaver.CreateRemoteSignal();
	};
	-- Middleware can also be specified outside of CreateService.
	-- This allows for use of the service table in your inbound functions
	Middleware =
	{
		Inbound =
		{
			-- First, we check for the last time this client sent a packet
			function(client: Player, ...): (boolean, ...any)
				local currentTime: number = os.clock()
				local lastSent: number? = senders[client]

				if lastSent and ((currentTime - lastSent) < 0.5) then
					warn(client, "is being rate limited!")
					return false
				end
				-- In practice, you may want to remove client from the senders dictionary
				-- when they leave via Players.PlayerRemoving
				senders[client] = currentTime
				return true, ...
			end;
			-- Then, we filter the request to make sure we've received a buffer
			function(client: Player, ...): (boolean, buffer?)
				-- This will simply just use the first argument in ...;
				-- essentially select(1, ...)
				local packet: any? = ...
				if typeof(packet) == "buffer" then
					return true, packet
				end
				warn(client, "tried to send a bad buffer!")
				return false
			end;
			-- After this, it's sent to the receiver!
		}
	};
}

function NetworkService:WeaverInit(): ()
	-- Our packet is guaranteed to either be a buffer or nil, due to our inbound middleware
	self.Client.Receiver:Connect(function(client: Player, packet: buffer?): ()
		-- First, check if it's null
		if not packet then
			warn(client, "sent invalid data!")
			return
		end
		-- If it isn't, we have a valid packet and can carry on with it
		-- ...
	end)
end
-- Main
return NetworkService