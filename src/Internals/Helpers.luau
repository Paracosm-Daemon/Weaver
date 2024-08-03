--!strict
-- Module
local Helpers = {}
-- Functions
function Helpers.CreateMarker(Name: string): Marker
	local Marker: Marker = newproxy(true)
	getmetatable(Marker).__tostring = function(): string
		return Name
	end
	return Marker
end
-- Main
export type Marker = typeof(newproxy(false))
return Helpers