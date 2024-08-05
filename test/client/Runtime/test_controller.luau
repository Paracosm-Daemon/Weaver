--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- https://github.com/luau-lang/luau/issues/1357
local Signal = Weaver.Util.Signal
-- Service
local Module = Weaver.CreateController{ Name = script.Name }
Module.Test = Signal.new()
-- Functions
function Module:WeaverInit(): ()
	print("baz")

	local Thing: Weaver.SignalConnection
	Thing = self.Test:Connect(function(Input: string): ()
		warn(Input)
		Thing:Disconnect()
		task.wait(1)
		print(Thing.Connected)
	end)
	self.Test:Once(function(Input: string): ()
		print("ONCE CLIENT", Input)
	end)
	task.spawn(function(): ()
		print("WAIT CLIENT", self.Test:Wait())
	end)
end
function Module:WeaverStart(): ()
	print("qux")

	local TestService = Weaver.GetService("test_service")
	print(TestService:GetAttribute("hi"))

	TestService.Remote:Connect(function(Output: string): ()
		print("Server output", Output)

		local Bytes: { number } = { string.byte(Output, 1, #Output) }
		local Frobulations: number = 0

		for _, Byte: number in Bytes do
			Frobulations += Byte
		end
		warn(TestService:Frobulate(Frobulations))
	end)
	TestService.Remote:Once(function(Output: string): ()
		print("ONCE SERVER", Output)
		for _ = 1, 3, 1 do
			self.Test:Fire(Output)
		end
	end)
	task.spawn(function(): ()
		print("WAIT SERVER", TestService.Remote:Wait())
	end)
	TestService.Remote:Fire("quux")
end
-- Main
return Module