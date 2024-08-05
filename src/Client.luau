--!strict
-- Module
--[=[
	@class WeaverClient
	@client

	The client backend of Weaver.

	All of the logic here is for starting and handling controllers alongside the communication bridge with the server.
]=]--
local WeaverClient: WeaverImpl = {} :: WeaverImpl
-- Services
local Players = game:GetService("Players")
-- Modules
local Module = script.Parent

local Internals = Module.Internals
local Util = require(Module.Util)

local RemoteSignal = require(Internals.RemoteSignal)
local Exceptions = require(Internals.Exceptions)
local Paths = require(Internals.Paths)
-- Variables
local Controllers: { [string]: WeaverController } = {}

local Services: { [string]: WeaverService } = {}
local Standby: { [string]: { thread } } = {}

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
-- Public
--[=[
	Starts Weaver.

	**This will throw an error if Weaver is already started.**
]=]--
function WeaverClient.Start(): ()
	assert(not Started, Exceptions.EXCEPTION_HAS_STARTED)

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
	Yields until Weaver has started.

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
			if Child:IsA("Folder") and (Child.Name == Name) then
				Connection:Disconnect()
				task.spawn(Thread)
			end
		end)
	end

	local Service: WeaverService = {} :: WeaverService
	for _, Child: Instance in Path:GetChildren() do
		if Child:IsA("RemoteEvent") or Child:IsA("UnreliableRemoteEvent") then
			Service[Child.Name] = RemoteSignal.new(Child :: RemoteSignal.SignalListener)
			continue
		end
		if Child:IsA("RemoteFunction") then
			Service[Child.Name] = function(_self: WeaverService, ...): (...any)
				return Child:InvokeServer(...)
			end
			continue
		end
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

	**This will throw an error if Weaver has not started, or if `Name` is not used for a controller.**

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
	Creates and adds a [WeaverController] before Weaver has started.

	**This will throw an error if Weaver has started.**

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
-- Types
--[=[
	The type used for all services on the client.

	@type WeaverService { AttributeChanged: RBXScriptSignal, GetAttributeChangedSignal: (self: WeaverService, Attribute: string) -> RBXScriptSignal, GetAttribute: (self: WeaverService, Attribute: string) -> any, [string]: RemoteSignal.RemoteSignal | (self: WeaverService, ...any) -> (...any) }
	@within WeaverClient
]=]--
export type WeaverService =
{
	-- Variables
	AttributeChanged: RBXScriptSignal;
	-- Methods
	GetAttributeChangedSignal: (self: WeaverService, Attribute: string) -> RBXScriptSignal;

	GetAttribute: (self: WeaverService, Attribute: string) -> any;
	GetAttributes: (self: WeaverService) -> { [string]: any };

	[string]: RemoteSignal.RemoteSignal | (self: WeaverService, ...any) -> (...any);
}
--[=[
	The type used for all controllers.

	@type WeaverController { Name: string, [any]: any, WeaverStart: (self: WeaverController) -> ()?, WeaverInit: (self: WeaverController) -> ()? }
	@within WeaverClient
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

export type WeaverImpl =
{
	-- Variables
	Util: typeof(Util);
	Client: Player;
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
		Returns the WeaverService found from the server.

		This will yield until a service matching the name is found.
	]=]--
	GetService: (Name: string) -> WeaverService;
	--[=[
		If the `Name` is used for a controller, returns the WeaverController from the server.

		This will throw an error if Weaver has not started, or if `Name` is not used for a controller.
	]=]--
	GetController: (Name: string) -> WeaverController;
	--[=[
		Creates and adds a controller before Weaver has started.

		This will throw an error if Weaver has started.
	]=]--
	CreateController: (Controller: WeaverController) -> WeaverController;
	--[=[
		Adds all services from Handle to Weaver automatically.

		Returns an array of all of the added WeaverControllers.
	]=]--
	AddControllers: (Handle: Instance) -> { WeaverController };
}
-- Main
WeaverClient.Client = Players.LocalPlayer
WeaverClient.Util = Util

return WeaverClient