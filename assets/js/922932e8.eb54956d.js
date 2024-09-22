"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[747],{18182:e=>{e.exports=JSON.parse('{"functions":[{"name":"Start","desc":"Starts Weaver.\\n\\nIf any middleware is provided, it will be used as as the default if no services have their own within the optional `Services` table.\\n\\n:::caution\\n\\nThis will throw an error if Weaver is already started.\\n\\n:::","params":[{"name":"Middleware","desc":"","lua_type":"{ Inbound: WeaverMiddleware?, Outbound: WeaverMiddleware?, Services: { [string]: { Inbound: WeaverMiddleware?, Outbound: WeaverMiddleware? } }? }?"}],"returns":[],"function_type":"static","yields":true,"source":{"line":186,"path":"src/Client.luau"}},{"name":"OnStart","desc":"Yields until Weaver has started. Useful for external modules that are not ran as controllers.\\n\\nIf Weaver has already started, this will not yield.","params":[],"returns":[],"function_type":"static","yields":true,"source":{"line":263,"path":"src/Client.luau"}},{"name":"GetService","desc":"Returns the [WeaverService](WeaverClient#WeaverService) found from the server.\\n\\nThis will yield until a service matching the name is found.","params":[{"name":"Name","desc":"","lua_type":"string"}],"returns":[{"desc":"","lua_type":"WeaverService"}],"function_type":"static","yields":true,"source":{"line":283,"path":"src/Client.luau"}},{"name":"GetController","desc":"If the `Name` is used for a controller, returns the [WeaverController] from the server.\\n\\n:::caution\\n\\nThis will throw an error if Weaver has not started, or if `Name` is not used for a controller.\\n\\n:::","params":[{"name":"Name","desc":"","lua_type":"string"}],"returns":[{"desc":"","lua_type":"WeaverController"}],"function_type":"static","source":{"line":395,"path":"src/Client.luau"}},{"name":"GetControllers","desc":"Returns all [WeaverController]s added.\\n\\n:::caution\\n\\nThis will throw an error if Weaver has not started.\\n\\n:::","params":[],"returns":[{"desc":"","lua_type":"{ [string]: WeaverController }"}],"function_type":"static","source":{"line":415,"path":"src/Client.luau"}},{"name":"CreateController","desc":"Creates and adds a [WeaverController] before Weaver has started.\\n\\n:::caution\\n\\nThis will throw an error if Weaver has started.\\n\\n:::","params":[{"name":"Controller","desc":"","lua_type":"WeaverController"}],"returns":[{"desc":"","lua_type":"WeaverController"}],"function_type":"static","source":{"line":431,"path":"src/Client.luau"}},{"name":"AddControllers","desc":"Adds all services from Handle to Weaver automatically.\\n\\nReturns an array of all of the added [WeaverControllers](WeaverClient#WeaverController).","params":[{"name":"Handle","desc":"","lua_type":"Instance"}],"returns":[{"desc":"","lua_type":"{ WeaverController }"}],"function_type":"static","source":{"line":451,"path":"src/Client.luau"}}],"properties":[{"name":"Player","desc":"A reference to `Players.LocalPlayer` that you can easily access through Weaver.","lua_type":"Player","readonly":true,"source":{"line":481,"path":"src/Client.luau"}},{"name":"Util","desc":"A module that contains all of the utility modules that Weaver exposes.","lua_type":"{ Signal }","readonly":true,"source":{"line":490,"path":"src/Client.luau"}}],"types":[{"name":"WeaverMiddlewareMethod","desc":"","lua_type":"...any -> (boolean, ...any)","source":{"line":32,"path":"src/Client.luau"}},{"name":"WeaverService","desc":"The type used for all services on the client.","fields":[{"name":"AttributeChanged","lua_type":"RBXScriptSignal","desc":""},{"name":"GetAttributeChangedSignal","lua_type":"(self: WeaverService, Attribute: string) -> RBXScriptSignal","desc":""},{"name":"GetAttribute","lua_type":"(self: WeaverService, Attribute: string) -> any","desc":""},{"name":"[string]","lua_type":"RemoteSignal | RemoteProperty | (self: WeaverService, ...any) -> ...any","desc":""}],"source":{"line":47,"path":"src/Client.luau"}},{"name":"WeaverController","desc":"The type used for all controllers.","fields":[{"name":"Name","lua_type":"string","desc":"The name of the controller."},{"name":"[any]","lua_type":"any","desc":""},{"name":"WeaverStart","lua_type":"(self: WeaverController) -> ()?","desc":""},{"name":"WeaverInit","lua_type":"(self: WeaverController) -> ()?","desc":""}],"source":{"line":71,"path":"src/Client.luau"}},{"name":"WeaverMiddlewareCallback","desc":"","lua_type":"(Client: Player, ...any) -> (Continue: boolean, ...any)","source":{"line":84,"path":"src/Client.luau"}},{"name":"WeaverMiddleware","desc":"[Middleware](/docs/communication/middleware) used by the client.","lua_type":"WeaverMiddlewareCallback | { WeaverMiddlewareCallback }","source":{"line":90,"path":"src/Client.luau"}}],"name":"WeaverClient","desc":"The client backend of Weaver.\\n\\nAll of the logic here is for starting and handling controllers alongside the communication bridge with the server.","realm":["Client"],"source":{"line":10,"path":"src/Client.luau"}}')}}]);