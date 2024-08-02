--!strict
-- Module
local Signal: SignalImpl = {} :: SignalImpl
local Connection: ConnectionImpl = {} :: ConnectionImpl

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
		Waits for the event to fire before resuming the current thread.

		Returns what data the signal passed through.
	]=]--
	Wait: (self: Signal) -> (...any);
	--[=[
		Connects `Callback` to this signal, creating a new `Connection`.
	]=]--
	Connect: (self: Signal, Callback: ConnectionCallback) -> Connection;
	--[=[
		Connects `Callback` to this signal, disconnecting it once the signal has fired once.
	]=]--
	Once: (self: Signal, Callback: ConnectionCallback) -> Connection;
	-- Private
	_Disconnect: (self: Signal, Index: any) -> ();
}
type ConnectionImpl =
{
	-- Variables
	__index: ConnectionImpl;
	-- Methods
	new: (Callback: ConnectionCallback) -> Connection;
	--[=[
		Disconnects the connection, removing it from the signal.
	]=]--
	Disconnect: (self: Connection) -> ();
}

type ConnectionIndex = typeof(newproxy(false))
type ConnectionCallback = (...any) -> ()

export type Signal = typeof(setmetatable({} :: {
	-- Variables
	_Connections: { [Connection]: boolean };
}, {} :: SignalImpl))
export type Connection = typeof(setmetatable({} :: {
	-- Variables
	-- Public
	Connected: boolean;
	-- Private
	_Callback: ConnectionCallback;
	_Finish: () -> ();
}, {} :: ConnectionImpl))
-- Functions
function Signal.new(): Signal
	return setmetatable({
		_Connections = {};
	}, Signal)
end
function Signal:Fire(...): ()
	for Connected: Connection in self._Connections do
		task.spawn(Connected._Callback, ...)
	end
end

function Signal:Connect(Callback: ConnectionCallback): Connection
	local Connected: Connection = Connection.new(Callback)
	Connected._Finish = function(): ()
		self._Connections[Connected] = nil
	end
	self._Connections[Connected] = true
	return Connected
end
function Signal:Once(Callback: ConnectionCallback): Connection
	local Connected: Connection
	Connected = self:Connect(function(...): ()
		task.spawn(Callback, ...)
		Connected:Disconnect()
	end)
	return Connected
end
function Signal:Wait(): (...any)
	local Thread: thread = coroutine.running()
	local Connected: Connection

	Connected = self:Connect(function(...): ()
		task.spawn(Thread, ...)
		Connected:Disconnect()
	end)
	return coroutine.yield()
end

function Connection.new(Callback: ConnectionCallback): Connection
	return setmetatable({
		Connected = true;
		_Callback = Callback;
	}, Connection) :: Connection
end
function Connection:Disconnect(): ()
	self.Connected = false
	self._Finish()
end
-- Main
return Signal