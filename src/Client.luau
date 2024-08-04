--!strict
-- Module
--[=[
	@class WeaverClient
	@client

	The client backend of Weaver.

	All of the logic here is for starting and handling controllers alongside the communication bridge with the server.
]=]--
local Weaver: WeaverImpl = {} :: WeaverImpl
-- Services
local Players = game:GetService("Players")
-- Modules
local Module = script.Parent

local Internals = Module.Internals
local Util = Module.Util

local RemoteSignal = require(Internals.RemoteSignal)
local Exceptions = require(Internals.Exceptions)
local Paths = require(Internals.Paths)
-- Variables
local Controllers: { [string]: WeaverController } = {}
local Services: { [string]: WeaverService } = {}

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
		if (Child.Name == Paths.ORIGIN) and Child:IsA("Folder") then
			Located = Child
			task.spawn(Thread)
		end
	end)
	coroutine.yield()

	Connection:Disconnect()
	Bridge = Located

	return Located
end
-- Public
function Weaver.Start(): ()
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

	local Cached: WeaverService? = Services[Name]
	if Cached then
		return Cached
	end

	local Path: Instance = FindBridge():WaitForChild(Name)
	local Service: WeaverService = {}

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
	return Service
end
function Weaver.GetController(Name: string): WeaverController
	assert(Started, string.format(Exceptions.EXCEPTION_NEED_USE_START, "GetController"))

	local Type: string = type(Name)
	assert(Type == "string", string.format(Exceptions.EXCEPTION_MUST_BE_TYPE, "Controller", "string", Type))

	local Controller: WeaverController? = Controllers[Name]
	return assert(Controller, string.format(Exceptions.EXCEPTION_DOES_NOT_EXIST, "Controller", Name))
end

function Weaver.CreateController(Controller: WeaverController): WeaverController
	assert(not Started, string.format(Exceptions.EXCEPTION_BEFORE_START, "Controllers"))

	local Name: string = Controller.Name
	local Type: string = type(Name)

	assert(Type == "string", string.format(Exceptions.EXCEPTION_MUST_BE_TYPE, "Controller", "string", Type))
	assert(Controllers[Name] == nil, string.format(Exceptions.EXCEPTION_EXISTS_AS, "Controller", Name))

	Controllers[Name] = Controller
	return Controller
end
function Weaver.AddControllers(Handle: Instance): { WeaverController }
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
export type WeaverService = { [any]: any }
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
		Runs when Weaver is started.
	]=]--
	OnStart: () -> ();
	--[=[
		Gets a service.

		If `Service` exists, returns what was exposed from the server.
	]=]--
	GetService: (Service: string) -> WeaverService;
	--[=[
		Gets a controller.

		If `Controller` exists, returns the `WeaverController` from the client.
	]=]--
	GetController: (Name: string) -> WeaverController;
	--[=[
		Creates a controller.

		This method will only work before Weaver is started.
	]=]--
	CreateController: (Controller: WeaverController) -> WeaverController;
	--[=[
		Adds all controllers from `Handle` to Weaver automatically.

		Returns an array of all of the added controllers.
	]=]--
	AddControllers: (Handle: Instance) -> { WeaverController };
}
-- Main
Weaver.Client = Players.LocalPlayer
Weaver.Util = Util

return Weaver
