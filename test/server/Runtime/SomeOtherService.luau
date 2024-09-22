--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
local Signal = Weaver.Util.Signal
-- Service
local Service = Weaver.CreateService{
	SomeSignal = Signal.new();
	Name = "SomeOtherService";
}
-- Main
return Service