---
sidebar_position: 1
---

# Execution Model

## Lifecycle

Weaver's execution model is simple yet orderly, ensuring all controllers and services will be ready as soon as their respective hosts start Weaver.

1. Weaver is required
2. [WeaverServices](/api/WeaverServer#WeaverService) and [WeaverControllers](/api/WeaverClient#WeaverController) are created
3. [`WeaverServer.Start()`](/api/WeaverServer#Start) and [`WeaverClient.Start()`](/api/WeaverClient#Start) respectively are called
	1. Weaver internally constructs the services when [`WeaverServer.Start()`](/api/WeaverServer#Start) is called
4. Every `WeaverInit` method is invoked
	1. Weaver waits for all respective [`WeaverService:WeaverInit()`](/api/WeaverServer#WeaverService) and [`WeaverController:WeaverInit()`](/api/WeaverClient#WeaverController) methods to resolve before continuing to the next step
5. Every `WeaverStart` method is invoked, spawning new threads for all services and controllers
6. All threads yielding from [`WeaverServer.OnStart()`](/api/WeaverServer#OnStart) and [`WeaverClient.OnStart()`](/api/WeaverClient#OnStart) respectfully are resumed

![Weaver's Execution Model](/extras-execution-model.svg)

## Explanation

When [`WeaverServer.Start()`](/api/WeaverServer#Start) is called, all of the [WeaverServices](/api/WeaverServer#WeaverService) are instantiated internally, which includes [RemoteSignals](/api/RemoteSignal) and methods. This step does not happen on the client, rather, services are dynamically created when [`WeaverClient.GetService()`](/api/WeaverClient#GetService) is called.

Internally, all services' signals and their attributes are guaranteed to be ready when they are returned using [`WeaverClient.GetService()`](/api/WeaverClient#GetService). This is because they are created before WeaverInit, as other services may use or rely on a service's [RemoteSignals](/api/RemoteSignal) during WeaverInit or WeaverStart. This is the same for how [WeaverControllers](/api/WeaverClient#WeaverController) behave, just without creating instances.

:::caution

[WeaverServices](/api/WeaverServer#WeaverService) and [WeaverControllers](/api/WeaverClient#WeaverController) are unable to be created once their respective hosts have started Weaver.

:::

## Best Practice

When using Weaver, your project structure should generally follow these rules:

* One script on the server manages the [WeaverServer](/api/WeaverServer)
	* This means that all service modules should be used in one script, alongside [`WeaverServer.Start()`](/api/WeaverServer#Start)
* One script on the client manages the [WeaverClient](/api/WeaverClient)
	* This means that all controller modules should be used in one script, alongside [`WeaverClient.Start()`](/api/WeaverClient#Start)

This is to enforce the [single-script architecture](https://medium.com/roblox-development/this-article-was-originally-published-in-them-magazines-de995382e352) that Weaver uses, as Weaver will not work correctly if your project uses a multi-script architecture.
