--!strict
-- Module
local Module = table.freeze{
	EXCEPTION_BEFORE_START = "%s cannot be added after Weaver has started";
	EXCEPTION_MUST_BE_TYPE = "%s must be of type %s, got %s";

	EXCEPTION_DOES_NOT_EXIST = "%s %s does not exist";
	EXCEPTION_EXISTS_AS = "%s %s already exists";

	EXCEPTION_CANT_START = "Failed to start Weaver due to an internal error";

	EXCEPTION_NEED_USE_START = "Weaver must be started to use %s";
	EXCEPTION_HAS_STARTED = "Weaver has already started";
}
-- Main
return Module