--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Service
-- This is being ran on the server
local MessagingService = game:GetService("MessagingService")
-- This will be the topic we post to
local POST_TOPIC: string = "GlobalMessages"
type Payload = { name: string, message: string }
-- First, create PostService
local PostService = Weaver.CreateService{ Name = "PostService" }
-- Then, create the remote signal.
-- Trying to use it before Weaver has started will throw an exception
PostService.Client.SendMessage = Weaver.CreateRemoteSignal()
-- Connections are done within WeaverInit so that they are ready on WeaverStart
function PostService:WeaverInit(): ()
	-- !!! Yields otherwise
	if not RunService:IsStudio() then
		-- First, subscribe to listen to payloads from SendMessage
		MessagingService:SubscribeAsync(POST_TOPIC, function(received: { Data: Payload, Sent: number }): ()
			local payload: Payload = received.Data
			print("Player", payload.name, "sent", payload.message)
		end)
	end
	-- Then, connect SendMessage.
	-- This will take a string as its message parameter
	self.Client.SendMessage:Connect(function(client: Player, message: string): ()
		-- Normally, you'd want to add sanity checks,
		-- but this is just an example
		local payload: Payload = {
			name = client.Name;
			message = message;
		}
		MessagingService:PublishAsync(POST_TOPIC, payload)
	end)
end
-- Main
return PostService