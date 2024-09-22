--!strict
--[=[
	@class WeaverServer
	@server

	The server backend of Weaver.

	All of the logic here is for starting and handling services alongside the communication bridge with the client.
]=]--
-- Module
local WeaverServer = {}
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
type MarkerMethod = (Name: string, Communication: Folder, Inbound: Helpers.MiddlewareCallbacks, Outbound: Helpers.MiddlewareCallbacks) -> RemoteSignal.RemoteSignal
type WeaverAttributes = { [string]: any }
--[=[
	@type WeaverMethod (self: WeaverExposed, Invoker: Player, ...any) -> (...any)
	@within WeaverServer
]=]--
type WeaverMethod = (self: WeaverExposed, Invoker: Player, ...any) -> (...any)
type WeaverMockExposed =
{
	[string]: Helpers.Marker | WeaverMethod | any;
}

type WeaverServiceInit =
{
	-- Variables
	Attributes: WeaverAttributes?;
	Client: WeaverMockExposed?;

	Name: string;
	[any]: any;
	-- Methods
	WeaverStart: (self: WeaverService) -> ()?;
	WeaverInit: (self: WeaverService) -> ()?;
}
type WeaverMockService =
{
	-- Variables
	Attributes: WeaverAttributes;
	Client: WeaverMockExposed;

	Middleware: Helpers.Middleware?;
	Name: string;

	[any]: any;
	-- Methods
	WeaverStart: (self: WeaverService) -> ()?;
	WeaverInit: (self: WeaverService) -> ()?;
}
--[=[
	The type that the `Client` table in [WeaverService](WeaverServer#WeaverService) uses.

	@interface WeaverExposed
	@within WeaverServer

	@field Server WeaverService
	@field [string] RemoteSignal | RemoteProperty | WeaverMethod
]=]--
export type WeaverExposed =
{
	Server: WeaverService;
	[string]: any;
}
--[=[
	The type used for all services on the server.

	@interface WeaverService
	@within WeaverServer

	@field Name string -- The name of the service.
	@field Client WeaverExposed

	@field [any] any

	@field WeaverStart (self: WeaverService) -> ()?
	@field WeaverInit (self: WeaverService) -> ()?

	@field AttributeChanged RBXScriptSignal

	@field GetAttributeChangedSignal (self: WeaverService, Attribute: string) -> RBXScriptSignal
	@field GetAttribute (self: WeaverService, Attribute: string) -> any

	@field SetAttribute (self: WeaverService, Attribute: string, Value: any) -> ()
]=]--
export type WeaverService =
{
	-- Variables
	AttributeChanged: RBXScriptSignal;

	Client: WeaverExposed;
	Name: string;

	[any]: any;
	-- Methods
	GetAttributeChangedSignal: (self: WeaverService, Attribute: string) -> RBXScriptSignal;

	GetAttribute: (self: WeaverService, Attribute: string) -> any;
	GetAttributes: (self: WeaverService) -> { [string]: any };

	SetAttribute: (self: WeaverService, Attribute: string, Value: any) -> ();

	WeaverStart: (self: WeaverService) -> ()?;
	WeaverInit: (self: WeaverService) -> ()?;
}
--[=[
	@type WeaverMiddlewareCallback (Client: Player, ...any) -> (Continue: boolean, ...any)
	@within WeaverServer
]=]--
--[=[
	[Middleware](/docs/communication/middleware) used by the server.

	@type WeaverMiddleware WeaverMiddlewareCallback | { WeaverMiddlewareCallback }
	@within WeaverServer
]=]--
-- Constants
local UNRELIABLE_SIGNAL_MARKER: Helpers.Marker = Helpers.CreateMarker("UNRELIABLE_SIGNAL_MARKER")
local REMOTE_SIGNAL_MARKER: Helpers.Marker = Helpers.CreateMarker("REMOTE_SIGNAL_MARKER")

local MARKINGS: { [Helpers.Marker]: MarkerMethod } =
{
	[REMOTE_SIGNAL_MARKER] = function(Name: string, Communication: Folder, Inbound: Helpers.MiddlewareCallbacks, Outbound: Helpers.MiddlewareCallbacks): RemoteSignal.RemoteSignal
		local Signal: RemoteEvent = Instance.new("RemoteEvent")

		Signal.Name = Name
		Signal.Parent = Communication

		return RemoteSignal.new(Signal :: RemoteSignal.SignalListener, Inbound, Outbound)
	end;
	[UNRELIABLE_SIGNAL_MARKER] = function(Name: string, Communication: Folder, Inbound: Helpers.MiddlewareCallbacks, Outbound: Helpers.MiddlewareCallbacks): RemoteSignal.RemoteSignal
		local Signal: UnreliableRemoteEvent = Instance.new("UnreliableRemoteEvent")

		Signal.Name = Name
		Signal.Parent = Communication

		return RemoteSignal.new(Signal :: RemoteSignal.SignalListener, Inbound, Outbound)
	end;
}
-- Variables
local Mockups: { [string]: WeaverMockService }? = {}
local Services: { [string]: WeaverService } = {}

local Queue: { thread } = {}
local Waiting: number = 0

local Running: boolean = false
local Started: boolean = false
-- Functions
-- Private
local function HookMiddleware(
	Signal: RemoteFunction,
	self: WeaverExposed,
	Callback: (self: WeaverExposed, Client: Player, ...any) -> ...any,
	Inbound: Helpers.MiddlewareCallbacks?,
	Outbound: Helpers.MiddlewareCallbacks?
): ()
	if Inbound then
		if Outbound then
			-- Inbound & Outbound
			Signal.OnServerInvoke = function(Invoker: Player, ...): (...any)
				return Helpers.ProcessMiddleware(Outbound, Invoker, Callback(self, Invoker, Helpers.ProcessMiddleware(Inbound, Invoker, ...)))
			end
			return
		end
		-- Inbound
		Signal.OnServerInvoke = function(Invoker: Player, ...): (...any)
			return Callback(self, Invoker, Helpers.ProcessMiddleware(Inbound, Invoker, ...))
		end
		return
	end
	if Outbound then
		-- Outbound
		Signal.OnServerInvoke = function(Invoker: Player, ...): (...any)
			return Helpers.ProcessMiddleware(Outbound, Invoker, Callback(self, Invoker, ...))
		end
		return
	end
	-- None
	Signal.OnServerInvoke = function(Invoker: Player, ...): (...any)
		return Callback(self, Invoker, ...)
	end
end
-- Public
--[=[
	Starts Weaver.

	If any middleware is provided, it will be used as as the default if no services provide their own.

	:::caution

	This will throw an error if Weaver has already started.

	:::

	@yields
	@param Middleware { Inbound: WeaverMiddleware?, Outbound: WeaverMiddleware? }?
]=]--
function WeaverServer.Start(Middleware: Helpers.Middleware?): ()
	assert(not Started, Exceptions.EXCEPTION_HAS_STARTED)
	assert(Mockups, Exceptions.EXCEPTION_CANT_START)

	local Outbound: Helpers.MiddlewareCallbacks = Helpers.EMPTY_MIDDLEWARE
	local Inbound: Helpers.MiddlewareCallbacks = Helpers.EMPTY_MIDDLEWARE

	if Middleware then
		Outbound = Helpers.StripMiddleware(Middleware.Outbound)
		Inbound = Helpers.StripMiddleware(Middleware.Inbound)
	end

	Started = true
	table.freeze(Mockups)
	-- Networking
	local Communication: Folder = Instance.new("Folder")
	Communication.Name = Paths.ORIGIN
	-- Initialize the signals before parenting the Communication folder
	for Name: string, Mockup: WeaverMockService in Mockups do
		local Service_Outbound: Helpers.MiddlewareCallbacks = Outbound
		local Service_Inbound: Helpers.MiddlewareCallbacks = Inbound

		local Service_Middleware: Helpers.Middleware? = Mockup.Middleware
		if Service_Middleware then
			Service_Outbound = Helpers.StripMiddleware(Service_Middleware.Outbound)
			Service_Inbound = Helpers.StripMiddleware(Service_Middleware.Inbound)
		end

		local Has_Outbound: boolean = Service_Outbound[1] ~= nil
		local Has_Inbound: boolean = Service_Inbound[1] ~= nil

		local Service: WeaverService = Mockup :: WeaverService
		local Client: WeaverExposed = {} :: WeaverExposed

		local Network: Folder = Instance.new("Folder")

		local Signals: Folder = Instance.new("Folder")
		local Props: Folder = Instance.new("Folder")

		Props.Name = Paths.PROPERTIES
		Signals.Name = Paths.SIGNALS

		Signals.Parent = Network
		Props.Parent = Network

		Network.Name = Name
		for Index: string, Value: any in Mockup.Client do
			if (typeof(Index) ~= "string") or (Index == "Server") then
				continue
			end

			local Type: string = typeof(Value)
			-- Functions are declared as RemoteFunctions in the CLient table
			if Type == "function" then
				local Signal: RemoteFunction = Instance.new("RemoteFunction")
				HookMiddleware(
					Signal,
					Client,
					Value,
					if Has_Inbound then Service_Inbound else nil,
					if Has_Outbound then Service_Outbound else nil
				)

				Signal.Name = Index
				Signal.Parent = Signals

				Client[Index] = Value
				continue
			end
			-- Type userdata means that this is a newproxy(), and possibly a marker
			if (Type == "userdata") and (Value ~= Helpers.NONE) then
				local Instantiate: MarkerMethod? = MARKINGS[Value]
				if not Instantiate then
					continue
				end

				Client[Index] = Instantiate(tostring(Index), Signals, Service_Inbound, Service_Outbound)
				continue
			end
			-- Assign other types to a RemoteProperty, since they're defined in the Client table
			local Signal: RemoteEvent = Instance.new("RemoteEvent")

			Signal.Name = Index
			Signal.Parent = Props

			Client[Index] = RemoteProperty.new(Signal, if Value == Helpers.NONE then nil else Value)
		end
		for Attribute: string, Value: any in Mockup.Attributes do
			Network:SetAttribute(Attribute, Value)
		end

		function Service:GetAttribute(Attribute: string): any
			return Network:GetAttribute(Attribute)
		end
		function Service:GetAttributes(): { [string]: any }
			return Network:GetAttributes()
		end

		function Service:GetAttributeChangedSignal(Attribute: string): RBXScriptSignal
			return Network:GetAttributeChangedSignal(Attribute)
		end
		function Service:SetAttribute(Attribute: string, Value: any): ()
			Network:SetAttribute(Attribute, Value)
		end

		Service.AttributeChanged = Network.AttributeChanged
		Service.Attributes = nil

		Client.Server = Service
		Service.Client = Client

		table.freeze(Client)

		Services[Name] = Service :: WeaverService
		Network.Parent = Communication
	end
	-- Clear the Mockups table, since it is now unused
	Mockups = nil
	table.freeze(Services)
	-- Init
	for _, Service: WeaverService in Services do
		local Init: any? = Service.WeaverInit
		if type(Init) ~= "function" then
			continue
		end

		local Thread: thread = coroutine.running()
		local Suspended: boolean = false

		local Runner: thread = task.spawn(function(): ()
			debug.setmemorycategory(`WInitService.{ Service.Name }`)
			Init(Service)

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
	for _, Service: WeaverService in Services do
		local Start: any? = Service.WeaverStart
		if type(Start) ~= "function" then
			continue
		end
		task.spawn(function(): ()
			debug.setmemorycategory(`WService.{ Service.Name }`)
			Start(Service)
		end)
	end
	-- Once the services are started, parent the Communication folder to the tree
	Communication.Parent = Paths.TREE
	Running = true
	-- Then, unpause any threads that are waiting OnStart
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
	Yields until Weaver has started. Useful for external modules that are not ran as services.

	If Weaver has already started, this will not yield.

	@yields
]=]--
function WeaverServer.OnStart(): ()
	if Running then
		return
	end

	Waiting += 1
	Queue[Waiting] = coroutine.running()

	coroutine.yield()
