--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Service
-- This is being ran on the server
-- CreateService's parameter is a table,
-- and Name has to be specified as a string for it to be registered
local PingService = Weaver.CreateService{ Name = "PingService" }
-- Since this method is going to be shared with the client, specify it under the Client table
function PingService.Client:Ping(): string
	return "Pong!"
end
-- Main
return PingService