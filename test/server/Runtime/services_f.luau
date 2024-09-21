--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Service
local MyMultiStepService = Weaver.CreateService{
	Name = "Service";
	Client = {
		SomeExposedSignal = Weaver.CreateRemoteSignal();
	};
}

function MyMultiStepService:WeaverInit(): ()
	print("Init", self.Name)
	-- Connect some events here...
	self.Client.SomeExposedSignal:Connect(function(client: Player): ()
		warn(client, "fired my exposed signal!")
	end)
end
function MyMultiStepService:WeaverStart(): ()
	print("Start", self.Name)
	-- Fire some events or execute some functions here...
	local SomeOtherService = Weaver.GetService("SomeOtherService")
	SomeOtherService.SomeSignal:Fire(123)
end

-- Output:
-- Init Service
-- Start Service
-- Main
return MyMultiStepService