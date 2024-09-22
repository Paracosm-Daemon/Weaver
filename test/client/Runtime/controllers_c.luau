--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Controller
local Controller = Weaver.CreateController{ Name = "Controller" }
local OtherController -- Leave this uninitialized for now!

function Controller:WeaverInit(): ()
	OtherController = Weaver.GetController("OtherController")
end
function Controller:WeaverStart(): ()
	OtherController:DoSomething() -- This will work, since our controller was initialized in WeaverInit
end
-- Main
return Controller