---
sidebar_position: 1
---

# Introduction

Weaver is a fast, lightweight game framework meant for simple yet seamless communication between the server and the client. Weaver adheres by a single-script architecture, with a setup for the creation of services and controllers, allowing quick and painless communication from script-to-script without the need of BindableEvents/Functions.

Weaver is based off of the archived framework [Knit](https://github.com/Sleitnick/Knit). The structure that Weaver has is identical to Knit, making migration a simple process. If you're interested in migrating, take a look at the [migration guide](extras/migrate).

If you feel like Weaver is the framework for you, read about [getting started here](getting-started/installation).

## Why Weaver?

### Reliability

Since Weaver's structure is built around a single-script architecture, your code is guaranteed to run in an order you can easily manage. [WeaverServices](/api/WeaverServer#WeaverService) and [WeaverControllers](/api/WeaverClient#WeaverController) will always be ready on WeaverInit, and fully initialized on WeaverStart. You can also read more about Weaver's [execution model](extras/execution-model).

### Infrastructure

Weaver allows for a simpler way of networking between the server and client. You don't need to add [RemoteEvents](https://create.roblox.com/docs/reference/engine/classes/RemoteEvent) or [RemoteFunctions](https://create.roblox.com/docs/reference/engine/classes/RemoteFunction) to your game's hierarchy at all; Weaver automatically bridges the gap between the server and the client with custom-made and typed implementations of these classes.

### Accessibility

Weaver is greatly accessible - from grabbing the module via Roblox's Creator Store to using it as a package in Wally, installation is straightforward and made to fit your workflow. And, once it is added to your project, using it is simple; all you need to do is [`require`](https://create.roblox.com/docs/reference/engine/globals/RobloxGlobals#require) Weaver. You can read more about [using Weaver here](getting-started/usage).

### Adaptability

Since Weaver is under the [MIT license](https://github.com/Paracosm-Daemon/Weaver/blob/main/LICENSE), you're always free to [fork the source code](https://github.com/Paracosm-Daemon/Weaver/fork), fix or add features by [making a pull request](https://github.com/Paracosm-Daemon/Weaver/pulls), or even modify and distribute your own version of the framework. Weaver will always be open source and mendable to your liking; all contributions towards improving the framework are greatly appreciated.
