--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Main
local Start: number = os.clock()

Weaver.AddControllers(script.Runtime)
Weaver.Start{
	Inbound =
	{
		function(...): (boolean, ...any)
			return true, ...
		end;
	};
	Services =
	{
		test_service =
		{
			Outbound =
			{
				function(...): (boolean, ...any)
					print("OUTBOUND INTERCEPTED:", ...)
					print("INSTEAD SENDING 4321")

					return true, 4321
				end;
			};
		};
	};
}

local Benchmark: number = os.clock() - Start
print(string.format("Client took %.2fms", 1_000. * Benchmark))