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
end
-- Main
return Controller