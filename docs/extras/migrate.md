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
