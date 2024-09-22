--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Service
-- This is being ran on the server
local PointsService = Weaver.CreateService{ Name = "PointsService" }

PointsService.Client.Points = 0 -- This is a RemoteProperty! Our starting points will be 0
PointsService.Client.AddPoints = Weaver.CreateRemoteSignal() -- Our signal to add more points

function PointsService:WeaverInit(): ()
	-- We'll be storing this as a variable
	-- so that we don't need to write self.Client.Points
	-- every time we want to access it
	local Points: any = self.Client.Points
	self.Client.AddPoints:Connect(function(Client: Player)
		-- This will add 10 points every time the client fires AddPoints
		Points:SetFor(Client, 10 + Points:GetFor(Client))
	end)
end
-- Main
return PointsService