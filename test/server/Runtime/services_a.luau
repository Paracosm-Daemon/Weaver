--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Service
local Service = Weaver.CreateService{
	Name = "ServiceA";
	Attributes = {
		isService = true;
	};
	Client = {
		Shoot = Weaver.CreateRemoteSignal();
	};
}
-- Main
return Service