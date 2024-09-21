--!strict
--[[
	Using GetPlayers() constantly can be expensive,
	so I've implemented connections to store all clients
]]--
-- Module
local Clients = {}
-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
-- Main
if RunService:IsServer() then
	Clients.Array = Players:GetPlayers() :: { Player }
	Clients.Connected = #Clients.Array

	Clients.Map = {} :: { [Player]: number }
	Players.PlayerRemoving:Connect(function(Client: Player): ()
		local Index: number? = Clients.Map[Client]
		if not Index then
			return
		end
		Clients.Map[Client] = nil
		-- Shifting operation
		if Clients.Connected == 1 then
			Clients.Connected = 0
			table.clear(Clients.Array)

			return
		end

		local Source: { Player } = {}
		if Index ~= 1 then
			table.move(Clients.Array, 1, Index - 1, 1, Source)
		end

		table.move(Clients.Array, 1 + Index, Clients.Connected, Index, Source)
		Clients.Connected -= 1
	end)
	Players.PlayerAdded:Connect(function(Client: Player): ()
		local Connected: number = 1 + Clients.Connected
		Clients.Connected = Connected

		Clients.Array[Connected] = Client
		Clients.Map[Client] = Connected
	end)

	for Index: number, Client: Player in Clients.Array do
		Clients.Map[Client] = Index
	end
end
return Clients