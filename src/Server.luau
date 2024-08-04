--!strict
-- Module
--[=[
	@class WeaverServer
	@server

	The server backend of Weaver.

	All of the logic here is for starting and handling services alongside the communication bridge with the client.
]=]--
local Weaver: WeaverImpl = {} :: WeaverImpl
-- Modules
local Module = script.Parent

local Internals = Module.Internals
local Util = Module.Util

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
function Weaver.Start(): ()
	assert(not Started, Exceptions.EXCEPTION_HAS_STARTED)

	Started = true
	table.freeze(Mockups)
	-- Networking
	local Communication: Folder = Instance.new("Folder")
	Communication.Name = Paths.ORIGIN

	for Name: string, Service: WeaverMockService in Mockups do
		local Client: WeaverService = {} :: WeaverService
		local Network: Folder = Instance.new("Folder")

		Network.Name = Name
		for Index: string, Value: any in Service.Client do
			if typeof(Index) ~= "string" then
				continue
			end

			local Type: string = typeof(Value)
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
			if Type == "userdata" then
				local Instantiate: MarkerMethod? = MARKINGS[Value]
				if not Instantiate then
					continue
				end

				Client[Index] = Instantiate(tostring(Index), Network)
				continue
			end
		end

		Client.Server = Service
		Service.Client = Client

		Services[Name] = Service :: WeaverService
		Network.Parent = Communication
	end
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

	Communication.Parent = Paths.TREE
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
function Weaver.OnStart(): ()
	if Running then
		return
	end

	Waiting += 1
	Queue[Waiting] = coroutine.running()

	coroutine.yield()
end

function Weaver.GetService(Name: string): WeaverService
	assert(Started, string.format(Exceptions.EXCEPTION_NEED_USE_START, "GetService"))

	local Type: string = type(Name)
	assert(Type == "string", string.format(Exceptions.EXCEPTION_MUST_BE_TYPE, "Service", "string", Type))

	return assert(Services[Name], string.format(Exceptions.EXCEPTION_DOES_NOT_EXIST, "Service", Name))
end

function Weaver.CreateService(Service: WeaverServiceInit): WeaverMockService
	assert(not Started, string.format(Exceptions.EXCEPTION_BEFORE_START, "Services"))

	local Name: string = Service.Name
	local Type: string = type(Name)

	assert(Type == "string", string.format(Exceptions.EXCEPTION_MUST_BE_TYPE, "Service", "string", Type))
	assert(Mockups[Name] == nil, string.format(Exceptions.EXCEPTION_EXISTS_AS, "Service", Name))

	local Created: WeaverMockService = Service :: WeaverMockService
	if typeof(Created.Client) ~= "table" then
		Created.Client = {}
	end

	Mockups[Name] = Created
	return Created
end
function Weaver.AddServices(Handle: Instance): { WeaverService }
	assert(not Started, string.format(Exceptions.EXCEPTION_BEFORE_START, "Services"))

	local Type: string = typeof(Handle)
	assert(Type == "Instance", string.format(Exceptions.EXCEPTION_MUST_BE_TYPE, "Handle", "Instance", Type))

	local Added: { WeaverService } = {}
	local Index: number = 0

	for _, Child: Instance in Handle:GetChildren() do
		if not Child:IsA("ModuleScript") then
			continue
		end

		local Service: WeaverService = require(Child) :: WeaverService

		Index += 1
		Added[Index] = Service
	end
	return Added
end

function Weaver.CreateRemoteSignal(): Helpers.Marker
	return REMOTE_SIGNAL_MARKER
end
function Weaver.CreateUnreliableSignal(): Helpers.Marker
	return UNRELIABLE_SIGNAL_MARKER
end
-- Types
type MarkerMethod = (Name: string, Communication: Folder) -> RemoteSignal.RemoteSignal
type WeaverMethod = (self: WeaverClient, Invoker: Player, ...any) -> (...any)

type WeaverMockExposed =
{
	[string]: Helpers.Marker | WeaverMethod;
}

type WeaverServiceInit =
{
	-- Variables
	Client: WeaverMockExposed?;
	Name: string;

	[any]: any;
	-- Methods
	WeaverStart: (self: WeaverMockService) -> ()?;
	WeaverInit: (self: WeaverMockService) -> ()?;
}
type WeaverMockService =
{
	-- Variables
	Client: WeaverMockExposed;
	Name: string;

	[any]: any;
	-- Methods
	WeaverStart: (self: WeaverMockService) -> ()?;
	WeaverInit: (self: WeaverMockService) -> ()?;
}

export type WeaverClient =
{
	Server: WeaverService;
	[string]: RemoteSignal.RemoteSignal | WeaverMethod;
}
export type WeaverService =
{
	-- Variables
	Client: WeaverClient;
	Name: string;

	[any]: any;
	-- Methods
	WeaverStart: (self: WeaverMockService) -> ()?;
	WeaverInit: (self: WeaverMockService) -> ()?;
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
		Runs when Weaver is started.
	]=]--
	OnStart: () -> ();
	--[=[
		Gets a service.

		If `Service` exists, returns the `WeaverService` from the server.
	]=]--
	GetService: (Name: string) -> WeaverService;
	--[=[
		Creates a service.

		This method will only work before Weaver is started.
	]=]--
	CreateService: (Service: WeaverServiceInit) -> WeaverMockService;
	--[=[
		Adds all services from `Handle` to Weaver automatically.

		Returns an array of all of the added services.
	]=]--
	AddServices: (Handle: Instance) -> { WeaverService };
	--[=[
		Creates a remote signal.
	]=]--
	CreateRemoteSignal: () -> Helpers.Marker;
	--[=[
		Creates an unreliable remote signal.
	]=]--
	CreateUnreliableSignal: () -> Helpers.Marker;
}
-- Main
Weaver.Util = Util
return table.freeze(Weaver)