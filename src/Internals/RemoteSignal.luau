--!strict
-- Module
--[=[
	@class RemoteSignal

	Weaver's built-in implementation for RemoteEvents.

	This is an interface meant to make using RemoteEvents much easier, with functions identical to [Signal].
]=]--
local RemoteSignal: RemoteSignalImpl = {} :: RemoteSignalImpl

RemoteSignal.__index = RemoteSignal
RemoteSignal.__tostring = function(_self: RemoteSignalImpl): string
	return "RemoteSignal"
end
-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
-- Types
type RemoteSignalImpl =
{
	-- Variables
	__index: RemoteSignalImpl;
	__tostring: (self: RemoteSignalImpl) -> string;
	-- Methods
	new: (Instance: SignalListener) -> RemoteSignal;
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
		Connects `Callback` to this signal.

		Executes when a client fires this signal to the server, or vice versa.
	]=]--
	Connect: (self: RemoteSignal, Callback: RemoteConnectionCallback) -> RBXScriptConnection;
	--[=[
		Connects `Callback` to this signal in parallel. Useful with Parallel Luau.

		Executes when a client fires this signal to the server, or vice versa.
	]=]--
	ConnectParallel: (self: RemoteSignal, Callback: RemoteConnectionCallback) -> RBXScriptConnection;
	--[=[
		Connects `Callback` to this signal, disconnecting it once the signal has fired once.
	]=]--
	Once: (self: RemoteSignal, Callback: RemoteConnectionCallback) -> RBXScriptConnection;
	--[=[
		Waits for the event to fire before resuming the current thread.
	]=]--
	Wait: (self: RemoteSignal) -> (...any);
}
--[=[
	@type RemoteConnectionCallback (...any) -> () | (Client: Player, ...any)
	@within RemoteSignal
]=]--
type RemoteConnectionCallback = (...any) -> () | (Client: Player, ...any) -> ()
export type SignalListener = Instance & {
	OnServerEvent: RBXScriptSignal<(Player, ...any)>;
	OnClientEvent: RBXScriptSignal<...any>;

	FireClient: (Client: Player, ...any) -> ();

	FireAllClients: (...any) -> ();
	FireServer: (...any) -> ();
}
export type RemoteSignal = typeof(setmetatable({} :: {
	_Instance: SignalListener;
	_Event: RBXScriptSignal;
}, {} :: RemoteSignalImpl))
-- Constants
local IS_SERVER: boolean = RunService:IsServer()
-- Variables
local Clients: { [number]: Player } = {}
local Hash: { [Player]: number } = {}

local Connected: number = 0
-- Functions
function RemoteSignal.new(From: SignalListener): RemoteSignal
	return table.freeze(setmetatable({
		_Instance = From;
		_Event = if IS_SERVER then From.OnServerEvent else From.OnClientEvent;
	}, RemoteSignal))
end
if IS_SERVER then
	--[=[
		Fires to the specified client, from the server.

		**The first argument of `Fire` must be a [Player].**

		@server
		@param ... ...any -- The arguments to send over this RemoteSignal.
	]=]--
	function RemoteSignal:Fire(Client: Player, ...): ()
		assert((typeof(Client) == "Instance") and Client:IsA("Player"), "The first argument of FireClient on the server must be a player, got %s")
		self._Instance:FireClient(Client, ...)
	end
	--[=[
		Fires to all clients in the game.

		@server
		@param ... ...any
	]=]--
	function RemoteSignal:FireAll(...): ()
		self._Instance:FireAllClients(...)
	end
	--[=[
		Fires to all clients specified in `For`.

		@server
		@param For { Player }
		@param ... ...any
	]=]--
	function RemoteSignal:FireFor(For: { Player }, ...): ()
		for _, Client: Player in For do
			self._Instance:FireClient(Client, ...)
		end
	end
	--[=[
		Fires to all clients in the game, except for the clients specified.

		@server
		@param Excluding { Player }
		@param ... ...any
	]=]--
	function RemoteSignal:FireExcept(Excluding: { Player }, ...): ()
		local For: { Player } = table.clone(Clients)
		for _, Client: Player in Excluding do
			For[Hash[Client]] = nil
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
		self._Instance:FireServer(...)
	end
end
--[=[
	Connects `Callback` to this signal.

	Executes when a client fires this signal to the server, or vice versa.

	@param Callback RemoteConnectionCallback -- The function to connect.
	@return RBXScriptConnection
]=]--
function RemoteSignal:Connect(Callback: RemoteConnectionCallback): RBXScriptConnection
	return self._Event:Connect(Callback)
end
--[=[
	Connects `Callback` to this signal in parallel. Useful with Parallel Luau.

	Executes when a client fires this signal to the server, or vice versa.

	@param Callback RemoteConnectionCallback -- The function to connect.
	@return RBXScriptConnection
]=]--
function RemoteSignal:ConnectParallel(Callback: RemoteConnectionCallback): RBXScriptConnection
	return self._Event:ConnectParallel(Callback)
end
--[=[
	Connects `Callback` to this signal, disconnecting it once the signal has fired once.

	@param Callback RemoteConnectionCallback -- The function to connect.
	@return RBXScriptConnection
]=]--
function RemoteSignal:Once(Callback: RemoteConnectionCallback): RBXScriptConnection
	return self._Event:Once(Callback)
end
--[=[
	Waits for the event to fire before resuming the current thread.

	@yields
	@return ...any -- All of the data that the signal returned from one event.
]=]--
function RemoteSignal:Wait(): (...any)
	return self._Event:Wait()
end
-- Main
if IS_SERVER then
	--[[
		Using GetPlayers() constantly can be expensive,
		so I've implemented connections to store all clients
	]]--
	Players.PlayerAdded:Connect(function(Client: Player): ()
		Connected += 1

		Clients[Connected] = Client
		Hash[Client] = Connected
	end)
	Players.PlayerRemoving:Connect(function(Client: Player): ()
		local Index: number? = Hash[Client]
		if Index then
			table.remove(Clients, Index)
			Hash[Client] = nil
		end
		Connected -= 1
	end)

	Clients = Players:GetPlayers()
	Connected = #Clients

	for Index: number, Client: Player in Clients do
		Hash[Client] = Index
	end
end
return table.freeze(RemoteSignal) :: {
	new: (Instance: SignalListener) -> RemoteSignal;
}