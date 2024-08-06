--!strict
-- Module
--[=[
	@class RemoteProperty

	Weaver's built-in implementation for RemoteEvents.

	This is an interface meant to make using RemoteEvents much easier, with functions identical to [Signal].
]=]--
local RemoteProperty: RemotePropertyImpl = {} :: RemotePropertyImpl

RemoteProperty.__index = RemoteProperty
RemoteProperty.__tostring = function(_self: RemotePropertyImpl): string
	return "RemoteProperty"
end
-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
-- Modules
local Weaver = script.Parent.Parent
local Internals = Weaver.Internals

local Clients = require(Internals.Clients)
local Helpers = require(Internals.Helpers)

local Signal = require(Weaver.Util.Signal)
-- Types
type RemotePropertyImpl =
{
	-- Variables
	__index: RemotePropertyImpl;
	__tostring: (self: RemotePropertyImpl) -> string;
	-- Methods
	--[=[
		Constructs a new RemoteProperty object.
	]=]--
	new: (Instance: RemoteFunction, Event: RemoteEvent, Default: any?) -> RemoteProperty;
	--[=[
		Sets the default value of the RemoteProperty, clearing all clients' custom values.
	]=]--
	Set: (self: RemoteProperty, Default: any?) -> ();
	--[=[
		Sets the default value of the RemoteProperty without clearing all clients' custom values.
	]=]--
	SetDefault: (self: RemoteProperty, Default: any?) -> ();
	--[=[
		Sets the value of this RemoteProperty for a specific client.
	]=]--
	SetFor: (self: RemoteProperty, For: Player, Value: any?) -> ();
	--[=[
		Sets the value of this RemoteProperty for the clients specified.
	]=]--
	SetForEach: (self: RemoteProperty, For: { Player }, Value: any?) -> ();
	--[=[
		Sets the value of this RemoteProperty for all clients in the game, except for the clients specified.
	]=]--
	SetExcept: (self: RemoteProperty, Excluding: { Player }, Value: any?) -> ();
	--[=[
		Sets the value of this RemoteProparty for all clients in the game, using a filter to specify which clients have their values set.
	]=]--
	SetFilter: (self: RemoteProperty, Filter: (Client: Player, Value: any?) -> boolean, Value: any?) -> ();
	--[=[
		Clears all clients' custom values.
	]=]--
	Clear: (self: RemoteProperty) -> ();
	--[=[
		Clears the value set for a specific client.
	]=]--
	ClearFor: (self: RemoteProperty, For: Player) -> ();
	--[=[
		Clears the values set for the clients specified.
	]=]--
	ClearForEach: (self: RemoteProperty, For: { Player }) -> ();
	--[=[
		Clears the value of all clients in the game, except for the clients specified.
	]=]--
	ClearExcept: (self: RemoteProperty, Excluding: { Player }) -> ();
	--[=[
		Clears the value of all clients in the game, using a filter to specify which clients receive the event.
	]=]--
	ClearFilter: (self: RemoteProperty, Filter: (Client: Player) -> boolean) -> ();
	--[=[
		Gets the current value of the RemoteProperty.
	]=]--
	Get: (self: RemoteProperty) -> any?;
	--[=[
		Gets the current value of the RemoteProperty for `Client`.
	]=]--
	GetFor: (self: RemoteProperty, Client: Player) -> any?;
}
--[=[
	@type RemoteConnectionCallback (...any) -> () | (Client: Player, ...any)
	@within RemoteProperty
]=]--
type RemoteConnectionCallback = (...any) -> () | (Client: Player, ...any) -> ()
--[=[
	Fires when the RemoteProperty's value is changed.

	@client

	@prop Changed Signal
	@within RemoteProperty
]=]--
export type RemoteProperty = typeof(setmetatable({} :: {
	Changed: Signal.Signal;

	_Values: { [Player]: any? };
	_Default: any?;

	_Instance: RemoteFunction;
	_Event: RemoteEvent;
}, {} :: RemotePropertyImpl))
-- Constants
local IS_SERVER: boolean = RunService:IsServer()
-- Functions
-- Private
local function GetValue(Value: any?): any?
	return if Value == Helpers.NONE then nil else Value
end
-- Public
--[=[
	Constructs a new RemoteProperty object.
	@private

	@param From RemoteFunction -- The RemoteFunction to hook.
	@param Default any? -- The default value of the RemoteProperty.

	@return RemoteProperty
]=]--
function RemoteProperty.new(From: RemoteFunction, Event: RemoteEvent, Default: any?): RemoteProperty
	local self =
	{
		_Instance = From;
		_Event = Event;
	}
	if IS_SERVER then
		-- These values are only set on the server
		self._Default = Default
		self._Values = {}

		Players.PlayerRemoving:Connect(function(Client: Player): ()
			self._Values[Client] = nil
		end)
	else
		self.Changed = Signal.new()
		Event.OnClientEvent:Connect(function(Value: any?): ()
			self.Changed:Fire(Value)
		end)
	end

	setmetatable(self, RemoteProperty)
	if IS_SERVER then
		From.OnServerInvoke = function(Client: Player): any?
			return self:GetFor(Client)
		end
	end
	return table.freeze(self)
