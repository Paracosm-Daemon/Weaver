---
sidebar_position: 1
---

# Services

[WeaverServices](/api/WeaverServer#WeaverService) are created through the [WeaverServer](/api/WeaverServer). Services are simply tables, which makes them able to be created in modules, rather than needing to all be created in the same script, which is why Weaver's structure works so well.

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

Alongside this, you're also free to add any other items to the service's table itself; the only restrictive table are the `Client` and `Attributes` tables. The `Client` table only accepts methods (or functions) and [RemoteSignal](/api/RemoteSignal) markers, which are created via [`WeaverServer.CreateRemoteSignal()`](/api/WeaverServer#CreateRemoteSignal) and [`WeaverServer.CreateUnreliableSignal()`](/api/WeaverServer#CreateUnreliableSignal).

```lua
local Service = Weaver.CreateService{
	Name = "Service";
	Client = {
		ImportantCall = Weaver.CreateRemoteSignal();
		GetSomething = function(self: WeaverExposed): string
			return "Something"
		end;
	};

	someSharedValue = 123;
	someOtherSharedValue = "hello";
	someSharedValues = { 1, 2, 3 };
}
```

Note that anything outside of the `Client` table is not exposed to any clients. This is to guarantee safety, and so you can control what clients are able to access. Usually, for formatting purposes, you may also want to define `Client` outside of [`WeaverServer.CreateService()`](/api/WeaverServer#CreateService).

```lua
local Service = Weaver.CreateService{ Name = "Service" }
Service.Client.SomeSignal = Weaver.CreateRemoteSignal()

function Service.Client:AddNumber(value: number): number
	return value + 2
end
```

When you first create a Weaver service, a few things will not be available:

* `WeaverService.Client` table will not be initialized until Weaver is started. Ditto for `WeaverService.Client.Server`, which is used to access the `Server` table from methods within the `Client` table.
* All [RemoteSignals](/api/RemoteSignal) will be markers. These markers are used to create remotes once Weaver starts, but they will not work or be available for use.
* All of `WeaverService`'s attribute methods will be unavailable, as Weaver needs to start to initialize the service, which then internally sets the attributes and exposes the functions.

See Weaver's [execution model](/docs/extras/execution-model) to understand how services are initialized.
