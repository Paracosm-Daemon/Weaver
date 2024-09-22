--!strict
--[=[
	@private
	@ignore

	@class Helpers

	Weaver's general utility module to bridge boilerplate between the server and client.
]=]--
-- Services
local RunService = game:GetService("RunService")
-- Modules
local Internals = script.Parent
local Exceptions = require(Internals.Exceptions)
-- Module
local Helpers =
{
	EMPTY_MIDDLEWARE = table.freeze{};
	NONE = newproxy(false);
}
-- Types
export type MiddlewareCallback = (...any) -> boolean
export type MiddlewareCallbacks = { MiddlewareCallback }

export type Middleware = { Inbound: (MiddlewareCallback | MiddlewareCallbacks)?, Outbound: (MiddlewareCallback | MiddlewareCallbacks)? }

export type Marker = typeof(newproxy(false))
export type None = typeof(Helpers.NONE)
-- Constants
local IS_SERVER: boolean = RunService:IsServer()
-- Functions
--[=[
	Creates a marker with the specified `Name`

	@param Name string
]=]--
function Helpers.CreateMarker(Name: string): Marker
	local Marker: Marker = newproxy(true)
	getmetatable(Marker).__tostring = function(_self: { [any]: any }): string
		return Name
	end
	return Marker
end
if IS_SERVER then
	--[=[
		Used for processing inbound/outbound functions with multiple arguments

		@server
		@yields

		@param Callbacks MiddlewareCallbacks
		@param Client Player
		@param ... ...any
	]=]--
	function Helpers.ProcessMiddleware(Callbacks: MiddlewareCallbacks, Client: Player, ...): ...any
		local Arguments: { any }
		local Length: number

		for _, Callback: MiddlewareCallback in Callbacks do
			Arguments =
				if Arguments then
					-- Simplest way of unpacking the arguments efficiently
					{ Callback(Client, table.unpack(Arguments, 2, Length)) }
				else
					{ Callback(Client, ...) }
			Length = #Arguments
			if Arguments[1] ~= true then
				return table.unpack(Arguments, 2, Length)
			end
		end
		if Length == 1 then
			return nil
		end
		return table.unpack(Arguments, 2, Length)
	end
else
	--[=[
		Used for processing inbound/outbound functions with multiple arguments

		@client
		@yields

		@param Callbacks MiddlewareCallbacks
		@param ... ...any
	]=]--
	function Helpers.ProcessMiddleware(Callbacks: MiddlewareCallbacks, ...): ...any
		local Arguments: { any }
		local Length: number

		for _, Callback: MiddlewareCallback in Callbacks do
			Arguments =
				if Arguments then
					-- Simplest way of unpacking the arguments efficiently
					{ Callback(table.unpack(Arguments, 2, Length)) }
				else
					{ Callback(...) }
			Length = #Arguments
			if Arguments[1] ~= true then
				return table.unpack(Arguments, 2, Length)
			end
		end
		if Length == 1 then
			return nil
		end
		return table.unpack(Arguments, 2, Length)
	end
end
--[=[
	Used for only processing a single argument via middleware for more performance

	@yields

	@param Callbacks MiddlewareCallbacks
	@param Argument any?
]=]--
function Helpers.ProcessSingleMiddleware(Callbacks: MiddlewareCallbacks, Argument: any?): any?
	for _, Callback: MiddlewareCallback in Callbacks do
		local Success: boolean, Next: any = Callback(Argument)
		if not Success then
			return Next
		end
		Argument = Next
	end
	return Argument
end
--[=[
	Strips the given `Methods` into an ordered array of `MiddlewareCallback`s

	@param Methods (MiddlewareCallback | MiddlewareCallbacks)?
	@return MiddlewareCallbacks
]=]--
function Helpers.StripMiddleware(Methods: (MiddlewareCallback | MiddlewareCallbacks)?): MiddlewareCallbacks
	local Type: string = typeof(Methods)
	assert(
		(Type == "nil") or (Type == "table") or (Type == "function"),
		string.format(Exceptions.EXCEPTION_MUST_BE_TYPE, "Methods", "null, table, or function", Type)
	)

	if Type == "function" then
		return table.freeze{ Methods :: MiddlewareCallback }
	end

	local Stripped: MiddlewareCallbacks = {}
	if Type == "table" then
		for Index: number = 1, #(Methods :: MiddlewareCallbacks), 1 do
			local Callback: MiddlewareCallback = (Methods :: MiddlewareCallbacks)[Index]
			local Kind: string = typeof(Callback)

			assert(Kind == "function", string.format(Exceptions.EXCEPTION_MUST_BE_TYPE, "Middleware Method", "function", Kind))
			Stripped[Index] = Callback
		end
	end

	table.freeze(Stripped)
	return Stripped
end
-- Main
table.freeze(Helpers)
return Helpers