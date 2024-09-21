--!strict
--[=[
	@class RemoteProperty

	Weaver's implementation of Knit's [RemoteProperties](https://sleitnick.github.io/RbxUtil/api/RemoteProperty/).

	Internally, these are simply RemoteEvents which can store different values for clients.
]=]--
-- Module
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

local Exceptions = require(Internals.Exceptions)
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
	new: (Instance: RemoteEvent, Default: any?) -> RemoteProperty;
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
	Fires when the RemoteProperty's value has changed for any player. The first parameter will always be the `Player`.

	If the default value for the RemoteProperty was changed rather than a specific player's value, the first parameter will be `nil`.

	@server

	@prop Changed Signal
	@within RemoteProperty
]=]--
--[=[
	Fires when the RemoteProperty's value has changed. Note that this won't fire if the value that the server sets is the same as your currently registered value.

	@client

	@prop Changed Signal
	@within RemoteProperty
]=]--
export type RemoteProperty = typeof(setmetatable({} :: {
	Changed: Signal.Signal;

	_Values: { [Player]: any };
	_Default: any?;

	_Once: { [Player]: boolean }?;
	_Threads: { thread }?;

	_Waiting: number?;
	_Instance: RemoteEvent;
}, {} :: RemotePropertyImpl))
-- Constants
local IS_SERVER: boolean = RunService:IsServer()
-- Functions
-- Private
local function GetValue(Value: any?): any?
	return if Value == Helpers.NONE then nil else Value
end
local function PlayerRemoving(Values: { [Player]: any }, Client: Player): ()
	Values[Client] = nil
end
-- Public
--[=[
	Constructs a new RemoteProperty object.
	@private

	@param From RemoteEvent -- The RemoteEvent to hook.
	@param Default any? -- The default value of the RemoteProperty.

	@return RemoteProperty
]=]--
function RemoteProperty.new(From: RemoteEvent, Default: any?): RemoteProperty
	local self =
	{
		Changed = Signal.new();
		_Instance = From;
	}

	if IS_SERVER then
		-- These values are only set on the server
		self._Default = Default

		self._Values = {}
		self._Once = {}

		Players.PlayerRemoving:Connect(function(Client: Player): ()
			self._Once[Client] = nil
			task.defer(PlayerRemoving, self._Values, Client)
		end)
	else
		local Threads: { thread } = {}

		self._Threads = Threads :: { thread }?
		self._Waiting = 0 :: number?

		From.OnClientEvent:Connect(function(Value: any?): ()
			local Last: any? = self._Default
			self._Default = if Value == nil then Helpers.NONE else Value

			if Last == nil then
				if self._Waiting == 0 then
					return
				end
				for Index: number = 1, self._Waiting :: number, 1 do
					task.spawn(Threads[Index], Value)
				end

				self._Threads = nil
				self._Waiting = nil

				return
			end
			self.Changed:Fire(Value)
		end)
		-- Fire once to receive the first value assigned to the client
		From:FireServer()
	end

	setmetatable(self, RemoteProperty)
	if IS_SERVER then
		From.OnServerEvent:Connect(function(Client: Player): ()
			if self._Once[Client] then
				return
			end

			self._Once[Client] = true
			From:FireClient(Client, self:GetFor(Client))
		end)
	end
	return self
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
			self._Instance:FireClient(Client, Default)
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
		self.Changed:Fire(nil, Default)

		for _, Client: Player in Clients.Array do
			if self._Values[Client] then
				continue
			end
			self._Instance:FireClient(Client, Default)
		end
	end
	--[=[
		Sets the value of this RemoteProperty for a specific client.

		@server
	]=]--
	function RemoteProperty:SetFor(For: Player, Value: any?): ()
		local Type: string = typeof(For)
		assert((Type == "Instance") and For:IsA("Player"), string.format(Exceptions.EXCEPTION_MUST_BE_TYPE, "For", "Player", `type { Type } with value { tostring(For) }`))

		local New: any = if Value == nil then Helpers.NONE else Value
		if self._Values[For] == New then
			return
		end

		self._Values[For] = New
		self._Instance:FireClient(For, Value)

		self.Changed:Fire(For, Value)
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
		local Type: string = typeof(For)
		assert((Type == "Instance") and For:IsA("Player"), string.format(Exceptions.EXCEPTION_MUST_BE_TYPE, "For", "Player", `type { Type } with value { tostring(For) }`))

		local Last: any? = self:GetFor(For)
		self._Values[For] = nil

		if Last ~= self._Default then
			self._Instance:FireClient(For, self._Default)
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
		return if Value == nil then self._Default else GetValue(Value)
	end
else
	--[=[
		Gets the current value of the RemoteProperty.

		:::caution Yielding

		This function will yield when you first call `:Get()` if the server has not sent a Changed event at least once. If this is an issue that worries you, try calling `:Get()` once in [`WeaverController:WeaverInit()`](WeaverClient#WeaverController) so that the value is guaranteed to exist.

		:::

		@yields
		@client
	]=]--
	function RemoteProperty:Get(): any?
		if self._Default == nil then
			assert(self._Threads and self._Waiting, "RemoteProperty was initialized incorrectly!")

			self._Waiting += 1
			self._Threads[self._Waiting] = coroutine.running()
			-- The resulting value will always return from this yield
			return coroutine.yield()
		end
		return GetValue(self._Default)
	end
end
-- Main
table.freeze(RemoteProperty)
return RemoteProperty :: {
	new: (Instance: RemoteEvent, Default: any?) -> RemoteProperty;
}