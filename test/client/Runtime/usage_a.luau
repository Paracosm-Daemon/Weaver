--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Controller
local Controller = Weaver.CreateController{ Name = "usage_a" }
function Controller:WeaverStart(): ()
	-- Get PingService; it's almost like calling game:GetService()
	local PingService = Weaver.GetService("PingService")
	-- Start our game of ping-pong on the client
	print("Ping!")

	local pingStart: number = os.clock()
	-- Call PingService:Ping(), which will return "Pong!"
	local pongOutput: string = PingService:Ping()
	-- Calculate how long it took for the server to respond to our request
	local pongTime: number = os.clock() - pingStart
	warn(pongOutput, "took", pongTime) -- Pong! took 0.31758950000221375
end
-- Main
return Controller