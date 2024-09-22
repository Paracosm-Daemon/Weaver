--!strict
--[=[
	@class Signal

	Weaver's built-in implementation for signals.

	This is meant to replace [BindableEvents](https://create.roblox.com/docs/reference/engine/classes/BindableEvent) with simple and fast logic, omitting the need of Instances.
]=]--
-- Module
local Signal: SignalImpl = {} :: SignalImpl
--[=[
	@class SignalConnection

	The connection class used by [Signal] objects.
]=]--
--[=[
	If the [SignalConnection] is connected to a [Signal], this value will be `true`, otherwise `false`.

	@prop Connected boolean
	@within SignalConnection
]=]--
local SignalConnection: SignalConnectionImpl = {} :: SignalConnectionImpl

Signal.__index = Signal
Signal.__tostring = function(_self: SignalImpl): string
	return "Signal"
end

SignalConnection.__index = SignalConnection
-- Types
type SignalImpl =
{
	-- Variables
	__index: SignalImpl;
	__tostring: (self: SignalImpl) -> string;
	-- Methods
	-- Public
	--[=[
		Constructs a new Signal object.
	]=]--
	new: () -> Signal;
	--[=[
		Fires the Signal with the specified data.
	]=]--
	Fire: (self: Signal, ...any) -> ();
	--[=[
		Connects `Callback` to this Signal, creating a new `SignalConnection`.
	]=]--
	Connect: (self: Signal, Callback: ConnectionCallback) -> SignalConnection;
	--[=[
		Connects `Callback` to this Signal in parallel, creating a new `SignalConnection`. Useful for Parallel Luau.
	]=]--
	ConnectParallel: (self: Signal, Callback: ConnectionCallback) -> SignalConnection;
	--[=[
		Connects `Callback` to this Signal, disconnecting it once the Signal has fired once.
	]=]--
	Once: (self: Signal, Callback: ConnectionCallback) -> SignalConnection;
	--[=[
		Waits for the event to fire before resuming the current thread.
	]=]--
	Wait: (self: Signal) -> ...any;
	-- Private
	_Disconnect: (self: Signal, Index: any) -> ();
}
type SignalConnectionImpl =
{
	-- Variables
	__index: SignalConnectionImpl;
	-- Methods
	new: (Callback: ConnectionCallback, Ref: ConnectionsMap) -> SignalConnection;
	--[=[
		Disconnects the connection, removing it from the Signal it is connected to.
	]=]--
	Disconnect: (self: SignalConnection) -> ();
}
--[=[
	@type ConnectionCallback (...any) -> ()
	@within Signal
]=]--
type ConnectionCallback = (...any) -> ()
type ConnectionsMap = { [SignalConnection]: boolean }

export type Signal = typeof(setmetatable({} :: {
	-- Variables
	_Connections: ConnectionsMap;
}, {} :: SignalImpl))
export type SignalConnection = typeof(setmetatable({} :: {
	-- Variables
	-- Public
	Connected: boolean;
	-- Private
	_Callback: ConnectionCallback;
	_Ref: ConnectionsMap;
}, {} :: SignalConnectionImpl))
-- Functions
-- Signal
--[=[
	Constructs a new Signal object.

	@return Signal
]=]--
function Signal.new(): Signal
	return table.freeze(setmetatable({
		_Connections = {};
	}, Signal))
end
--[=[
	Fires the Signal with the specified data.

	@param ... ...any
]=]--
function Signal:Fire(...): ()
	for Connection: SignalConnection in self._Connections do
		task.spawn(Connection._Callback, ...)
	end
end
--[=[
	Connects `Callback` to this Signal, creating a new [SignalConnection].

	@param Callback ConnectionCallback -- The function to connect.
	@return SignalConnection
]=]--
function Signal:Connect(Callback: ConnectionCallback): SignalConnection
	return SignalConnection.new(Callback, self._Connections)
end
--[=[
	Connects `Callback` to this Signal in parallel, creating a new [SignalConnection]. Useful for Parallel Luau.

	@param Callback ConnectionCallback -- The function to connect.
	@return SignalConnection
]=]--
function Signal:ConnectParallel(Callback: ConnectionCallback): SignalConnection
	return self:Connect(function(...): ()
		task.desynchronize()
		Callback(...)
	end)
end
--[=[
	Connects `Callback` to this Signal, disconnecting it once the Signal has fired once.

	@param Callback ConnectionCallback -- The function to connect.
	@return SignalConnection
]=]--
function Signal:Once(Callback: ConnectionCallback): SignalConnection
	local Connection: SignalConnection
	Connection = self:Connect(function(...): ()
		task.spawn(Callback, ...)
		Connection:Disconnect()
	end)
	return Connection
end
--[=[
	Waits for the event to fire before resuming the current thread.

	@yields
	@return ...any -- All of the data that the Signal returned from one event.
]=]--
function Signal:Wait(): ...any
	local Thread: thread = coroutine.running()
	local Connection: SignalConnection

	Connection = self:Connect(function(...): ()
		task.spawn(Thread, ...)
		Connection:Disconnect()
	end)
	return coroutine.yield()
end
-- Connection
function SignalConnection.new(Callback: ConnectionCallback, Ref: ConnectionsMap): SignalConnection
	local self: SignalConnection = setmetatable({
		Connected = true;

		_Callback = Callback;
		_Ref = Ref;
	}, SignalConnection)
	Ref[self] = true
	return self
end
--[=[
	Disconnects the connection, removing it from the [Signal] it is connected to.
]=]--
function SignalConnection:Disconnect(): ()
	self.Connected = false
	self._Ref[self] = nil
end
-- Main
table.freeze(Signal)
return Signal :: {
	new: () -> Signal;
}