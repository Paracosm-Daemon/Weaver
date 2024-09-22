--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Service
local Service = Weaver.CreateService{
	Name = "ServiceB";
	Client = {
		ImportantCall = Weaver.CreateRemoteSignal();
		SomeProperty = 0;

		GetSomething = function(self): string
			return "Something"
		end;
	};

	someSharedValue = 123;
	someOtherSharedValue = "hello";
	someSharedValues = { 1, 2, 3 };
}
-- Main
return Service