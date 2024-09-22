--!strict
--[=[
	@class RemoteSignal

	Weaver's built-in implementation for RemoteEvents.

	This is an interface meant to make using RemoteEvents much easier, with functions identical to [Signal].
]=]--
-- Module
local RemoteSignal: RemoteSignalImpl = {} :: RemoteSignalImpl

RemoteSignal.__index = RemoteSignal
RemoteSignal.__tostring = function(_self: RemoteSignalImpl): string
	return "RemoteSignal"
end
-- Services
local RunService = game:GetService("RunService")
-- Modules
local Internals = script.Parent

local Clients = require(Internals.Clients)
local Helpers = require(Internals.Helpers)
-- Types
type RemoteSignalImpl =
{
	-- Variables
	__index: RemoteSignalImpl;
	__tostring: (self: RemoteSignalImpl) -> string;
	-- Methods
	--[=[
		Constructs a new RemoteSignal object.
	]=]--
	new: (Instance: SignalListener, Inbound: Helpers.MiddlewareCallbacks, Outbound: Helpers.MiddlewareCallbacks) -> RemoteSignal;
	--[=[
		On the client, fires to the server.

		On the server, fires to the specified client. The first argument of `Fire` must be a Player in this case.
	]=]--
	Fire: (self: RemoteSignal, ...any) -> ();
	--[=[
		Fires to all clients in the game.
	]=]--
	FireAll: (self: RemoteSignal, ...any) -> ();
	--[=[
		Fires to all clients specified in `For`.
	]=]--
	FireFor: (self: RemoteSignal, For: { Player }, ...any) -> ();
	--[=[
		Fires to all clients in the game, except for the clients specified.
	]=]--
	FireExcept: (self: RemoteSignal, Excluding: { Player }, ...any) -> ();
	--[=[
		Fires to all clients in the game, using a filter to specify which clients receive the event.
	]=]--
	FireFilter: (self: RemoteSignal, Filter: (Client: Player, ...any) -> boolean, ...any) -> ();
	--[=[
		Connects `Callback` to this RemoteSignal.

		Executes when a client fires this RemoteSignal to the server, or vice versa.
	]=]--
	Connect: (self: RemoteSignal, Callback: RemoteConnectionCallback) -> RBXScriptConnection;
	--[=[
		Connects `Callback` to this RemoteSignal in parallel. Useful with Parallel Luau.

		Executes when a client fires this RemoteSignal to the server, or vice versa.
	]=]--
	ConnectParallel: (self: RemoteSignal, Callback: RemoteConnectionCallback) -> RBXScriptConnection;
	--[=[
		Connects `Callback` to this RemoteSignal, disconnecting it once the RemoteSignal has fired once.
	]=]--
	Once: (self: RemoteSignal, Callback: RemoteConnectionCallback) -> RBXScriptConnection;
	--[=[
		Waits for the event to fire before resuming the current thread.
	]=]--
	Wait: (self: RemoteSignal) -> (...any);
}
type BaseRemoteConnection = (...any) -> ()
--[=[
	@type RemoteConnectionCallback (...any) -> () | (Client: Player, ...any)
	@within RemoteSignal
]=]--
type RemoteConnectionCallback = BaseRemoteConnection | (Client: Player, ...any) -> ()
--[=[
	@private

	@type SignalListener Instance & { OnServerEvent: RBXScriptSignal<(Player, ...any)>, OnClientEvent: RBXScriptSignal<...any>, FireClient: (Client: Player, ...any) -> (), FireAllClients: (...any) -> (), FireServer: (...any) -> () }
	@within RemoteSignal
]=]--
export type SignalListener = Instance & {
	OnServerEvent: RBXScriptSignal<(Player, ...any)>;
	OnClientEvent: RBXScriptSignal<...any>;

	FireClient: (Client: Player, ...any) -> ();

	FireAllClients: (...any) -> ();
	FireServer: (...any) -> ();
}
--[=[
	Determines whether the RemoteSignal is unreliable or not.

	@prop Unreliable boolean
	@within RemoteSignal

	@readonly
]=]--
export type RemoteSignal = typeof(setmetatable({} :: {
	Unreliable: boolean;

	_Instance: SignalListener;
	_Event: RBXScriptSignal;

	_Outbound: Helpers.MiddlewareCallbacks;
	_Inbound: Helpers.MiddlewareCallbacks;

	_Has_Outbound: boolean;
	_Has_Inbound: boolean;
}, {} :: RemoteSignalImpl))
-- Constants
local IS_SERVER: boolean = RunService:IsServer()
-- Functions
-- Private
local ProcessInbound: (Inbounds: Helpers.MiddlewareCallbacks, ...any) -> ...any
if IS_SERVER then
	ProcessInbound = function(Inbounds: Helpers.MiddlewareCallbacks, Client: Player, ...): (Player, ...any)
		return Client, Helpers.ProcessMiddleware(Inbounds, Client, ...)
	end
else
	ProcessInbound = function(Inbounds: Helpers.MiddlewareCallbacks, ...): ...any
		return Helpers.ProcessMiddleware(Inbounds, ...)
	end
