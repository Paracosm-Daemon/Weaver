--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Controller
local Controller = Weaver.CreateController{ Name = "NetworkController" }
function Controller:WeaverStart(): ()
	local NetworkService = Weaver.GetService("NetworkService")

	NetworkService.Receiver:Fire(1, 2, 3, 4)
	NetworkService.Receiver:Fire(5, 6, 7, 8)

	task.wait(1.)
	NetworkService.Receiver:Fire(9, 10, 11, 12)
end
-- Main
return Controller