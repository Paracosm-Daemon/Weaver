---
sidebar_position: 2
---

# Migration from Knit

Generally, porting your code from Knit to Weaver should be simple, as the API is functionally similar. The only functions that may need to change are [`Knit.Start()`](https://sleitnick.github.io/Knit/api/KnitServer#Start) and [`Knit.OnStart()`](https://sleitnick.github.io/Knit/api/KnitServer#OnStart); since Weaver doesn't use Promises, you may need to implement that yourself, or slightly modify your scripts.

## Runners

```lua
local Knit = require(Knit)

Knit.AddServices(script.Runtime)
Knit.Start():andThen(function(): ()
	print("Knit has started!")
end):catch(warn)
```

This is a simple Knit service runner which relies on the use of Promises to handle errors and run code after Knit successfully starts. This behavior can be ported into Weaver in multiple ways. The easiest and most familiar way to port this is by using the [Promise](https://eryn.io/roblox-lua-promise/) library by evaera.

```lua
local Promise = require(Promise)
local Weaver = require(Weaver)

Weaver.AddServices(script.Runtime)
Promise.try(Weaver.start):andThen(function(): ()
	print("Weaver has started!")
end):catch(warn)
```

If you use the Promise library already, this should be easy to implement in your own code. Otherwise, an easier way is to use [`xpcall`](https://create.roblox.com/docs/reference/engine/globals/LuaGlobals#xpcall):

```lua
local Weaver = require(Weaver)
Weaver.AddServices(script.Runtime)
-- Since xpcall yields, any code will be ran after this
-- Think of this as Promise:await()
xpcall(function(): ()
	Weaver.Start()
	print("Weaver has started!")
end, warn)
```

You can also wrap the [`xpcall`](https://create.roblox.com/docs/reference/engine/globals/LuaGlobals#xpcall) in a [`task.spawn`](https://create.roblox.com/docs/reference/engine/libraries/task#spawn) thread to replicate the new thread that Promises spawn, rather than the yielding behavior:

```lua
local Weaver = require(Weaver)
Weaver.AddServices(script.Runtime)
-- This is functionally the same as Promise.try
task.spawn(xpcall, function(): ()
	Weaver.Start()
	print("Weaver has started!")
end, warn)
```

This way of error handling also goes for [`Weaver.OnStart()`](/api/WeaverServer#OnStart).

## Networking

The equivalent to [`Knit.CreateSignal()`](https://sleitnick.github.io/Knit/api/KnitServer#CreateSignal) in Weaver is [`WeaverServer.CreateRemoteSignal()`](/api/WeaverServer#CreateRemoteSignal). They are functionally the same, but named differently. In Studio, or if you use an IDE, using the shortcut `CTRL + SHIFT + H` should open a "Search and Replace" menu for all scripts in your project. You can easily replace all mentions of `CreateSignal` with `CreateRemoteSignal` this way. Ditto for replacing mentions of Knit with Weaver.

The class that was majorly overhauled was [RemoteProperty](/api/RemoteProperty). While most of the API is the same, there is no `RemoteProperty:Observe()`, unlike [Knit's version](https://sleitnick.github.io/RbxUtil/api/ClientRemoteProperty#Observe). It was instead replaced with the [`RemoteProperty.Changed`](/api/RemoteProperty#Changed) signal, which does not fire when the value for the client has loaded. There is also no substitute to [`Knit.CreateProperty()`](https://sleitnick.github.io/Knit/api/KnitServer#CreateProperty), rather, any values you set in your `Client` table aside from the remote signal markers will be converted into [RemoteProperties](/api/RemoteProperty).

Here's an example of how you would make a [RemoteProperty](https://sleitnick.github.io/RbxUtil/api/RemoteProperty) in Knit:

```lua
local Service = Knit.CreateService{ Name = "Service" }
Service.Client.RemoteProperty = Knit.CreateProperty(0)
```

In Weaver, the constructor has been changed to this:

```lua
local Service = Weaver.CreateService{ Name = "Service" }
Service.Client.RemoteProperty = 0
```

Due to this, you are not able to initialize properties with a value of `nil` in Weaver. This has instead been substituted with the [`WeaverService.CreateEmptyProperty()`](/api/WeaverServer#CreateEmptyProperty) function:

```lua
local Service = Weaver.CreateService{ Name = "Service" }
Service.Client.RemoteProperty = Weaver.CreateEmptyProperty()
```

Generally, the API for [RemoteProperties](/api/RemoteProperty) is not too different outside of the [`RemoteProperty.Changed`](/api/RemoteProperty#Changed) signal. Do note that [`RemoteProperty:SetTop()`](https://sleitnick.github.io/RbxUtil/api/RemoteProperty#SetTop), [`RemoteProperty:SetForList()`](https://sleitnick.github.io/RbxUtil/api/RemoteProperty#SetForList), and [`RemoteProperty:ClearForList()`](https://sleitnick.github.io/RbxUtil/api/RemoteProperty#ClearForList) have been renamed to [`RemoteProperty:SetDefault()`](/api/RemoteProperty#SetDefault), [`RemoteProperty:SetForEach()`](/api/RemoteProperty#SetForEach), and [`RemoteProperty:ClearForEach()`](/api/RemoteProperty#ClearForEach) respectively. Extra quality-of-life methods have also been added, which you can see in Weaver's [RemoteProperty API reference](/api/RemoteProperty).

[Middleware](/docs/communication/middleware) has slightly different naming compared to Knit, with [PerServiceMiddleware](https://sleitnick.github.io/Knit/api/KnitClient#PerServiceMiddleware) being renamed to Services within the [`WeaverClient.Start()`](/api/WeaverClient#Start) middleware table. Server middleware also does not receive its arguments as a table, though this behavior is easily replicable:

```lua
WeaverServer.Start{
	Middleware = {
		Inbound = function(client: Player, ...): (boolean, ...any)
			local length: number = select("#", ...)
			-- Here you can also use table.pack(),
			-- though note that it adds "n" which makes the above length variable unnecessary
			local arguments: { any } = { ... }
			return true, table.unpack(arguments, 1, length)
		end;
	};
}
```

Weaver also does not pass through the `Continue` boolean. This is done to keep the backend consistent, though you can add your own return value to specify if all of your inbound/outbound functions have passed.
