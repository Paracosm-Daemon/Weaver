--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Service
local Module = Weaver.CreateService{ Name = script.Name }
Module.Client.Foo = Weaver.CreateRemoteSignal()

function Module.Client:Qux(Client: Player, Frobulations: number): (number, number)
	return Client.UserId + Frobulations, self.Server:Baz(Frobulations) :: number
end

function Module:Baz(Frobulations: number): number
	return 1 + Frobulations
end
function Module:WeaverInit(): ()
	self.Client.Foo:Connect(function(Client: Player, Bar: string): ()
		warn(Client, "said", Bar)
		self.Client.Foo:Fire(Client, Bar)
	end)
end

return Module