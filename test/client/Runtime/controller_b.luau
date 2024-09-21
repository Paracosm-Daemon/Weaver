--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Controller
local client = Weaver.Player -- Weaver exposes the LocalPlayer as this Player property
local CharacterController = Weaver.CreateController{ Name = "CharacterController" }

function CharacterController:HandleCharacter(character: Model): ()
	-- Here, we set our cameraSubject to the character.
	-- In return, our camera now tracks our character's location!
	self.CameraController.cameraSubject = character
end
function CharacterController:WeaverStart(): ()
	-- Just so it's easier to access from our other functions,
	-- store CameraController in our controller.
	-- See below for a different way of using GetController
	self.CameraController = Weaver.GetController("CameraController")
	client.CharacterAdded:Connect(function(character: Model): ()
		self:HandleCharacter(character)
	end)

	local currentCharacter: Model? = client.Character
	if currentCharacter then
		self:HandleCharacter(currentCharacter)
	end
end
-- Main
return CharacterController