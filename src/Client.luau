--!strict
--[=[
	@class WeaverClient
	@client

	The client backend of Weaver.

	All of the logic here is for starting and handling controllers alongside the communication bridge with the server.
]=]--
-- Module
local WeaverClient = {}
-- Services
local Players = game:GetService("Players")
-- Modules
local Module = script.Parent

local Internals = Module.Internals
local Util = require(Module.Util)

local RemoteProperty = require(Internals.RemoteProperty)
local RemoteSignal = require(Internals.RemoteSignal)

local Exceptions = require(Internals.Exceptions)
local Helpers = require(Internals.Helpers)
local Paths = require(Internals.Paths)
-- Types
type WeaverClientMiddleware = Helpers.Middleware & { Services: { [string]: Helpers.Middleware }? }
--[=[
	@type WeaverMiddlewareMethod ...any -> (boolean, ...any)
	@within WeaverClient
]=]--
export type WeaverMiddlewareMethod = (self: WeaverController, ...any) -> (boolean, ...any)
export type WeaverMiddlewareMethods = { WeaverMiddlewareMethod }
--[=[
	The type used for all services on the client.

	@interface WeaverService
	@within WeaverClient

	@field AttributeChanged RBXScriptSignal

	@field GetAttributeChangedSignal (self: WeaverService, Attribute: string) -> RBXScriptSignal
	@field GetAttribute (self: WeaverService, Attribute: string) -> any

	@field [string] RemoteSignal | RemoteProperty | (self: WeaverService, ...any) -> ...any
]=]--
export type WeaverService =
{
	-- Variables
	AttributeChanged: RBXScriptSignal;
	-- Methods
	GetAttributeChangedSignal: (self: WeaverService, Attribute: string) -> RBXScriptSignal;

	GetAttribute: (self: WeaverService, Attribute: string) -> any;
	GetAttributes: (self: WeaverService) -> { [string]: any };

	[string]: RemoteSignal.RemoteSignal | RemoteProperty.RemoteProperty | (self: WeaverService, ...any) -> ...any;
}
--[=[
	The type used for all controllers.

	@interface WeaverController
	@within WeaverClient

	@field Name string -- The name of the controller.
	@field [any] any

	@field WeaverStart (self: WeaverController) -> ()?
	@field WeaverInit (self: WeaverController) -> ()?
]=]--
export type WeaverController =
{
	-- Variables
	Name: string;
	[any]: any;
	-- Methods
	WeaverStart: (self: WeaverController) -> ()?;
	WeaverInit: (self: WeaverController) -> ()?;
}
--[=[
	@type WeaverMiddlewareCallback (Client: Player, ...any) -> (Continue: boolean, ...any)
	@within WeaverClient
]=]--
--[=[
	[Middleware](/docs/communication/middleware) used by the client.

	@type WeaverMiddleware WeaverMiddlewareCallback | { WeaverMiddlewareCallback }
	@within WeaverClient
]=]--
-- Constants
local CLIENT: Player = Players.LocalPlayer
-- Variables
local Controllers: { [string]: WeaverController } = {}

local Services: { [string]: WeaverService } = {}
local Standby: { [string]: { thread } } = {}

local Outbound: WeaverMiddlewareMethods = Helpers.EMPTY_MIDDLEWARE
local Inbound: WeaverMiddlewareMethods = Helpers.EMPTY_MIDDLEWARE

local Service_Middleware: { [string]: { WeaverMiddlewareMethods } } = {}
local Queue: { thread } = {}

local Waiting: number = 0
local Bridge: Folder

local Running: boolean = false
local Started: boolean = false
-- Functions
-- Private
local function FindBridge(): Folder
	if Bridge then
		return Bridge
	end
	for _, Child: Instance in Paths.TREE:GetChildren() do
		if (Child.Name == Paths.ORIGIN) and Child:IsA("Folder") then
			Bridge = Child
			return Child
		end
	end

	local Thread: thread = coroutine.running()
	local Connection: RBXScriptConnection

	local Located: Folder
	Connection = Paths.TREE.ChildAdded:Connect(function(Child: Instance): ()
		if not Connection.Connected then
			return
		end
		if (Child.Name == Paths.ORIGIN) and Child:IsA("Folder") then
			Located = Child
			Connection:Disconnect()

			task.spawn(Thread)
		end
	end)

	coroutine.yield()
	Bridge = Located

	return Located
end
local function HookMiddleware(
	Signal: RemoteFunction,
	Service_Inbound: Helpers.MiddlewareCallbacks?,
	Service_Outbound: Helpers.MiddlewareCallbacks?
): (self: WeaverService, ...any) -> ...any
	if Service_Outbound then
		if Service_Inbound then
			-- Inbound & Outbound
			return function(_self: WeaverService, ...): ...any
				return Helpers.ProcessMiddleware(Service_Inbound, Signal:InvokeServer(Helpers.ProcessMiddleware(Service_Outbound, ...)))
			end
		end
		-- Outbound
		return function(_self: WeaverService, ...): ...any
			return Signal:InvokeServer(Helpers.ProcessMiddleware(Service_Outbound, ...))
		end
	end
	if Service_Inbound then
		-- Inbound
		return function(_self: WeaverService, ...): ...any
			return Helpers.ProcessMiddleware(Service_Inbound, Signal:InvokeServer(...))
		end
	end
	-- None
	return function(_self: WeaverService, ...): ...any
		return Signal:InvokeServer(...)
	end
