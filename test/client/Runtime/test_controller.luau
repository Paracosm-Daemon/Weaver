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

		local Bytes: { number } = { string.byte(Result, 1, #Result) }
		local Frobulations: number = 0

		for _, Byte: number in Bytes do
			Frobulations += Byte
		end
		warn(TestService:Frobulate(Frobulations))
	end)
	TestService.Remote:Fire("quux")
end
-- Main
return Module