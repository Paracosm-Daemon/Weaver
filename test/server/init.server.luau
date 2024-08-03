--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Main
print("Starting Weaver Server")
local Start: number = os.clock()

Weaver.AddServices(script.Runtime)
Weaver.Start()

local Benchmark: number = os.clock() - Start
print(string.format("Started Weaver Server in %.2fms", 1_000. * Benchmark))