--!strict
-- Module
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
		Connects a function to this signal.

		Executes when a client fires this signal.
	]=]--
	Connect: (self: RemoteSignal, Callback: ConnectionCallback) -> RBXScriptConnection;
	--[=[
		Fires to a specific client.
	]=]--
	Fire: (self: RemoteSignal, ...any) -> ();
	--[=[
		Fires to all clients in the game.
	]=]--
	FireAll: (self: RemoteSignal, Client: Player, ...any) -> ();
	--[=[
		Fires to all clients specified in `For`.
	]=]--
	FireFor: (self: RemoteSignal, For: { Player }, ...any) -> ();
	--[=[
		Fires to all clients in the game, except for the clients specified.
	]=]--
	FireExcept: (self: RemoteSignal, Excluding: { Player }, ...any) -> ();
}

type ConnectionCallback = (Client: Player, ...any) -> ()
export type SignalListener = Instance & {
	OnServerEvent: RBXScriptSignal<(Player, ...any)>;
	OnClientEvent: RBXScriptSignal<...any>;

	FireClient: ConnectionCallback;

	FireAllClients: (...any) -> ();
	FireServer: (...any) -> ();
}
export type RemoteSignal = typeof(setmetatable({} :: {
	_Instance: SignalListener;
}, {} :: RemoteSignalImpl))
-- Constants
local EXCEPTION_SERVER_ONLY: string = "Must be ran on the server to use this function"
local IS_SERVER: boolean = RunService:IsServer()
-- Variables
local Clients: { [number]: Player } = {}
local Hash: { [Player]: number } = {}

local Connected: number = 0
-- Functions
function RemoteSignal.new(From: SignalListener): RemoteSignal
	return setmetatable({ _Instance = From }, RemoteSignal)
end
function RemoteSignal:Connect(Callback: (...any) -> () | ConnectionCallback): RBXScriptConnection
	return
		if IS_SERVER then
			self._Instance.OnServerEvent:Connect(Callback :: ConnectionCallback)
		else
			self._Instance.OnClientEvent:Connect(Callback :: (...any) -> ())
end

function RemoteSignal:Fire(First: any, ...): ()
	if IS_SERVER then
		assert((typeof(First) == "Instance") and First:IsA("Player"), "The first argument of FireClient must be a player")
		self._Instance:FireClient(First, ...)

		return
	end
	self._Instance:FireServer(First, ...)
end
function RemoteSignal:FireAll(...): ()
	assert(IS_SERVER, EXCEPTION_SERVER_ONLY)
	self._Instance:FireAllClients(...)
end

function RemoteSignal:FireFor(For: { Player }, ...): ()
	assert(IS_SERVER, EXCEPTION_SERVER_ONLY)
	for _, Client: Player in For do
		self:Fire(Client, ...)
	end
end
function RemoteSignal:FireExcept(Excluding: { Player }, ...): ()
	assert(IS_SERVER, EXCEPTION_SERVER_ONLY)

	local For: { Player } = table.clone(Clients)
	for _, Client: Player in Excluding do
		For[Hash[Client]] = nil
	end
	self:FireFor(For, ...)
end
-- Main
if IS_SERVER then
	--[[
		Using GetPlayers() constantly can be expensive,
		so implement simple connections to store all clients easily
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
return RemoteSignal