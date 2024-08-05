---
sidebar_position: 1
---

# Execution Model

![Weaver's Execution Model](/extras-execution-model.png)

When [`WeaverService.Start()`](/api/WeaverService#Start) is called, all of the [WeaverServices](/api/WeaverServer#WeaverService) are instantiated internally, which includes [RemoteSignals](/api/RemoteSignal) and methods. This step does not happen on the client, rather, services are dynamically created when [`WeaverClient.GetService()`](/api/WeaverClient#GetService) is called.

Services are guaranteed to be fully constructed when they are returned using [`WeaverClient.GetService()`](/api/WeaverClient#GetService). This is because they are created before WeaverInit even starts, as other services may rely on a service's [RemoteSignals](/api/RemoteSIgnal) during WeaverInit. Ditto for how [WeaverControllers](/api/WeaverClient#WeaverController) behave, just without creating instances.