end
-- Public
--[=[
	Starts Weaver.

	If any middleware is provided, it will be used as as the default if no services have their own within the optional `Services` table.

	:::caution

	This will throw an error if Weaver is already started.

	:::

	@yields
	@param Middleware { Inbound: WeaverMiddleware?, Outbound: WeaverMiddleware?, Services: { [string]: { Inbound: WeaverMiddleware?, Outbound: WeaverMiddleware? } }? }?
]=]--
function WeaverClient.Start(Middleware: WeaverClientMiddleware?): ()
	assert(not Started, Exceptions.EXCEPTION_HAS_STARTED)
	if Middleware then
		Outbound = Helpers.StripMiddleware(Middleware.Outbound)
		Inbound = Helpers.StripMiddleware(Middleware.Inbound)

		local Services_Middleware: { [string]: Helpers.Middleware }? = Middleware.Services
		if Services_Middleware then
			for Service: string, Service_Methods: Helpers.Middleware in Services_Middleware do
				local Service_Outbound: WeaverMiddlewareMethods = Outbound
				local Service_Inbound: WeaverMiddlewareMethods = Inbound

				if Service_Methods then
					Service_Outbound = Helpers.StripMiddleware(Service_Methods.Outbound)
					Service_Inbound = Helpers.StripMiddleware(Service_Methods.Inbound)
				end
				Service_Middleware[Service] = { Service_Inbound, Service_Outbound }
			end
		end
	end

	Started = true
	table.freeze(Controllers)
	-- Init
	for _, Controller: WeaverController in Controllers do
		local Init: any? = Controller.WeaverInit
		if type(Init) ~= "function" then
			continue
		end

		local Thread: thread = coroutine.running()
		local Suspended: boolean = false

		local Runner: thread = task.spawn(function(): ()
			debug.setmemorycategory(`WInitController.{ Controller.Name }`)
			Init(Controller)

			if Suspended then
				task.spawn(Thread)
			end
		end)
		-- Prevent unnecessary yielding if the thread isn't dead
		if coroutine.status(Runner) ~= "dead" then
			Suspended = true
			coroutine.yield()
		end
	end
	-- Start
	for _, Controller: WeaverController in Controllers do
		local Start: any? = Controller.WeaverStart
		if type(Start) ~= "function" then
			continue
		end
		task.spawn(function(): ()
			debug.setmemorycategory(`WController.{ Controller.Name }`)
			Start(Controller)
		end)
	end

	Running = true
	if Waiting ~= 0 then
		for Index: number = 1, Waiting, 1 do
			local Thread: thread = Queue[Index]
			task.spawn(Thread)

			Queue[Index] = nil
		end
		Waiting = 0
	end
end
--[=[
	Yields until Weaver has started. Useful for external modules that are not ran as controllers.

	If Weaver has already started, this will not yield.

	@yields
]=]--
function WeaverClient.OnStart(): ()
	if Running then
		return
	end

	Waiting += 1
	Queue[Waiting] = coroutine.running()

	coroutine.yield()
