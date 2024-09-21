--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Service
local EventHandlingService = Weaver.CreateService{ Name = "EventHandlingService" }
function EventHandlingService:WeaverInit(): ()
	-- First, we get the service
	local EventFiringService = Weaver.GetService("EventFiringService")
	-- Then, we connect an event to it
	EventFiringService.SomethingHappened:Connect(function(): ()
		print("Something happened!")
	end)
end
-- Main
return EventHandlingService