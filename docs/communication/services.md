---
sidebar_position: 1
---

# Services

[WeaverServices](/api/WeaverServer#WeaverService) are created through the [WeaverServer](/api/WeaverServer). Services are simply tables, which makes them able to be created in modules, rather than needing to all be created in the same script, which is why Weaver's structure works so well.

## Construction

When creating a service, the only key needed in the table is the `Name` property, like so:

```lua
local Service = Weaver.CreateService({ Name = "Service" })
```

If the extra parenthesis do not fit your coding style, you can also remove them:

```lua
local Service = Weaver.CreateService{ Name = "Service" }
```

Other values are also able to be specified in this initialization phase, such as the `Client` table. This table is what exposes certain methods or signals to the client. It's also possible to specify an `Attributes` table, which are directly tied to Roblox's [instance attributes](https://create.roblox.com/docs/studio/properties#instance-attributes).

```lua
local Service = Weaver.CreateService{
	Name = "Service";
	Attributes = {
		isService = true;
	};
	Client = {
		Shoot = Weaver.CreateRemoteSignal();
	};
}
```

Alongside this, you're also free to add any other items to the service's table itself; the only restrictive table are the `Client` and `Attributes` tables. The `Client` table accepts methods (or functions) and [RemoteSignal](/api/RemoteSignal) markers, which are created via [`WeaverServer.CreateRemoteSignal()`](/api/WeaverServer#CreateRemoteSignal) and [`WeaverServer.CreateUnreliableSignal()`](/api/WeaverServer#CreateUnreliableSignal). Any other type is classified as a [RemoteProperty](/api/RemoteProperty), and will be instantiated as one.

```lua
local Service = Weaver.CreateService{
	Name = "Service";
	Client = {
		ImportantCall = Weaver.CreateRemoteSignal();
		SomeProperty = 0;

		GetSomething = function(self: WeaverExposed): string
			return "Something"
		end;
	};

	someSharedValue = 123;
	someOtherSharedValue = "hello";
	someSharedValues = { 1, 2, 3 };
}
```

:::caution

The `Client` table is shallow, and all other tables inside of it will be converted into a [RemoteProperty](/api/RemoteProperty) once Weaver starts.

:::

## Signals

Let's say that we don't want to expose signals to the client, rather, we want to have an event that other services can listen to, like a [BindableEvent](https://create.roblox.com/docs/reference/engine/classes/BindableEvent). Weaver implements this through it's built-in class: [Signal](/api/Signal). You are able to create a Signal by using the module located at `Weaver.Util.Signal`. Unlike [RemoteSignals](/api/RemoteSignal), these are available as soon as you create them via [`Signal.new()`](/api/Signal#new).

First, we create our service, which handles our signal:

```lua
local Signal = Weaver.Util.Signal -- Util is a module, and Signal is already required!
local EventFiringService = Weaver.CreateService{
	Name = "EventFiringService";
	SomethingHappened = Signal.new();
}
function EventFiringService:WeaverStart(): ()
	-- Fire SomethingHappened in WeaverStart,
	-- as the connections from other services should be ready
	self.SomethingHappened:Fire()
end
```

Then, we create our service which uses this signal:

```lua
local EventHandlingService = Weaver.CreateService{ Name = "EventHandlingService" }
function EventHandlingService:WeaverInit(): ()
	-- First, we get the service
	local EventFiringService = Weaver.GetService("EventFiringService")
	-- Then, we connect an event to it
	EventFiringService.SomethingHappened:Connect(function(): ()
		print("Something happened!")
	end)
end
```

:::caution

Trying to add [Signals](/api/signal) to [`WeaverService.Client`](/api/WeaverServer#WeaverService) will not work. The signal will still exist, but it will not be accessible from `Client` once Weaver starts, as it cannot be exposed to the client.

:::

## Properties

Weaver also has support for [RemoteProperties](/api/RemoteProperty). These are properties which are set by the server, and passed to the client. These properties are also able to be different for every client, while still having a default value. This is great for services which may handle points or currency. As an example, here is a basic money service:

```lua
local MoneyService = Weaver.CreateService{ Name = "MoneyService" }
-- This will initialize as a RemoteProperty once Weaver is initialized
-- The value this is set to will be used as the default
MoneyService.Client.Money = 0
MoneyService.Client.AddMoney = Weaver.CreateRemoteSignal()

local Money -- This gets initialized in WeaverInit, so it can be used as a shorthand
-- This is in the server table, so this won't clash with the signal's name
function MoneyService:AddMoney(Client: Player, Amount: number): ()
	Money:SetFor(Client, Money:GetFor(Client) + Amount)
end
function MoneyService:WeaverInit(): ()
	-- Initialize our Money variable
	Money = self.Client.Money
	-- Hook our AddMoney signal to the AddMoney function aswell,
	-- so players can also give themselves money
	self.Client.AddMoney:Connect(function(Client: number, Amount: number): ()
		self:AddMoney(Client, Amount)
	end)
end
```

This service has a setup where both services and clients can add money to their own values, though you may not want to have a setup like this in production.

Similar logic can be used for something that relies on data; if your game uses [DataStores](https://create.roblox.com/docs/cloud-services/data-stores), you may want to set a client's value on a [RemoteProperty](/api/RemoteProperty) to their stored value once they load in. This value could be something like the number of kills a client has reached, or their current level and experience points. Do note that [RemoteProperties](/api/RemoteProperty) can have all data types that [RemoteEvents](https://create.roblox.com/docs/scripting/events/bindable#argument-limitations) support.

The methods, signals, properties, and attributes all have their own distinct uses. You should pick which one you want to use based on which is the mose optimal for your own use cases.

## Initialization

Trying to utilize services before Weaver has started will result in errors, especially when dealing with [RemoteSignals](/api/RemoteSignal). This is because Weaver needs to construct all of the services internally so that they are ready when WeaverInit and WeaverStart are called. This is because the client could have unexpected behavior dealing with services, as issues related to [race conditions](https://en.wikipedia.org/wiki/Race_condition) may cause certain signals to be missing, should services be initialized early.

Weaver's way of dealing with this is through two functions: WeaverInit and WeaverStart. As outlined in the [execution model](/extras/execution-model), all service objects are internally created and handled, then WeaverInit is called, followed by WeaverStart. These functions are declared by adding `Service:WeaverInit()` and `Service:WeaverStart()` to your service.

```lua
local MyMultiStepService = Weaver.CreateService{
	Name = "Service";
	Client = {
		SomeExposedSignal = Weaver.CreateRemoteSignal();
	};
}

function MyMultiStepService:WeaverInit(): ()
	print("Init", self.Name)
	-- Connect some events here...
	self.Client.SomeExposedSignal:Connect(function(client: Player): ()
		warn(client, "fired my exposed signal!")
	end)
end
function MyMultiStepService:WeaverStart(): ()
	print("Start", self.Name)
	-- Fire some events or execute some functions here...
	local SomeOtherService = Weaver.GetService("SomeOtherService")
	SomeOtherService.SomeSignal:Fire(123)
end

-- Output:
-- Init Service
-- Start Service
```

As seen above, WeaverInit will always be called before WeaverStart. This goes for all services that you create for your [WeaverServer](/api/WeaverServer#CreateService). The best practice is to connect handlers for [Signals](/api/Signal), [RemoteSignals](/api/RemoteSignal), or other [RBXScriptSignals](https://create.roblox.com/docs/reference/engine/datatypes/RBXScriptSignal) in WeaverInit, and then execute functions or handle things that update based on the task scheduler — i.e [RunService.PostSimulation](https://create.roblox.com/docs/reference/engine/classes/RunService#PostSimulation) — in WeaverStart. This helps to prevent race conditions from occuring, where you may fire a signal before its handler is connected.

Note that anything outside of the `Client` table is not exposed to any clients. This is to guarantee safety as you can control what clients are able to access. Usually, for formatting purposes, you may also want to define `Client` outside of [`WeaverServer.CreateService()`](/api/WeaverServer#CreateService).

```lua
local Service = Weaver.CreateService{ Name = "Service" }
Service.Client.SomeSignal = Weaver.CreateRemoteSignal()

function Service.Client:IncrementNumber(value: number): number
	return value + 1
end
```

If you have ModuleScripts for every [WeaverService](/api/WeaverServer#WeaverService), you are also able to use [`WeaverServer.AddServices()`](/api/WeaverServer#AddServices) to add all of your services in bulk. This makes it easy to load all of your services at once, and it's especially useful if all of your services are in one location.

```lua
local Weaver = require(Weaver)

Weaver.AddServices(script.Runtime) -- Just an example of a directory to store your services in
Weaver.Start()
```

## Caveats

When you first create a Weaver service, a few things will not be available:

* [`WeaverService.Client`](/api/WeaverServer#WeaverService) will not be initialized until Weaver is started, meaning all [RemoteSignals](/api/RemoteSignal) will still be markers, and all [RemoteProperties](/api/RemoteProperty) will only be the values that you put in the `Client` table.
* `Client.Server`, which is used to access the `Server` table from methods within the `Client` table, will also not be initialized until Weaver has started.
* All of `WeaverService`'s attribute methods will be unavailable, as Weaver needs to start to initialize the service, which then internally sets the attributes and exposes the functions.

See Weaver's [execution model](/docs/extras/execution-model) to understand how services are initialized.
