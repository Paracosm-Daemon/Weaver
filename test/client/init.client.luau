--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Main
local Start: number = os.clock()

Weaver.AddControllers(script.Runtime)
Weaver.Start{
	Services =
	{
		test_service =
		{
			Inbound =
			{
				function(...): (boolean, ...any)
					warn("RECEIVED", ...)
					return true, ...
				end;
			};
			Outbound =
			{
				function(Value: number): (boolean, number)
					print("OUTBOUND INTERCEPTED:", Value)
					if Value == 4 then
						return true, Value
					end

					print("INSTEAD SENDING 4321")
					return true, 4321
				end;
			};
		};
	};
}

local Benchmark: number = os.clock() - Start
print(string.format("Client took %.2fms", 1_000. * Benchmark))