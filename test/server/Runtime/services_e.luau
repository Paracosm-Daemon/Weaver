--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Service
local MoneyService = Weaver.CreateService{ Name = "MoneyService" }
-- This will initialize as a RemoteProperty once Weaver is initialized
-- The value this is set to will be used as the default
MoneyService.Client.Money = 0
MoneyService.Client.AddMoney = Weaver.CreateRemoteSignal()

local Money: any -- This gets initialized in WeaverInit, so it can be used as a shorthand
-- This is in the server table, so this won't clash with the signal's name
function MoneyService:AddMoney(Client: Player, Amount: number): ()
	Money:SetFor(Client, Money:GetFor(Client) + Amount)
end
function MoneyService:WeaverInit(): ()
	-- Initialize our Money variable
	Money = self.Client.Money
	-- Hook our AddMoney signal to the AddMoney function aswell,
	-- so players can also give themselves money
	self.Client.AddMoney:Connect(function(Client: number, Amount: number): ()
		self:AddMoney(Client, Amount)
	end)
end
-- Main
return MoneyService