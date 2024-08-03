--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local Weaver = require(ReplicatedStorage.Weaver)
-- Main
local Start: number = os.clock()

Weaver.AddControllers(script.Runtime)
Weaver.Start()

local Benchmark: number = os.clock() - Start
print(string.format("Client took %.2fms", 1_000. * Benchmark))