end
--[=[
	If the `Name` is used for a service, returns the [WeaverService](WeaverServer#WeaverService) from the server.

	:::caution

	This will throw an error if Weaver has not started, or if `Name` is not used for a service.

	:::

	@param Name string
	@return WeaverService
]=]--
function WeaverServer.GetService(Name: string): WeaverService
	assert(Started, string.format(Exceptions.EXCEPTION_NEED_USE_START, "GetService"))

	local Type: string = type(Name)
	assert(Type == "string", string.format(Exceptions.EXCEPTION_MUST_BE_TYPE, "Service", "string", Type))

	return assert(Services[Name], string.format(Exceptions.EXCEPTION_DOES_NOT_EXIST, "Service", Name))
end
--[=[
	Returns all [WeaverService]s added.

	:::caution

	This will throw an error if Weaver has not started.

	:::

	@return { [string]: WeaverService }
]=]--
function WeaverServer.GetServices(): { [string]: WeaverService }
	assert(Started, string.format(Exceptions.EXCEPTION_NEED_USE_START, "GetServices"))
	return Services
end
--[=[
	Creates and adds a [WeaverService](WeaverServer#WeaverService) before Weaver has started.

	:::caution

	This will throw an error if Weaver has started.

	:::

	@param Service { Attributes: { [string]: any }?, Client: { [string]: any }?, Name: string, [any]: any, WeaverStart: (self: WeaverService) -> ()?, WeaverInit: (self: WeaverService) -> ()? }
	@return WeaverMockService
]=]--
function WeaverServer.CreateService(Service: WeaverServiceInit): WeaverMockService
	assert(not Started, string.format(Exceptions.EXCEPTION_BEFORE_START, "Services"))

	local Name: string = Service.Name
	local Type: string = type(Name)

	assert(Type == "string", string.format(Exceptions.EXCEPTION_MUST_BE_TYPE, "Service", "string", Type))
	assert(Mockups and (Mockups[Name] == nil), string.format(Exceptions.EXCEPTION_EXISTS_AS, "Service", Name))

	local Created: WeaverMockService = Service :: WeaverMockService
	if typeof(Created.Client) ~= "table" then
		Created.Client = {} :: WeaverExposed
	end
	if typeof(Created.Attributes) ~= "table" then
		Created.Attributes = {} :: WeaverAttributes
	end

	Mockups[Name] = Created
	return Created
end
--[=[
	Adds all services from `Handle` to Weaver automatically.

	Returns an array of all of the added [WeaverServices](WeaverServer#WeaverService).

	@param Handle Instance
	@return { WeaverService }
]=]--
function WeaverServer.AddServices(Handle: Instance): { WeaverService }
	assert(not Started, string.format(Exceptions.EXCEPTION_BEFORE_START, "Services"))

	local Type: string = typeof(Handle)
	assert(Type == "Instance", string.format(Exceptions.EXCEPTION_MUST_BE_TYPE, "Handle", "Instance", Type))

	local Added: { WeaverService } = {}
	local Index: number = 0

	for _, Child: Instance in Handle:GetChildren() do
		if not Child:IsA("ModuleScript") then
			continue
		end

		Index += 1
		Added[Index] = require(Child) :: WeaverService
	end
	return Added
end
--[=[
	Creates a remote signal marker which is turned into a [RemoteSignal] when Weaver is started.

	:::caution

	This will only create a [RemoteSignal] if it is indexxed into the Client table.

	:::

	@return Marker
]=]--
function WeaverServer.CreateRemoteSignal(): Helpers.Marker
	return REMOTE_SIGNAL_MARKER
end
--[=[
	Creates an unreliable signal marker which is turned into a [RemoteSignal] when Weaver is started. This is adjacent to Roblox's [UnreliableRemoteEvent]

	:::caution

	This will only create a [RemoteSignal] if it is indexxed into the Client table.

	:::

	@return Marker
]=]--
function WeaverServer.CreateUnreliableSignal(): Helpers.Marker
	return UNRELIABLE_SIGNAL_MARKER
end
--[=[
	Creates a [RemoteProperty] with a value of `nil` when Weaver has started. If you would like to create a [RemoteProperty] with a value, set your property in your `Client` table to any value, i.e `Service.Client.Property = 0`

	:::caution

	This will only create a [RemoteProperty] if it is indexxed into the Client table.

	:::

	@return Marker
]=]--
function WeaverServer.CreateEmptyProperty(): Helpers.None
	return Helpers.NONE
end
-- Main
--[=[
	A module that contains all of the utility modules that Weaver exposes.

	@prop Util { Signal }
	@within WeaverServer

	@readonly
]=]--
WeaverServer.Util = Util
table.freeze(WeaverServer)

return WeaverServer