end
if IS_SERVER then
	--[=[
		Sets the default value of the RemoteProperty, clearing all clients' custom values.

		@server
	]=]--
	function RemoteProperty:Set(Default: any?): ()
		self._Default = Default
		for _, Client: Player in Clients.Array do
			if self:GetFor(Client) == Default then
				continue
			end
			self._Event:FireClient(Client, Default)
		end
		table.clear(self._Values)
	end
	--[=[
		Sets the default value of the RemoteProperty without clearing all clients' custom values.

		@server
	]=]--
	function RemoteProperty:SetDefault(Default: any?): ()
		if self._Default == Default then
			return
		end

		self._Default = Default
		for _, Client: Player in Clients.Array do
			if self._Values[Client] then
				continue
			end
			self._Event:FireClient(Client, Default)
		end
	end
	--[=[
		Sets the value of this RemoteProperty for a specific client.

		@server
	]=]--
	function RemoteProperty:SetFor(For: Player, Value: any?): ()
		if self:GetFor(For) == Value then
			return
		end

		self._Values[For] = if Value == nil then Helpers.NONE else Value
		self._Event:FireClient(For, Value)
	end
	--[=[
		Sets the value of this RemoteProperty for the clients specified.

		@server
	]=]--
	function RemoteProperty:SetForEach(For: { Player }, Value: any?): ()
		for _, Client: Player in For do
			self:SetFor(Client, Value)
		end
	end
	--[=[
		Sets the value of this RemoteProperty for all clients in the game, except for the clients specified.

		@server
	]=]--
	function RemoteProperty:SetExcept(Excluding: { Player }, Value: any?): ()
		local For: { Player } = table.clone(Clients.Array)
		for _, Client: Player in Excluding do
			For[Clients.Map[Client]] = nil
		end
		self:SetForEach(For, Value)
	end
	--[=[
		Sets the value of this RemoteProparty for all clients in the game, using a filter to specify which clients have their values set.

		@server
	]=]--
	function RemoteProperty:SetFilter(Filter: (Client: Player, Value: any?) -> boolean, Value: any?): ()
		local For: { Player } = {}
		for _, Client: Player in Clients.Array do
			if not Filter(Client, Value) then
				continue
			end
			For[Clients.Map[Client]] = Client
		end
		self:SetForEach(For, Value)
	end
	--[=[
		Clears all clients' custom values.

		@server
	]=]--
	function RemoteProperty:Clear(): ()
		self:Set(self._Default)
	end
	--[=[
		Clears the value set for a specific client.

		@server
	]=]--
	function RemoteProperty:ClearFor(For: Player): ()
		local Last: any? = self:GetFor(For)
		self._Values[For] = nil

		if Last ~= self._Default then
			self._Event:FireClient(For, self._Default)
		end
	end
	--[=[
		Clears the values set for the clients specified.

		@server
	]=]--
	function RemoteProperty:ClearForEach(For: { Player }): ()
		for _, Client: Player in For do
			self:ClearFor(Client)
		end
	end
	--[=[
		Clears the value of all clients in the game, except for the clients specified.

		@server
	]=]--
	function RemoteProperty:ClearExcept(Excluding: { Player }): ()
		local For: { Player } = table.clone(Clients.Array)
		for _, Client: Player in Excluding do
			For[Clients.Map[Client]] = nil
		end
		self:ClearForEach(For)
	end
	--[=[
		Clears the value of all clients in the game, using a filter to specify which clients receive the event.

		@server
	]=]--
	function RemoteProperty:ClearFilter(Filter: (Client: Player) -> boolean): ()
		local For: { Player } = {}
		for _, Client: Player in Clients.Array do
			if not Filter(Client) then
				continue
			end
			For[Clients.Map[Client]] = Client
		end
		self:ClearForEach(For)
	end
	--[=[
		Gets the current value of the RemoteProperty.

		@server
	]=]--
	function RemoteProperty:Get(): any?
		return self._Default
	end
	--[=[
		Gets the current value of the RemoteProperty for `Client`.

		@server
	]=]--
	function RemoteProperty:GetFor(Client: Player): any?
		local Value: any? = self._Values[Client]
		return if Value ~= nil then GetValue(Value) else self._Default
	end
else
	--[=[
		Gets the current value of the RemoteProperty.

		@client
	]=]--
	function RemoteProperty:Get(): any?
		return self._Instance:InvokeServer()
	end
end
-- Main
return table.freeze(RemoteProperty) :: {
	new: (Instance: RemoteFunction, Event: RemoteEvent, Default: any?) -> RemoteProperty;
}