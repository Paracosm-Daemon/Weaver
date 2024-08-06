--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
local Lock = require(ReplicatedStorage.Lock)
-- https://github.com/luau-lang/luau/issues/1357
local Signal = Weaver.Util.Signal
-- Constants
local EXPECTED_SIGNAL_INPUT: number = 123
local EXCEPTION_UNEXPECTED_SIGNAL: string = `Input is not { EXPECTED_SIGNAL_INPUT }! Got type %s with value %s`

local EXPECTED_ATTRIBUTE_NAME: string = "testAttribute"
local EXPECTED_ATTRIBUTE_VALUE: string = "foo"

local EXCEPTION_UNEXPECTED_ATTRIBUTE: string = `{ EXPECTED_ATTRIBUTE_NAME } is not { EXPECTED_ATTRIBUTE_VALUE }! Got type %s with value %s`

local EXPECTED_PROPERTY_VALUE: number = 0
local EXCEPTION_UNEXPECTED_PROPERTY: string = `TestProperty is not { EXPECTED_PROPERTY_VALUE }!`

local EXPECTED_REMOTE_VALUE: number = 4321
local EXCEPTION_UNEXPECTED_REMOTE: string = `Output is not { EXPECTED_REMOTE_VALUE }! Got type %s with value %s`
-- Service
local Module = Weaver.CreateController{ Name = script.Name }
Module.Test = Signal.new()
-- Variables
local Tester: Lock.Lock = Lock.new()
-- Functions
function Module:WeaverInit(): ()
	-- Hook Test signal
	Tester:Latch(function(Free): ()
		local Tries: number = 0
		self.Test:Connect(function(Input: number): ()
			assert(Input == EXPECTED_SIGNAL_INPUT, string.format(EXCEPTION_UNEXPECTED_SIGNAL, typeof(Input), tostring(Input)))
			Tries += 1

			if Tries == 2 then
				Free()
			end
		end)
	end, "Signal Connect")
	Tester:Latch(function(Free): ()
		local Connection: Weaver.SignalConnection
		local Tries: number = 0

		Connection = self.Test:Once(function(Input: number): ()
			assert(Input == EXPECTED_SIGNAL_INPUT, string.format(EXCEPTION_UNEXPECTED_SIGNAL, typeof(Input), tostring(Input)))
			Tries += 1

			assert(Tries == 1, `Once ran { Tries } times!`)
			task.defer(function(): ()
				assert(not Connection.Connected, "Once is still connected!")
				Free()
			end)
		end)
	end, "Signal Once")
	Tester:Latch(function(Free): ()
		local Input: number = self.Test:Wait()
		assert(Input == EXPECTED_SIGNAL_INPUT, string.format(EXCEPTION_UNEXPECTED_SIGNAL, typeof(Input), tostring(Input)))

		Free()
	end, "Signal Wait")
	-- Hook TestService remote
	Tester:Latch(function(FreeTree): ()
		local TestService = Weaver.GetService("test_service")
		Tester:Latch(function(Free): ()
			TestService.TestSignal:Once(function(Output: number): ()
				assert(Output == EXPECTED_REMOTE_VALUE, string.format(EXCEPTION_UNEXPECTED_REMOTE, typeof(Output), tostring(Output)))
				Free()
			end)
		end, "RemoteSignal Once")
		Tester:Latch(function(Free): ()
			TestService.TestSignal:Once(function(Output: number): ()
				assert(Output == EXPECTED_REMOTE_VALUE, string.format(EXCEPTION_UNEXPECTED_REMOTE, typeof(Output), tostring(Output)))
				Free()
			end)
		end, "RemoteSignal Once")
		Tester:Latch(function(Free): ()
			local Output: number = TestService.TestSignal:Wait()
			assert(Output == EXPECTED_REMOTE_VALUE, string.format(EXCEPTION_UNEXPECTED_REMOTE, typeof(Output), tostring(Output)))

			Free()
		end, "RemoteSignal Wait")
		FreeTree()
	end)
end
function Module:WeaverStart(): ()
	-- Fire Test signal
	Tester:Latch(function(Free): ()
		for _ = 1, 2, 1 do
			self.Test:Fire(EXPECTED_SIGNAL_INPUT)
		end
		Free()
	end, "Signal Fire")
	Tester:Latch(function(FreeTree): ()
		local TestService = Weaver.GetService("test_service")
		Tester:Latch(function(Free): ()
			assert(TestService:Frobulate(4) == 5, "Frobulation did not return 5!")
			Free()
		end, "Frobulate")
		Tester:Latch(function(Free): ()
			local Value: any? = TestService:GetAttribute(EXPECTED_ATTRIBUTE_NAME)
			assert(Value == EXPECTED_ATTRIBUTE_VALUE, string.format(EXCEPTION_UNEXPECTED_ATTRIBUTE, typeof(Value), tostring(Value)))
			Free()
		end, `{ EXPECTED_ATTRIBUTE_NAME } Get`)
		Tester:Latch(function(FreeBranch): ()
			assert(TestService.TestProperty:Get() == EXPECTED_PROPERTY_VALUE, EXCEPTION_UNEXPECTED_PROPERTY)
			Tester:Latch(function(Free): ()
				TestService.TestSignal:Fire(EXPECTED_REMOTE_VALUE)
				Free()
			end, "RemoteSignal Fire")
			FreeBranch()
		end, "RemoteProperty Get")
		FreeTree()
	end)
	Tester:Unlock()
end
-- Main
return Module