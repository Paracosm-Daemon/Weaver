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
```

If you would prefer to get your controllers in a different way, you can simply create the variables related to the controllers you want to get at the beginning of your module, then initialize them on WeaverInit. See below if you would like to use the alternative method.

<details>
<summary>Different GetController method</summary>

```lua
local Controller = Weaver.CreateController{ Name = "Controller" }
local OtherController -- Leave this uninitialized for now!

function Controller:WeaverInit(): ()
	OtherController = Weaver.GetController("OtherController")
end
function Controller:WeaverStart(): ()
	OtherController:DoSomething() -- This will work, since our controller was initialized in WeaverInit
end
```

This same logic can also be done for services.
</details>

With our character and camera setup, we've designed our controllers to handle their own purposes while being able to share values from one to the other. This same principle can be applied to all sorts of controllers, as this same logic can be used to share a number value between controllers, check if a controller is on a debounce, or they can be used as signals. Since Weaver isn't too restrictive, you are able to make controllers do almost anything.

```lua
local Signal = Weaver.Util.Signal
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

With some controllers, you may have to communicate with the server. Weaver makes this easy with [`WeaverClient.GetService()`](/api/WeaverClient#GetService), which loads a service, meaning its methods, signals, properties, and attributes will all be available once you load the service. Let's say that we would like to communicate to a points service to increment the client's points. First, we need our points service:

```lua
-- This is being ran on the server
local PointsService = Weaver.CreateService{ Name = "PointsService" }

PointsService.Client.Points = 0 -- This is a RemoteProperty! Our starting points will be 0
PointsService.Client.AddPoints = Weaver.CreateRemoteSignal() -- Our signal to add more points

function PointsService:WeaverInit(): ()
	-- We'll be storing this as a variable
	-- so that we don't need to write self.Client.Points
	-- every time we want to access it
	local Points: RemoteProperty = self.Client.Points
	self.Client.AddPoints:Connect(function(Client: Player)
		-- This will add 10 points every time the client fires AddPoints
		Points:SetFor(Client, 10 + Points:GetFor(Client))
	end)
end
```

In our controller, we want to fire AddPoints to update our points. Here's how we could hook a controller to PointsService:

```lua
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
```

Generally, controllers do not need to access the networking of services, meaning your entire game could be solely reliant on controllers without the use of services. The only times you may need to access a service are to transceive data, such as settings or any client-specific game data that needs to be stored.
