--!strict
-- Module
local Helpers =
{
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
-- Types
export type Marker = typeof(newproxy(false))
export type None = typeof(Helpers.NONE)
-- Main
return table.freeze(Helpers)