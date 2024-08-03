--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Service
local Module = Weaver.CreateService{ Name = script.Name }
-- Variables
Module.Client.Remote = Weaver.CreateRemoteSignal()
-- Functions
-- Client
function Module.Client:Frobulate(Client: Player, Frobulations: number): number
	warn(Client, "caused a frobulation")
	return self.Server:Frobulate(Frobulations)
end
-- Server
function Module:Frobulate(Frobulations: number): number
	return 1 + Frobulations
end

function Module:WeaverInit(): ()
	print("foo")
	self.Client.Remote:Connect(function(Client: Player, Input: string): ()
		warn(Client, "input", Input)
		self.Client.Remote:Fire(Client, "quuz")
	end)
end
function Module:WeaverStart(): ()
	print("bar")
end
-- Main
return Module