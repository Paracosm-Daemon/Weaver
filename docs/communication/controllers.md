---
sidebar_position: 2
---

# Controllers

Controllers have a similar API and functionality to services. The only difference is that controllers and services are separate; controllers are the client's version of services. This means that they are also tables, and similarly to [WeaverServices](/api/WeaverServer#WeaverService), are also able to be created in modules.

## Construction

When creating a controller, the only key needed, much like a [WeaverService](/api/WeaverServer#WeaverService), is the `Name` property.

```lua
local Controller = Weaver.CreateController{ Name = "Controller" }
```

One difference between controllers and services is that controllers do not have a construction phase, where they are created and turned into a folder internally. This means that there is no `Attributes` or `Client`-adjacent tables, rather the controller itself will store all that it needs. This means that communication between two controllers is simple; all you need to do is call [`WeaverClient.GetController()`](/api/WeaverClient#GetController) within WeaverInit or WeaverStart.

## Sharing

Let's say that we have two controllers, one for controlling the camera, and one for controlling the character. Let's say that our camera controller needs a camera subject to function:

```lua
local CameraController = Weaver.CreateController{ Name = "CameraController" }
CameraController.cameraSubject = nil :: PVInstance?
-- Here's our function for updating the camera
function CameraController:UpdateCamera(): ()
	local currentCamera: Camera = workspace.CurrentCamera
	currentCamera.CameraType = Enum.CameraType.Scriptable
	-- This will use our cameraSubject property to calculate the camera's position
	local cameraSubject: PVInstance? = self.cameraSubject
	if cameraSubject ~= nil then
		currentCamera.CFrame = cameraSubject:GetPivot()
	end
end
function CameraController:WeaverStart(): ()
	-- Connect our UpdateCamera function to RenderStepped
	RunService:BindToRenderStep("UpdateCamera", Enum.RenderPriority.Camera.Value, function(): ()
		self:UpdateCamera()
	end)
	self:UpdateCamera()
end
```

Our character controller can supply that. So, our setup should look something like this:

```lua
local client = Weaver.Player -- Weaver exposes the LocalPlayer as this Player property
local CharacterController = Weaver.CreateController{ Name = "CharacterController" }

function CharacterController:HandleCharacter(character: Model): ()
	-- Here, we set our cameraSubject to the character.
	-- In return, our camera now tracks our character's location!
	self.CameraController.cameraSubject = character
end
function CharacterController:WeaverStart(): ()
	-- Just so it's easier to access from our other functions,
	-- store CameraController in our controller
	self.CameraController = Weaver.GetController("CameraController")

	local currentCharacter: Model? = client.Character
	client.CharacterAdded:Connect(function(character: Model): ()
		self:HandleCharacter(character)
	end)
	if currentCharacter then
		self:HandleCharacter(currentCharacter)
	end
end
```

With this setup, we've designed our controllers to handle their own purposes while being able to share values from one to the other. This same principle can be applied to all sorts of controllers, as this same logic can be used to share a number value between controllers, check if a controller is on a debounce, or they can be used as signals. Since Weaver isn't too restrictive, you are able to make controllers do pretty much anything.

```lua
local MagicController = Weaver.CreateController{ Name = "MagicController" }

MagicController.MagicDone = Signal.new()
MagicController.isPreparingTrick = false

function MagicController:PerformMagic(): ()
	if self.isPreparingTrick then
		warn("Wait for the magician to set up the magic trick!")
		return
	end
	print("🎩🪄🐇")

	self.MagicDone:Fire()
	self.isPreparingTrick = true
	-- After the magic trick is done, prepare for the next trick (this is a debounce)
	task.wait(15)
	self.isPreparingTrick = false

	print("The show is ready to start again!")
end
```

## Communication

With some controllers, you may have to communicate with the server. Weaver makes this easy with [`WeaverClient.GetService()`](/api/WeaverClient#GetService), which loads a service, meaning its methods, signals, properties, and attributes.
