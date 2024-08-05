---
sidebar_position: 2
---

# Basic Usage

Since Weaver works in a [single-script architecture](https://medium.com/roblox-development/this-article-was-originally-published-in-them-magazines-de995382e352), it's best to start your projects off with it in mind. The most basic version of Weaver works by having one [Script](https://create.roblox.com/docs/reference/engine/classes/Script) in [ServerScriptService](https://create.roblox.com/docs/reference/engine/classes/ServerScriptService), and one [LocalScript](https://create.roblox.com/docs/reference/engine/classes/LocalScript) in [StarterPlayerScripts](https://create.roblox.com/docs/reference/engine/classes/StarterPlayerScripts), both starting Weaver using their respective [`WeaverService.Start()`](/api/WeaverServer#Start) and [`WeaverClient.Start()`](/api/WeaverClient#Start) methods. At the very least, both scripts should look like this:

```lua
local Weaver = require(Weaver) -- Weaver's actual path would likely be somewhere in ReplicatedStorage

Weaver.Start() -- Hooray, Weaver has started!
```

That is the _bare minimum_ that Weaver needs to run. However, this does not load any [WeaverServices](/api/WeaverServer#WeaverService) or [WeaverControllers](/api/WeaverClient#WeaverController). To do so, we need to create them.

## Basic Communication

Let's create a basic service on the server. It can be anything, but for this example, a simple "ping" service can work. Let's say that we want it to communicate with the client to play ping-pong. When a service is created via [`WeaverServer.CreateService()`](/api/WeaverService#CreateService), it will always have a Client table. There is more detail on how [`WeaverServices`](/api/WeaverServer#WeaverService) work in the [Communication tab](../communication/services).

```lua
-- This is being ran on the server
local Weaver = require(Weaver)
-- CreateService's parameter is a table,
-- and Name has to be specified as a string for it to be registered
local PingService = Weaver.CreateService{ Name = "PingService" }
-- Since this function is going to be shared with the client, specify it under the Client table
function PingService.Client:Ping(): string
	return "Pong!"
end
-- Finally, start Weaver after our service is created
Weaver.Start()
```

Then, on the client, you can get PingService using [`WeaverClient.GetService()`](/api/WeaverClient#GetService), and run `PingService:Ping()` to play ping-pong.

```lua
-- This is being ran on the client
local Weaver = require(Weaver)
-- Since Weaver needs to be started to get services and controllers,
-- it's done before we call Weaver.GetService()
Weaver.Start()
-- Get PingService; it's almost like calling game:GetService()
local PingService = Weaver.GetService("PingService")
-- Start our game of ping-pong on the client
print("Ping!")

local pingStart: number = os.clock()
-- Call PingService:Ping(), which will return "Pong!"
local pongOutput: string = PingService:Ping()
-- Calculate how long it took for the server to respond to our request
local pongTime: number = os.clock() - pingStart
warn(pongOutput, "took", pongTime) -- Pong! took 0.31758950000221375
```

Just like that, we've created a service to play ping-pong with. Under the hood, Weaver converts your function into a RemoteFunction, though it is handled as if it were a normal function on the client. If you find Weaver's i rnal structure while running your game, you can see how it's built:

![Ping in the Explorer tree](/usage-ping.png)

## Signals

Let's say that we want to use a [RemoteEvent](https://create.roblox.com/docs/reference/engine/classes/RemoteEvent) instead, and in this case, for posting a message via [MessagingService](https://create.roblox.com/docs/reference/engine/classes/MessagingService). We can use [`WeaverServer.CreateRemoteSignal()`](/api/WeaverServer#CreateRemoteSignal).

```lua
local MessagingService = game:GetService("MessagingService")
-- This will be the topic we post to
local POST_TOPIC: string = "GlobalMessages"
-- First, create PostService
local PostService = Weaver.CreateService{ Name = "PostService" }
-- Then, create the remote signal.
-- Trying to use it before Weaver has started will throw an exception
PostService.Client.SendMessage = Weaver.CreateRemoteSignal()
function PostService:WeaverInit(): ()
	-- We subscribe to POST_TOPIC in WeaverInit alongside SendMessage so it can be used on WeaverStart
	MessagingService:SubscribeAsync(POST_TOPIC, function(Message: { Payload: { Name: string, Message: string }, Sent: number }): ()
		print("Player", Payload.Name, "sent", Payload.Message)
	end)
	-- SendMessage will take a string
	self.Client.SendMessage:Connect(function(Client: Player, Message: string): ()
		-- Normally, you'd want to add sanity checks, but this is just an example
		MessagingService:PublishAsync(POST_TOPIC, {
			Name = Client.Name;
			Message = Message;
		})
	end)
end
```

Under the hood, this simply creates a RemoteEvent. This means that it will not yield when you fire SendMessage on the client.

Now, let's say that we want to call SendMessage from the client. All we need to do is call `SendMessage:Fire()`, as it gets registered as a [RemoteSignal](/api/RemoteSignal) when Weaver starts.

```lua
Weaver.Start()

local PostService = Weaver.GetService("PostService")
PostService.SendMessage:Fire("Hello from the client!") -- That's all!
```
