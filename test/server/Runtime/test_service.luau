--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
local Lock = require(ReplicatedStorage.Lock)
-- Constants
local EXPECTED_ATTRIBUTE_NAME: string = "TestAttribute"
local EXPECTED_ATTRIBUTE_VALUE: string = "foo"

local EXCEPTION_UNEXPECTED_ATTRIBUTE: string = `{ EXPECTED_ATTRIBUTE_NAME } is not { EXPECTED_ATTRIBUTE_VALUE }! Got type %s with value %s`
local EXCEPTION_PARAM_ERROR: string = "Param %d of %s is not %s! Got type %s with value %s"

local EXCEPTION_UNEXPECTED_PROPERTY: string = "TestProperty value for %s is not %s! Got type %s with value %s"
local DEFAULT_PROPERTY_VALUE: number = 0
-- Service
local Module = Weaver.CreateService{ Name = script.Name }
-- Variables
local Tester: Lock.Lock = Lock.new()

Module.Client.TestSignal = Weaver.CreateRemoteSignal()
Module.Client.TestProperty = DEFAULT_PROPERTY_VALUE

Module.Attributes.TestAttribute = "foo"
-- Functions
-- Client
function Module.Client:Frobulate(Client: Player, Frobulations: number): number
	assert(Client:IsA("Player"), string.format(EXCEPTION_PARAM_ERROR, 1, "Frobulate", "Player", typeof(Client), tostring(Client)))

	local Type: string = typeof(Frobulations)
	assert(Type == "number", string.format(EXCEPTION_PARAM_ERROR, 2, "Frobulate", "number", Type, tostring(Frobulations)))

	return self.Server:Frobulate(Frobulations)
end
-- Server
function Module:Frobulate(Frobulations: number): number
	return 1 + Frobulations
end

function Module:WeaverInit(): ()
	Tester:Latch(function(Free): ()
		local Value: any? = self:GetAttribute(EXPECTED_ATTRIBUTE_NAME)
		assert(Value == EXPECTED_ATTRIBUTE_VALUE, string.format(EXCEPTION_UNEXPECTED_ATTRIBUTE, typeof(Value), tostring(Value)))

		Free()
	end, `{ EXPECTED_ATTRIBUTE_NAME } Get`)
	if not RunService:IsRunMode() then
		Tester:Latch(function(Free): ()
			self.Client.TestSignal:Connect(function(Client: Player, Input: number): ()
				assert(Client:IsA("Player"), string.format(EXCEPTION_PARAM_ERROR, 1, "TestSignal", "Player", typeof(Client), tostring(Client)))

				local Type: string = typeof(Input)
				assert(Type == "number", string.format(EXCEPTION_PARAM_ERROR, 2, "TestSignal", "number", Type, tostring(Input)))

				self.Client.TestSignal:Fire(Client, 4321)
				Free()
			end)
		end, "RemoteSignal Connect")
		Tester:Latch(function(FreeBranch): ()
			local Tries: number = 0
			self.Client.TestSignal:Once(function(Client: Player, Input: number): ()
				Tries += 1

				assert(Tries == 1, `Once ran { Tries } times!`)
				assert(Client:IsA("Player"), string.format(EXCEPTION_PARAM_ERROR, 1, "TestSignal", "Player", typeof(Client), tostring(Client)))

				local Type: string = typeof(Input)
				assert(Type == "number", string.format(EXCEPTION_PARAM_ERROR, 2, "TestSignal", "number", Type, tostring(Input)))

				Tester:Latch(function(Free): ()
					self.Client.TestProperty:SetFor(Client, nil)

					local Value: any? = self.Client.TestProperty:GetFor(Client)
					assert(Value == nil, string.format(EXCEPTION_UNEXPECTED_PROPERTY, Client.Name, "null", typeof(Value), tostring(Value)))

					Free()
				end, "RemoteProperty SetFor NULL")
				Tester:Latch(function(Free): ()
					self.Client.TestProperty:SetFor(Client, Input)

					local Value: any? = self.Client.TestProperty:GetFor(Client)
					assert(Value == Input, string.format(EXCEPTION_UNEXPECTED_PROPERTY, Client.Name, Input, typeof(Value), tostring(Value)))

					Free()
				end, "RemoteProperty SetFor Value")
				Tester:Latch(function(Free): ()
					self.Client.TestProperty:Clear()
					assert(self.Client.TestProperty:GetFor(Client) == DEFAULT_PROPERTY_VALUE, `TestProperty value for { Client } is not { DEFAULT_PROPERTY_VALUE }!`)

					Free()
				end, "RemoteProperty Clear")
				FreeBranch()
			end)
		end, "RemoteSignal Once")
		Tester:Latch(function(Free): ()
			local Client: Player, Input: number = self.Client.TestSignal:Wait()
			assert(Client:IsA("Player"), string.format(EXCEPTION_PARAM_ERROR, 1, "TestSignal", "Player", typeof(Client), tostring(Client)))

			local Type: string = typeof(Input)
			assert(Type == "number", string.format(EXCEPTION_PARAM_ERROR, 2, "TestSignal", "number", Type, tostring(Input)))

			Free()
		end, "RemoteSignal Wait")
	end
end
function Module:WeaverStart(): ()
	Tester:Unlock()
end
-- Main
return Module