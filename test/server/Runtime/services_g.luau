--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Service
local Service = Weaver.CreateService{ Name = "ServiceG" }
Service.Client.SomeSignal = Weaver.CreateRemoteSignal()

function Service.Client:IncrementNumber(value: number): number
	return value + 1
end
-- Main
return Service