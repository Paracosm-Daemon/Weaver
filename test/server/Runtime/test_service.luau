--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver.Server)
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

		self.Client.Remote:FireAll("FireAll")
		self.Client.Remote:FireFor({ Client }, "FireFor")
		self.Client.Remote:FireExcept({ Client }, "FireExcept")
	end)
end
function Module:WeaverStart(): ()
	print("bar")
end
-- Main
return Module