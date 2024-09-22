--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Controller
local CameraController = Weaver.CreateController{ Name = "CameraController" }
CameraController.cameraSubject = nil :: PVInstance?
-- Here's our function for updating the camera
function CameraController:UpdateCamera(): ()
	-- (Commented out since it affects the real camera, but this works tested)
	--[[
	local currentCamera: Camera = workspace.CurrentCamera
	currentCamera.CameraType = Enum.CameraType.Scriptable
	-- This will use our cameraSubject property to calculate the camera's position
	local cameraSubject: PVInstance? = self.cameraSubject
	if cameraSubject ~= nil then
		currentCamera.CFrame = cameraSubject:GetPivot()
	end
	]]--
end
function CameraController:WeaverStart(): ()
	-- Connect our UpdateCamera function to RenderStepped
	RunService:BindToRenderStep("UpdateCamera", Enum.RenderPriority.Camera.Value, function(): ()
		self:UpdateCamera()
	end)
	self:UpdateCamera()
end
-- Main
return CameraController