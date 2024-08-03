--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Main
local Start: number = os.clock()

Weaver.AddServices(script.Runtime)
Weaver.Start()

local Benchmark: number = os.clock() - Start
print(string.format("Server took %.2fms", 1_000. * Benchmark))