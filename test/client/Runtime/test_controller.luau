--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Service
local Module = Weaver.CreateController{ Name = script.Name }
-- Functions
function Module:WeaverInit(): ()
	print("baz")
end
function Module:WeaverStart(): ()
	print("qux")

	local TestService = Weaver.GetService("test_service")
	TestService.Remote:Connect(function(Result: string): ()
		print("Server output", Result)
		warn(TestService:Frobulate(3))
	end)
	TestService.Remote:Fire("quux")
end
-- Main
return Module