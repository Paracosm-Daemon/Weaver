--!strict
-- Module
local Lock: LockImpl = {} :: LockImpl
Lock.__index = Lock
-- Types
type LockImpl =
{
	-- Variables
	__index: LockImpl;
	-- Methods
	-- Public
	new: () -> Lock;

	Latch: (self: Lock, Callback: (Free: () -> ()) -> (), Tag: string?) -> ();
	Unlock: (self: Lock) -> ();
	-- Private
	_Finish: (self: Lock) -> ();
}
export type Lock = typeof(setmetatable({} :: {
	_Latches: number;
	_Total: number;

	_Unlocked: boolean;
}, {} :: LockImpl))
-- Constants
local TIMEOUT_PERIOD: number = 5.
-- Functions
function Lock.new(): Lock
	return setmetatable({
		_Unlocked = false;

		_Latches = 0;
		_Total = 0;
	}, Lock)
end

function Lock:Latch(Callback: (Free: () -> ()) -> (), Tag: string?): ()
	self._Latches += 1
	self._Total += 1

	local Index: string = if Tag then `{ Tag } ({ self._Total })` else tostring(self._Total)

	local Timeout: thread
	local Thread: thread?

	local Traceback: string = debug.traceback(nil, 2)
	local function Free(): ()
		self._Latches -= 1
		if (self._Latches <= 0) and self._Unlocked then
			self:_Finish()
		end

		Thread = nil
		if coroutine.status(Timeout) ~= "dead" then
			task.cancel(Timeout)
		end
	end
	Timeout = task.delay(TIMEOUT_PERIOD, function(): ()
		warn(`LOCK THREAD { Index } HAS REACHED THE { TIMEOUT_PERIOD }s TIMEOUT PERIOD\n{ Traceback }`)
		if Thread and (coroutine.status(Thread) ~= "dead") then
			task.cancel(Thread)
			Thread = nil
		end
	end)
	Thread = coroutine.create(function(): ()
		xpcall(Callback, function(Exception: any): ()
			warn(`LOCK THREAD { Index } ENCOUNTERED AN EXCEPTION: { Exception }\n{ Traceback }`)

			Thread = nil
			if coroutine.status(Timeout) ~= "dead" then
				task.cancel(Timeout)
			end
		end, Free)
	end)
	task.spawn(Thread :: thread, Free)
end
function Lock:Unlock(): ()
	if self._Latches <= 0 then
		self:_Finish()
		return
	end
	self._Unlocked = true
end

function Lock:_Finish(): ()
	warn(`{ self._Total } LOCK THREAD(S) SUCCESSFULLY RAN`)
	self._Unlocked = false

	self._Latches = 0
	self._Total = 0
end
-- Main
return table.freeze(Lock) :: {
	new: () -> Lock;
}