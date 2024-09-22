--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Constants
local INTERCEPTION_VALUE: number = 4321
-- Main
local Start: number = os.clock()

Weaver.AddControllers(script.Runtime)
Weaver.Start{
	Services =
	{
		test_service =
		{
			Inbound = function(...): (boolean, ...any)
				warn("RECEIVED", ...)
				return true, ...
			end;
			Outbound =
			{
				function(Value: number): (boolean, number)
					print("OUTBOUND INTERCEPTED:", Value)
					if Value == 4 then
						return false, Value
					end
					return true, Value
				end;
				function(Value: number): (boolean, number)
					print(`SENDING { INTERCEPTION_VALUE } INSTEAD OF { Value }`)
					return true, INTERCEPTION_VALUE
				end;
			};
		};
	};
}

local Benchmark: number = os.clock() - Start
print(string.format("Client took %.2fms", 1_000. * Benchmark))