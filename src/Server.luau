--!strict
-- Module
--[=[
	@class WeaverServer
	@server

	The server backend of Weaver.

	All of the logic here is for starting and handling services alongside the communication bridge with the client.
]=]--
local WeaverServer: WeaverImpl = {} :: WeaverImpl
-- Modules
local Module = script.Parent

local Internals = Module.Internals
local Util = require(Module.Util)

local RemoteSignal = require(Internals.RemoteSignal)
local Exceptions = require(Internals.Exceptions)
local Helpers = require(Internals.Helpers)
local Paths = require(Internals.Paths)
-- Constants
local UNRELIABLE_SIGNAL_MARKER: Helpers.Marker = Helpers.CreateMarker("UNRELIABLE_SIGNAL_MARKER")
local REMOTE_SIGNAL_MARKER: Helpers.Marker = Helpers.CreateMarker("REMOTE_SIGNAL_MARKER")

local MARKINGS: { [Helpers.Marker]: MarkerMethod } =
{
	[REMOTE_SIGNAL_MARKER] = function(Name: string, Communication: Folder): RemoteSignal.RemoteSignal
		local Signal: RemoteEvent = Instance.new("RemoteEvent")

		Signal.Name = Name
		Signal.Parent = Communication

		return RemoteSignal.new(Signal :: RemoteSignal.SignalListener)
	end;
	[UNRELIABLE_SIGNAL_MARKER] = function(Name: string, Communication: Folder): RemoteSignal.RemoteSignal
		local Signal: UnreliableRemoteEvent = Instance.new("UnreliableRemoteEvent")

		Signal.Name = Name
		Signal.Parent = Communication

		return RemoteSignal.new(Signal :: RemoteSignal.SignalListener)
	end;
}
-- Variables
local Mockups: { [string]: WeaverMockService } = {}
local Services: { [string]: WeaverService } = {}

local Queue: { thread } = {}
local Waiting: number = 0

local Running: boolean = false
local Started: boolean = false
-- Functions
-- Private
-- Public
--[=[
	Starts Weaver.

	**This will throw an error if Weaver is already started.**
]=]--
function WeaverServer.Start(): ()
	assert(not Started, Exceptions.EXCEPTION_HAS_STARTED)

	Started = true
	table.freeze(Mockups)
	-- Networking
	local Communication: Folder = Instance.new("Folder")
	Communication.Name = Paths.ORIGIN
	-- Initialize the signals before parenting the Communication folder
	for Name: string, Mockup: WeaverMockService in Mockups do
		local Service: WeaverService = Mockup :: WeaverService
		local Client: WeaverExposed = {} :: WeaverExposed

		local Network: Folder = Instance.new("Folder")
		Network.Name = Name

		for Index: string, Value: any in Mockup.Client do
			if (typeof(Index) ~= "string") or (Index == "Server") then
				continue
			end

			local Type: string = typeof(Value)
			-- Functions are declared as RemoteFunctions in the CLient table
			if Type == "function" then
				local Signal: RemoteFunction = Instance.new("RemoteFunction")
				Signal.OnServerInvoke = function(Invoker: Player, ...): (...any)
					return Value(Client, Invoker, ...)
				end

				Signal.Name = Index
				Signal.Parent = Network

				Client[Index] = Value
				continue
			end
			-- Type userdata means that this is a newproxy(), and possibly a marker
			if Type == "userdata" then
				local Instantiate: MarkerMethod? = MARKINGS[Value]
				if not Instantiate then
					continue
				end

				Client[Index] = Instantiate(tostring(Index), Network)
				continue
			end
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

		Client.Server = Service
		Service.Client = Client

		table.freeze(Client)

		Services[Name] = Service :: WeaverService
		Network.Parent = Communication
	end
	-- Clear the Mockups table, since it is now unused
	Mockups = {}
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
	Yields until Weaver has started.

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

	**This will throw an error if Weaver has not started, or if `Name` is not used for a service.**

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
	Creates and adds a [WeaverService](WeaverServer#WeaverService) before Weaver has started.

	**This will throw an error if Weaver has started.**

	@param Service { Attributes: { [string]: any }?, Client: { [string]: any }?, Name: string, [any]: any, WeaverStart: (self: WeaverService) -> ()?, WeaverInit: (self: WeaverService) -> ()? }
	@return WeaverMockService
]=]--
function WeaverServer.CreateService(Service: WeaverServiceInit): WeaverMockService
	assert(not Started, string.format(Exceptions.EXCEPTION_BEFORE_START, "Services"))

	local Name: string = Service.Name
	local Type: string = type(Name)

	assert(Type == "string", string.format(Exceptions.EXCEPTION_MUST_BE_TYPE, "Service", "string", Type))
	assert(Mockups[Name] == nil, string.format(Exceptions.EXCEPTION_EXISTS_AS, "Service", Name))

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

	**This will only create a [RemoteSignal] if it is indexxed into the Client table.**

	@return Marker
]=]--
function WeaverServer.CreateRemoteSignal(): Helpers.Marker
	return REMOTE_SIGNAL_MARKER
