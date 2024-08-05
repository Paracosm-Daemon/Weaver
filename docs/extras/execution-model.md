---
sidebar_position: 1
---

# Execution Model

![Weaver's Execution Model](/extras-execution-model.png)

When [`WeaverService.Start()`](/api/WeaverService#Start) is called, all of the [WeaverServices](/api/WeaverServer#WeaverService) are instantiated internally, which includes [RemoteSignals](/api/RemoteSignal) and methods. This step does not happen on the client, rather, services are dynamically created when [`WeaverClient.GetService()`](/api/WeaverClient#GetService) is called.

Internally, all services' signals and their attributes are guaranteed to be ready when they are returned using [`WeaverClient.GetService()`](/api/WeaverClient#GetService). This is because they are created before WeaverInit, as other services may use or rely on a service's [RemoteSignals](/api/RemoteSignal) during WeaverInit or WeaverStart. This is the same for how [WeaverControllers](/api/WeaverClient#WeaverController) behave, just without creating instances.

:::caution

[WeaverServices](/api/WeaverServer#WeaverService) and [WeaverControllers](/api/WeaverClient#WeaverController) are unable to be created once their respective hosts have started Weaver.

:::
