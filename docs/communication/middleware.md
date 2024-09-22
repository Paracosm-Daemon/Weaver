---
sidebar_position: 3
---

# Middleware

Weaver has support for [middleware](https://en.wikipedia.org/wiki/Middleware) due to how its networking is implemented. This allows for any data sent to the server, or to the client, to be passed through a transformation layer where the resulting data is then sent/received.

Common uses for middleware are intercepting network traffic, such as verifying client packets or simply logging any data that signals or methods receive. Here is an example of middleware which logs any traffic going to and from the server:

```lua
Weaver.Start{
	Middleware = {
		Inbound = function(client: Player, ...): (boolean, ...any)
			print(client, "sent the following arguments to the server:", ...)
			return true, ...
		end;
		Outbound = function(client: Player, ...): (boolean, ...any)
			print("The server sent", client, "the following arguments:" ...)
			return true, ...
		end;
	}
}
```

Weaver also allows for as many inbound/outbound functions as needed. By specifying a table rather than a single function to either layer, you can transform the arguments further. This is also where the first value is important, as it specifies whether it should continue the chain of middleware.

Here is an example of middleware being used to verify a packet sent by clients via [`workspace:GetServerTimeNow()`](https://create.roblox.com/docs/reference/engine/classes/Workspace#GetServerTimeNow). Note that Weaver also runs middleware from first-to-last.

```lua
Weaver.Start{
	Middleware = {
		Inbound =
		{
			function(client: Player, sentAt: number, ...): (boolean, boolean, ...any)
				local currentTime: number = workspace:GetServerTimeNow()
				if (currentTime - sentAt) > (0.1 + client:GetNetworkPing()) then
					warn(client, "sent a packet that was delayed!")
					-- This discontinues the chain,
					-- also sending false plus an error message
					return false, false, "Delayed packet!"
				end
				-- This continues the chain,
				-- passing through all data that the client sent through
				return true, ...
			end;
			function(client: Player, ...): (boolean, boolean, ...any)
				print(client, "sent the following data:", ...)
				-- This continues the chain,
				-- sending a second true to indicate that this was a successful invocation,
				-- also chaining on the arguments sent by the client
				return true, true, ...
			end;
		};
	}
}
```

## Services

Services can also have their own middleware specified. **This will override the global middleware set in the [WeaverServer](/api/WeaverServer) handler**. Let's say that we have a service dedicated to handling packets sent by clients to the server. Here's how the service may look:

```lua
local senders: { [Player]: number } = {}
local NetworkService = Weaver.CreateService{
	Name = "NetworkService";
	Client =
	{
		-- This will be a receiver for our middleware
		Receiver = Weaver.CreateRemoteSignal();
	};
	-- Middleware can also be specified outside of CreateService.
	-- This allows for use of the service table in your inbound functions
	Middleware =
	{
		Inbound =
		{
			-- First, we check for the last time this client sent a packet
			function(client: Player, ...): (boolean, ...any)
				local currentTime: number = os.clock()
				local lastSent: number? = senders[client]

				if lastSent and ((currentTime - lastSent) < 0.5) then
					warn(client, "is being rate limited!")
					return false
				end
				-- In practice, you may want to remove client from the senders dictionary
				-- when they leave via Players.PlayerRemoving
				senders[client] = currentTime
				return true, ...
			end;
			-- Then, we filter the request to make sure we've received a buffer
			function(client: Player, ...): (boolean, buffer?)
				-- This will simply just use the first argument in ...;
				-- essentially select(1, ...)
				local packet: any? = ...
				if typeof(packet) == "buffer" then
					return true, packet
				end
				warn(client, "tried to send a bad buffer!")
				return false
			end;
			-- After this, it's sent to the receiver!
		}
	};
}

function NetworkService:WeaverInit(): ()
	-- Our packet is guaranteed to either be a buffer or nil, due to our inbound middleware
	self.Client.Receiver:Connect(function(client: Player, packet: buffer?): ()
		-- First, check if it's null
		if not packet then
			warn(client, "sent invalid data!")
			return
		end
		-- If it isn't, we have a valid packet and can carry on with it
		-- ...
	end)
end
```

This applies Weaver's middleware in a way where a service will only accept data from clients when it's in the form of a [buffer](https://create.roblox.com/docs/reference/engine/libraries/buffer), alongside rate limiting clients to make sure they aren't sending requests too fast. This is only one of the many use cases for middleware.

## Controllers

Middleware can also be specified for services within controllers. Do note that the middleware table may only be specified within the [WeaverClient](/api/WeaverClient) handler.

If we wanted to handle outbound requests to our supposed NetworkService, we could do the following in our handler:

```lua
local Weaver = require(Weaver)

Weaver.AddControllers(script.Runtime)
Weaver.Start{
	Middleware =
	{
		Services =
		{
			NetworkService =
			{
				-- Our outbound request will be converted into a buffer!
				-- For simplicity, let's just say that this only accepts 16-bit integers
				Outbound = function(...): (boolean, buffer)
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
	};
}
```

Note that adding middleware to specific services will also override the global inbound/outbound middleware set by the [WeaverClient](/api/WeaverClient) handler.
