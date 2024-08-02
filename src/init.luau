--!strict
-- Services
local RunService = game:GetService("RunService")
-- Modules
local WeaverClient = require(script.Client)
local WeaverServer = require(script.Server)
-- Main
export type WeaverController = WeaverClient.WeaverController
export type WeaverService = WeaverServer.WeaverService

return (if RunService:IsServer() then WeaverServer else WeaverClient) :: (WeaverServer.WeaverImpl & WeaverClient.WeaverImpl)