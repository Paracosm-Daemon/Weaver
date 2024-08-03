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
local Connection: SignalConnectionImpl = {} :: SignalConnectionImpl

Signal.__index = Signal
Signal.__tostring = function(_self: SignalImpl): string
	return "Signal"
end

Connection.__index = Connection
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
		Disconnects the connection, removing it from the signal.
	]=]--
	Disconnect: (self: SignalConnection) -> ();
}
--[=[
	@type ConnectionCallback (...any) -> ()
	@within Signal
]=]--
type ConnectionCallback = (...any) -> ()

export type Signal = typeof(setmetatable({} :: {
	-- Variables
	_Connections: { [SignalConnection]: boolean };
}, {} :: SignalImpl))
export type SignalConnection = typeof(setmetatable({} :: {
	-- Variables
	-- Public
	Connected: boolean;
	-- Private
	_Callback: ConnectionCallback;
	_Finish: () -> ();
}, {} :: SignalConnectionImpl))
-- Functions
-- Signal
--[=[
	Constructs a new Signal object.

	@return Signal
]=]--
function Signal.new(): Signal
	return setmetatable({
		_Connections = {};
	}, Signal)
end
--[=[
	Fires the signal with the specified data.

	@param ... ...any
]=]--
function Signal:Fire(...): ()
	for Connected: SignalConnection in self._Connections do
		task.spawn(Connected._Callback, ...)
	end
end
--[=[
	Connects `Callback` to this signal, creating a new [SignalConnection].

	@param Callback ConnectionCallback -- The function to connect.
	@return SignalConnection
]=]--
function Signal:Connect(Callback: ConnectionCallback): SignalConnection
	local Connected: SignalConnection = Connection.new(Callback)
	Connected._Finish = function(): ()
		self._Connections[Connected] = nil
	end
	self._Connections[Connected] = true
	return Connected
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
	local Connected: SignalConnection
	Connected = self:Connect(function(...): ()
		task.spawn(Callback, ...)
		Connected:Disconnect()
	end)
	return Connected
end
--[=[
	Waits for the event to fire before resuming the current thread.

	@yields
	@return ...any -- All of the data that the signal returned from one event.
]=]--
function Signal:Wait(): (...any)
	local Thread: thread = coroutine.running()
	local Connected: SignalConnection

	Connected = self:Connect(function(...): ()
		task.spawn(Thread, ...)
		Connected:Disconnect()
	end)
	return coroutine.yield()
end
-- Connection
function Connection.new(Callback: ConnectionCallback): SignalConnection
	return setmetatable({
		Connected = true;
		_Callback = Callback;
	}, Connection) :: SignalConnection
end
--[=[
	Disconnects the connection, removing it from the signal.
	@within SignalConnection
]=]--
function Connection:Disconnect(): ()
	self.Connected = false
	self._Finish()
end
-- Main
return Signal