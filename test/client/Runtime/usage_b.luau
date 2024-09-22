--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Controller
local Controller = Weaver.CreateController{ Name = "usage_b" }
function Controller:KnitStart(): ()
	local PostService = Weaver.GetService("PostService")
	PostService.SendMessage:Fire("Hello from the client!") -- That's all!
end
-- Main
return Controller