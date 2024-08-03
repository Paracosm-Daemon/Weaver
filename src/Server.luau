--!strict
-- Module
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
local Services: { [string]: WeaverService } = {}

local Queue: { thread } = {}
local Waiting: number = 0

local Running: boolean = false
local Started: boolean = false
-- Functions
-- Private
local function HasService(Name: string): boolean
	return Services[Name] ~= nil
end
-- Public
function Weaver.Start(): ()
	assert(not Started, Exceptions.EXCEPTION_HAS_STARTED)

	Started = true
	table.freeze(Services)
	-- Networking
	local Communication: Folder = Instance.new("Folder")
	Communication.Name = Paths.ORIGIN

	for Name: string, Service: WeaverService in Services do
		local Client: WeaverServiceClient = Service.Client
		local Network: Folder = Instance.new("Folder")

		Network.Name = Name
		for Index: any, Value: any in Client do
			local Type: string = typeof(Value)
			if Type == "function" then
				local Signal: RemoteFunction = Instance.new("RemoteFunction")
				Signal.OnServerInvoke = function(Invoker: Player, ...): (...any)
					return Value(Client, Invoker, ...)
				end

				Signal.Name = Index
				Signal.Parent = Network

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
		Network.Parent = Communication
	end
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

	local Service: WeaverService? = Services[Name]
	return assert(Service, string.format(Exceptions.EXCEPTION_DOES_NOT_EXIST, "Service", Name))
end

function Weaver.CreateService(Service: WeaverServiceOmitClient): WeaverService
	assert(not Started, Exceptions.EXCEPTION_BEFORE_START)

	local Name: string = Service.Name
	local Type: string = type(Name)

	assert(Type == "string", string.format(Exceptions.EXCEPTION_MUST_BE_TYPE, "Service", "string", Type))
	assert(not HasService(Name), string.format(Exceptions.EXCEPTION_EXISTS_AS, "Service", Name))

	local Cast: WeaverService = Service :: WeaverService
	local Client: WeaverServiceClient = Cast.Client

	if type(Client) == "table" then
		Client.Server = Cast
	else
		Client = { Server = Cast }
		Service.Client = Client
	end

	Services[Name] = Cast
	return Cast
end
function Weaver.AddServices(Handle: Instance): { WeaverService }
	assert(not Started, Exceptions.EXCEPTION_BEFORE_START)

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
	CreateService: (Service: WeaverServiceOmitClient) -> WeaverService;
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

type WeaverServiceOmitClient =
{
	-- Variables
	Client: { [any]: any }?;
	Name: string;

	[any]: any;
	-- Methods
	WeaverStart: (self: WeaverService) -> ()?;
	WeaverInit: (self: WeaverService) -> ()?;
}

export type WeaverServiceClient =
{
	Server: WeaverService;
	[any]: any;
}
export type WeaverService =
{
	-- Variables
	Client: WeaverServiceClient;
	Name: string;

	[any]: any;
	-- Methods
	WeaverStart: (self: WeaverService) -> ()?;
	WeaverInit: (self: WeaverService) -> ()?;
}
-- Main
Weaver.Util = Util
return table.freeze(Weaver)