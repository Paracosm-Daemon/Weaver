--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Controller
local Controller = Weaver.CreateController{ Name = "OtherController" }
function Controller:DoSomething(): ()
	return
end
-- Main
return Controller