end
--[=[
	Returns the [WeaverService](WeaverClient#WeaverService) found from the server.

	This will yield until a service matching the name is found.

	@yields

	@param Name string
	@return WeaverService
]=]--
function WeaverClient.GetService(Name: string): WeaverService
	assert(Started, string.format(Exceptions.EXCEPTION_NEED_USE_START, "GetService"))

	local Type: string = type(Name)
	assert(Type == "string", string.format(Exceptions.EXCEPTION_MUST_BE_TYPE, "Service", "string", Type))

	local Cached: WeaverService? = Services[Name]
	if Cached then
		return Cached
	end
	-- Prevent all possible instances of creating multiple Service tables, should it yield.
	local Queued: { thread }? = Standby[Name]
	if Queued then
		table.insert(Queued, coroutine.running())
		return coroutine.yield()
	end

	local Yielding: { thread } = {}
	Standby[Name] = Yielding

	local Network: Folder = FindBridge()

	local Found: Instance? = Network:FindFirstChild(Name)
	local Path: Folder

	if Found and Found:IsA("Folder") then
		Path = Found
	else
		local Thread: thread = coroutine.running()
		local Connection: RBXScriptConnection

		Connection = Network.ChildAdded:Connect(function(Child: Instance): ()
			if not Connection.Connected then
				return
			end
			if Child:IsA("Folder") and (Child.Name == Name) and not Path then
				Path = Child
				Connection:Disconnect()

				task.spawn(Thread)
			end
		end)
		if not Path then
			coroutine.yield()
		end
	end
	-- These are safe if the WeaverService was constructed properly
	local Props: Folder = Path[Paths.PROPERTIES]
	local Signals: Folder = Path[Paths.SIGNALS]

	local Middleware: { WeaverMiddlewareMethods }? = Service_Middleware[Name]
	local Service: WeaverService = {} :: WeaverService

	local Service_Outbound: WeaverMiddlewareMethods = if Middleware then Middleware[2] else Outbound
	local Service_Inbound: WeaverMiddlewareMethods = if Middleware then Middleware[1] else Inbound

	local Has_Outbound: boolean = Service_Outbound[1] ~= nil
	local Has_Inbound: boolean = Service_Inbound[1] ~= nil

	for _, Child: Instance in Signals:GetChildren() do
		if Child:IsA("RemoteEvent") or Child:IsA("UnreliableRemoteEvent") then
			Service[Child.Name] = RemoteSignal.new(Child :: RemoteSignal.SignalListener, Service_Inbound, Service_Outbound)
			continue
		end
		if Child:IsA("RemoteFunction") then
			Service[Child.Name] = HookMiddleware(
				Child,
				if Has_Inbound then Service_Inbound else nil,
				if Has_Outbound then Service_Outbound else nil
			)
		end
	end
	for _, Child: Instance in Props:GetChildren() do
		if not Child:IsA("RemoteEvent") then
			continue
		end
		Service[Child.Name] = RemoteProperty.new(Child, nil)
	end
	-- Define only GetAttribute(s)/GetAttributeChangedSignal
	function Service:GetAttribute(Attribute: string): any
		return Path:GetAttribute(Attribute)
	end
	function Service:GetAttributes(): { [string]: any }
		return Path:GetAttributes()
	end

	function Service:GetAttributeChangedSignal(Attribute: string): RBXScriptSignal
		return Path:GetAttributeChangedSignal(Attribute)
	end

	Service.AttributeChanged = Path.AttributeChanged
	Services[Name] = Service

	for _, Thread: thread in Yielding do
		task.spawn(Thread, Service)
	end

	Standby[Name] = nil
	return Service
end
--[=[
	If the `Name` is used for a controller, returns the [WeaverController] from the server.

	:::caution

	This will throw an error if Weaver has not started, or if `Name` is not used for a controller.

	:::

	@param Name string
	@return WeaverController
]=]--
function WeaverClient.GetController(Name: string): WeaverController
	assert(Started, string.format(Exceptions.EXCEPTION_NEED_USE_START, "GetController"))

	local Type: string = type(Name)
	assert(Type == "string", string.format(Exceptions.EXCEPTION_MUST_BE_TYPE, "Controller", "string", Type))

	local Controller: WeaverController? = Controllers[Name]
	return assert(Controller, string.format(Exceptions.EXCEPTION_DOES_NOT_EXIST, "Controller", Name))
end
--[=[
	Returns all [WeaverController]s added.

	:::caution

	This will throw an error if Weaver has not started.

	:::

	@return { [string]: WeaverController }
]=]--
function WeaverClient.GetControllers(): { [string]: WeaverController }
	assert(Started, string.format(Exceptions.EXCEPTION_NEED_USE_START, "GetControllers"))
	return Controllers
end
--[=[
	Creates and adds a [WeaverController] before Weaver has started.

	:::caution

	This will throw an error if Weaver has started.

	:::

	@param Controller WeaverController
	@return WeaverController
]=]--
function WeaverClient.CreateController(Controller: WeaverController): WeaverController
	assert(not Started, string.format(Exceptions.EXCEPTION_BEFORE_START, "Controllers"))

	local Name: string = Controller.Name
	local Type: string = type(Name)

	assert(Type == "string", string.format(Exceptions.EXCEPTION_MUST_BE_TYPE, "Controller", "string", Type))
	assert(Controllers[Name] == nil, string.format(Exceptions.EXCEPTION_EXISTS_AS, "Controller", Name))

	Controllers[Name] = Controller
	return Controller
end
--[=[
	Adds all services from Handle to Weaver automatically.

	Returns an array of all of the added [WeaverControllers](WeaverClient#WeaverController).

	@param Handle Instance
	@return { WeaverController }
]=]--
function WeaverClient.AddControllers(Handle: Instance): { WeaverController }
	assert(not Started, string.format(Exceptions.EXCEPTION_BEFORE_START, "Controllers"))

	local Type: string = typeof(Handle)
	assert(Type == "Instance", string.format(Exceptions.EXCEPTION_MUST_BE_TYPE, "Handle", "Instance", Type))

	local Added: { WeaverController } = {}
	local Index: number = 0

	for _, Child: Instance in Handle:GetChildren() do
		if not Child:IsA("ModuleScript") then
			continue
		end

		local Controller: WeaverController = require(Child) :: WeaverController

		Index += 1
		Added[Index] = Controller
	end
	return Added
end
-- Main
--[=[
	A reference to `Players.LocalPlayer` that you can easily access through Weaver.

	@prop Player Player
	@within WeaverClient

	@readonly
]=]--
WeaverClient.Player = CLIENT
--[=[
	A module that contains all of the utility modules that Weaver exposes.

	@prop Util { Signal }
	@within WeaverClient

	@readonly
]=]--
WeaverClient.Util = Util
table.freeze(WeaverClient)

return WeaverClient