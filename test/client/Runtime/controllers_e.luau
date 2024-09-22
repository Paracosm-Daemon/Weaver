--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Controller
-- This is being ran on the client
local PointsController = Weaver.CreateController{ Name = "PointsController" }
local PointsService -- See the alternative method mentioned above

function PointsController:WeaverInit(): ()
	PointsService = Weaver.GetService("PointsService")
	PointsService.Points.Changed:Connect(function(newPoints: number): ()
		warn("Our points were changed to", newPoints)
	end)
end
function PointsController:WeaverStart(): ()
	print("Our starting points are", PointsService.Points:Get())
	-- Fire our AddPoints signal to get some points
	PointsService.AddPoints:Fire()
end
-- Output:
-- Our starting points are 0
-- Our points were changed to 10
-- Main
return PointsController