end
--[=[
	Creates an unreliable signal marker which is turned into a [RemoteSignal] when Weaver is started. This is adjacent to Roblox's [UnreliableRemoteEvent]

	**This will only create a [RemoteSignal] if it is indexxed into the Client table.**

	@return Marker
]=]--
function WeaverServer.CreateUnreliableSignal(): Helpers.Marker
	return UNRELIABLE_SIGNAL_MARKER
end
-- Types
type MarkerMethod = (Name: string, Communication: Folder) -> RemoteSignal.RemoteSignal
type WeaverAttributes = { [string]: any }
--[=[
	@type WeaverMethod (self: WeaverExposed, Invoker: Player, ...any) -> (...any)
	@within WeaverServer
]=]--
type WeaverMethod = (self: WeaverExposed, Invoker: Player, ...any) -> (...any)
type WeaverMockExposed =
{
	[string]: Helpers.Marker | WeaverMethod;
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

	Name: string;
	[any]: any;
	-- Methods
	WeaverStart: (self: WeaverService) -> ()?;
	WeaverInit: (self: WeaverService) -> ()?;
}
--[=[
	The type that the `Client` table in [WeaverService](WeaverServer#WeaverService) uses.

	@type WeaverExposed { Server: WeaverService, [string]: RemoteSignal | WeaverMethod }
	@within WeaverServer
]=]--
export type WeaverExposed =
{
	Server: WeaverService;
	[string]: any;
}
--[=[
	The type used for all services on the server.

	@type WeaverService { AttributeChanged: RBXScriptSignal, Client: WeaverExposed, Name: string, [any]: any, GetAttributeChangedSignal: (self: WeaverService, Attribute: string) -> RBXScriptSignal, GetAttribute: (self: WeaverService, Attribute: string) -> any, SetAttribute: (self: WeaverService, Attribute: string, Value: any) -> (), WeaverStart: (self: WeaverService) -> ()?, WeaverInit: (self: WeaverService) -> ()? }
	@within WeaverServer
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

export type WeaverImpl =
{
	-- Variables
	Util: typeof(Util);
	-- Methods
	--[=[
		Starts Weaver.

		This will throw an error if Weaver is already started.
	]=]--
	Start: () -> ();
	--[=[
		Yields until Weaver has started.

		If Weaver has already started, this will not yield.
	]=]--
	OnStart: () -> ();
	--[=[
		If the `Name` is used for a service, returns the WeaverService from the server.

		This will throw an error if Weaver has not started, or if `Name` is not used for a service.
	]=]--
	GetService: (Name: string) -> WeaverService;
	--[=[
		Creates and adds a service before Weaver has started. The WeaverService returned will be turned into a WeaverService once Weaver starts.

		This will throw an error if Weaver has started.
	]=]--
	CreateService: (Service: WeaverServiceInit) -> WeaverService;
	--[=[
		Adds all services from `Handle` to Weaver automatically.

		Returns an array of all of the added WeaverServices.
	]=]--
	AddServices: (Handle: Instance) -> { WeaverService };
	--[=[
		Creates a remote signal marker which is turned into a RemoteSignal when Weaver is started.

		This will only create a RemoteSignal if it is indexxed into the Client table.
	]=]--
	CreateRemoteSignal: () -> Helpers.Marker;
	--[=[
		Creates an unreliable signal marker which is turned into a RemoteSignal when Weaver is started. This is adjacent to Roblox's UnreliableRemoteEvent

		This will only create a RemoteSignal if it is indexxed into the Client table.
	]=]--
	CreateUnreliableSignal: () -> Helpers.Marker;
}
-- Main
WeaverServer.Util = Util
return table.freeze(WeaverServer)