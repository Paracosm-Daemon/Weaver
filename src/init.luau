--!strict
-- Services
local RunService = game:GetService("RunService")
-- Modules
local Internals = script.Internals
local Util = script.Util

local RemoteSignal = require(Internals.RemoteSignal)
local Signal = require(Util.Signal)

local WeaverClient = require(script.Client)
local WeaverServer = require(script.Server)
-- Types
export type SignalConnection = Signal.SignalConnection
export type Signal = Signal.Signal

export type RemoteSignal = RemoteSignal.RemoteSignal
-- Main
return (if RunService:IsServer() then WeaverServer else WeaverClient) :: typeof(WeaverServer) & typeof(WeaverClient)