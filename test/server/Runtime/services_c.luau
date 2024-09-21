--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Service
local Signal = Weaver.Util.Signal -- Util is a module, and Signal is already required!
local EventFiringService = Weaver.CreateService{
	Name = "EventFiringService";
	SomethingHappened = Signal.new();
}
function EventFiringService:WeaverStart(): ()
	-- Fire SomethingHappened in WeaverStart,
	-- as the connections from other services should be ready
	self.SomethingHappened:Fire()
end
-- Main
return EventFiringService