end
-- Public
--[=[
	Constructs a new RemoteSignal object.

	@private
	@param From SignalListener -- The SignalListener to hook.

	@return RemoteSignal
]=]--
function RemoteSignal.new(From: SignalListener, Inbound: Helpers.MiddlewareCallbacks, Outbound: Helpers.MiddlewareCallbacks): RemoteSignal
	return table.freeze(setmetatable({
		Unreliable = From:IsA("UnreliableRemoteEvent");
		-- Fast way of checking since it's guaranteed to be an ordered array
		_Has_Outbound = Outbound[1] ~= nil;
		_Has_Inbound = Inbound[1] ~= nil;

		_Outbound = Outbound;
		_Inbound = Inbound;

		_Instance = From;
		_Event = if IS_SERVER then From.OnServerEvent else From.OnClientEvent;
	}, RemoteSignal))
end
if IS_SERVER then
	--[=[
		Fires to the specified client, from the server.

		:::caution

		The first argument of `Fire` must be a [Player].

		:::

		@server
		@param ... ...any -- The arguments to send over this RemoteSignal.
	]=]--
	function RemoteSignal:Fire(Client: Player, ...): ()
		assert((typeof(Client) == "Instance") and Client:IsA("Player"), "The first argument of FireClient on the server must be a player, got %s")
		if not self._Has_Outbound then
			self._Instance:FireClient(Client, ...)
			return
		end
		self._Instance:FireClient(Client, Helpers.ProcessMiddleware(self._Outbound, Client, ...))
	end
	--[=[
		Fires to all clients in the game.

		@server
		@param ... ...any
	]=]--
	function RemoteSignal:FireAll(...): ()
		if not self._Has_Outbound then
			self._Instance:FireAllClients(...)
			return
		end
		for _, Client: Player in Clients.Array do
			self._Instance:FireClient(Client, Helpers.ProcessMiddleware(self._Outbound, Client, ...))
		end
	end
	--[=[
		Fires to all clients specified in `For`.

		@server
		@param For { Player }
		@param ... ...any
	]=]--
	function RemoteSignal:FireFor(For: { Player }, ...): ()
		for _, Client: Player in For do
			self:Fire(Client, ...)
		end
	end
	--[=[
		Fires to all clients in the game, except for the clients specified.

		@server
		@param Excluding { Player }
		@param ... ...any
	]=]--
	function RemoteSignal:FireExcept(Excluding: { Player }, ...): ()
		local For: { Player } = table.clone(Clients.Array)
		for _, Client: Player in Excluding do
			For[Clients.Map[Client]] = nil
		end
		self:FireFor(For, ...)
	end
	--[=[
		Fires to all clients in the game, using a filter to specify which clients receive the event.

		@server
		@param Filter (Client: Player, ...any) -> boolean
		@param ... ...any
	]=]--
	function RemoteSignal:FireFilter(Filter: (Client: Player, ...any) -> boolean, ...): ()
		local For: { Player } = {}
		for _, Client: Player in Clients.Array do
			if not Filter(Client, ...) then
				continue
			end
			For[Clients.Map[Client]] = Client
		end
		self:FireFor(For, ...)
	end
else
	--[=[
		Fires to the server, from the client.

		@client
		@param ... ...any -- The arguments to send over this RemoteSignal.
	]=]--
	function RemoteSignal:Fire(...): ()
		if not self._Has_Outbound then
			self._Instance:FireServer(...)
			return
		end
		self._Instance:FireServer(Helpers.ProcessMiddleware(self._Outbound, ...))
	end
end
--[=[
	Connects `Callback` to this RemoteSignal.

	Executes when a client fires this RemoteSignal to the server, or vice versa.

	@param Callback RemoteConnectionCallback -- The function to connect.
	@return RBXScriptConnection
]=]--
function RemoteSignal:Connect(Callback: RemoteConnectionCallback): RBXScriptConnection
	if not self._Has_Inbound then
		return self._Event:Connect(Callback)
	end
	return self._Event:Connect(function(...): ()
		(Callback :: BaseRemoteConnection)(ProcessInbound(self._Inbound, ...))
	end)
end
--[=[
	Connects `Callback` to this RemoteSignal in parallel. Useful with Parallel Luau.

	Executes when a client fires this RemoteSignal to the server, or vice versa.

	@param Callback RemoteConnectionCallback -- The function to connect.
	@return RBXScriptConnection
]=]--
function RemoteSignal:ConnectParallel(Callback: RemoteConnectionCallback): RBXScriptConnection
	if not self._Has_Inbound then
		return self._Event:ConnectParallel(Callback)
	end
	return self._Event:ConnectParallel(function(...): ()
		(Callback :: BaseRemoteConnection)(ProcessInbound(self._Inbound, ...))
	end)
end
--[=[
	Connects `Callback` to this RemoteSignal, disconnecting it once the RemoteSignal has fired once.

	@param Callback RemoteConnectionCallback -- The function to connect.
	@return RBXScriptConnection
]=]--
function RemoteSignal:Once(Callback: RemoteConnectionCallback): RBXScriptConnection
	if not self._Has_Inbound then
		return self._Event:Once(Callback)
	end
	return self._Event:Once(function(...): ()
		(Callback :: BaseRemoteConnection)(ProcessInbound(self._Inbound, ...))
	end)
end
--[=[
	Waits for the event to fire before resuming the current thread.

	@yields
	@return ...any -- All of the data that the RemoteSignal returned from one event.
]=]--
function RemoteSignal:Wait(): ...any
	if not self._Has_Inbound then
		return self._Event:Wait()
	end
	return ProcessInbound(self._Inbound, self._Event:Wait())
end
-- Main
table.freeze(RemoteSignal)
return RemoteSignal :: {
	new: (Instance: SignalListener, Inbound: Helpers.MiddlewareCallbacks, Outbound: Helpers.MiddlewareCallbacks) -> RemoteSignal;
}