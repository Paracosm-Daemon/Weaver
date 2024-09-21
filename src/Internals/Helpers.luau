--!strict
-- Modules
local Internals = script.Parent
local Exceptions = require(Internals.Exceptions)
-- Module
local Helpers =
{
	EMPTY_MIDDLEWARE = table.freeze{};
	NONE = newproxy(false);
}
-- Functions
function Helpers.CreateMarker(Name: string): Marker
	local Marker: Marker = newproxy(true)
	getmetatable(Marker).__tostring = function(_self: { [any]: any }): string
		return Name
	end
	return Marker
end

function Helpers.StripMiddleware(Methods: MiddlewareCallbacks?): (MiddlewareCallbacks, number)
	local Type: string = typeof(Methods)
	assert((Type == "nil") or (Type == "table"), string.format(Exceptions.EXCEPTION_MUST_BE_TYPE, "Methods", "null or table", Type))

	local Stripped: MiddlewareCallbacks = {}
	local Length: number = 0

	if Methods then
		Length = #Methods
		for Index: number = 1, Length, 1 do
			local Callback: MiddlewareCallback = Methods[Index]
			local Kind: string = typeof(Callback)

			assert(Kind == "function", string.format(Exceptions.EXCEPTION_MUST_BE_TYPE, "Middleware Method", "function", Kind))
			Stripped[Index] = Callback
		end
	end

	table.freeze(Stripped)
	return Stripped, Length
end
function Helpers.CombineMiddleware(Base: MiddlewareCallbacks, Base_Length: number, Copy: MiddlewareCallbacks?): MiddlewareCallbacks
	local Combined_Middleware: MiddlewareCallbacks = {}
	local Mock_Middleware: MiddlewareCallbacks, Mock_Length: number = Helpers.StripMiddleware(Copy)
	-- Copy over the original middleware functions
	table.move(
		Base,
		1,
		Base_Length,
		1,
		Combined_Middleware
	)
	-- Then, add server-specific middleware
	table.move(
		Mock_Middleware,
		1,
		Mock_Length,
		1 + Base_Length,
		Combined_Middleware
	)
	table.freeze(Combined_Middleware)
	return Combined_Middleware
end
-- Types
export type MiddlewareCallback = (...any) -> boolean
export type MiddlewareCallbacks = { MiddlewareCallback }

export type Middleware = { Inbound: MiddlewareCallbacks?, Outbound: MiddlewareCallbacks? }

export type Marker = typeof(newproxy(false))
export type None = typeof(Helpers.NONE)
-- Main
table.freeze(Helpers)
return Helpers