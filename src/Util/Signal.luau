--!strict
-- Module
--[=[
	@class Signal

	Weaver's built-in implementation for signals.

	This is meant to replace BindableEvents with simple and fast logic, omitting the need of Instances.
]=]--
local Signal: SignalImpl = {} :: SignalImpl
--[=[
	@class SignalConnection

	The connection class used by [Signal] objects.
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
	new: () -> Signal;
	--[=[
		Fires the signal with the specified data.
	]=]--
	Fire: (self: Signal, ...any) -> ();
	--[=[
		Connects `Callback` to this signal, creating a new `SignalConnection`.
	]=]--
	Connect: (self: Signal, Callback: ConnectionCallback) -> SignalConnection;
	--[=[
		Connects `Callback` to this signal in parallel, creating a new `SignalConnection`. Useful for Parallel Luau.
	]=]--
	ConnectParallel: (self: Signal, Callback: ConnectionCallback) -> SignalConnection;
	--[=[
		Connects `Callback` to this signal, disconnecting it once the signal has fired once.
	]=]--
	Once: (self: Signal, Callback: ConnectionCallback) -> SignalConnection;
	--[=[
		Waits for the event to fire before resuming the current thread.
	]=]--
	Wait: (self: Signal) -> (...any);
	-- Private
	_Disconnect: (self: Signal, Index: any) -> ();
}
type SignalConnectionImpl =
{
	-- Variables
	__index: SignalConnectionImpl;
	-- Methods
	new: (Callback: ConnectionCallback) -> SignalConnection;
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
	Fires the signal with the specified data.

	@param ... ...any
]=]--
function Signal:Fire(...): ()
	for Connection: SignalConnection in self._Connections do
		task.spawn(Connection._Callback, ...)
	end
end
--[=[
	Connects `Callback` to this signal, creating a new [SignalConnection].

	@param Callback ConnectionCallback -- The function to connect.
	@return SignalConnection
]=]--
function Signal:Connect(Callback: ConnectionCallback): SignalConnection
	local Connection: SignalConnection = SignalConnection.new(Callback)
	Connection._Finish = function(): ()
		self._Connections[Connection] = nil
	end

	Connection._Ref = self._Connections
	self._Connections[Connection] = true

	return Connection
end
--[=[
	Connects `Callback` to this signal in parallel, creating a new [SignalConnection]. Useful for Parallel Luau.

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
	Connects `Callback` to this signal, disconnecting it once the signal has fired once.

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
	@return ...any -- All of the data that the signal returned from one event.
]=]--
function Signal:Wait(): (...any)
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
	return setmetatable({
		Connected = true;

		_Callback = Callback;
		_Ref = Ref;
	}, SignalConnection) :: SignalConnection
end
--[=[
	Disconnects the connection, removing it from the [Signal] it is connected to.
]=]--
function SignalConnection:Disconnect(): ()
	self.Connected = false
	self._Finish()
end
-- Main
return table.freeze(Signal) :: {
	new: () -> Signal;
}