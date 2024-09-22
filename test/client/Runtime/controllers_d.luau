--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Controller
local Signal = Weaver.Util.Signal
local MagicController = Weaver.CreateController{ Name = "MagicController" }

MagicController.MagicDone = Signal.new()
MagicController.isPreparingTrick = false

function MagicController:PerformMagic(): ()
	if self.isPreparingTrick then
		warn("Wait for the magician to set up the magic trick!")
		return
	end
	print("🎩🪄🐇")

	self.MagicDone:Fire()
	self.isPreparingTrick = true
	-- After the magic trick is done, prepare for the next trick (this is a debounce)
	task.wait(15)
	self.isPreparingTrick = false

	print("The show is ready to start again!")
end
-- Main
function MagicController:WeaverStart(): ()
	task.defer(self.PerformMagic, self)
	self:PerformMagic()
end
return MagicController