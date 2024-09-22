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
		NetworkService =
		{
			-- Our outbound request will be converted into a buffer!
			-- For simplicity, let's just say that this only accepts 16-bit integers
			Outbound = function(...): (boolean, buffer)
				warn("NETWROKSERVICE", ...)
				local arguments: { any } = { ... }
				-- We create our packet
				-- A 16-bit integer is 2 bytes, so we multiply 2 by our argument count
				local packet: buffer = buffer.create(2 * #arguments)
				for index: number, argument: any in arguments do
					-- Assertion to make sure our arguments are indeed numbers
					assert(
						typeof(argument) == "number",
						string.format(
							"The specified argument at index %i is not a number! got %*",
							index,
							argument
						)
					)
					-- Then, we write our number
					buffer.writei16(
						packet,
						argument,
						-- Buffers start at 0, so subtract 1 from index,
						-- then account for the 16-bit integer size in bytes
						2 * (index - 1)
					)
				end
				return true, packet
			end;
		};
	};
}

local Benchmark: number = os.clock() - Start
print(string.format("Client took %.2fms", 1_000. * Benchmark))