--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Service
local Module = Weaver.CreateController{ Name = script.Name }

function Module:WeaverInit(): ()
	print("foo")
end
function Module:WeaverStart(): ()
	print("bar")

	local TestService = Weaver.GetService("test_service")
	TestService.Foo:Connect(function(Result: string): ()
		print(Result)
		warn(TestService:Qux(17))
	end)
	TestService.Foo:Fire("baz")
end

return Module