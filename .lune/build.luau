-- Modules
local Process = require("@lune/process")
local Filesystem = require("@lune/fs")
local Roblox = require("@lune/roblox")
local Net = require("@lune/net")
-- Constants
local APPLICATION_JSON: string = "application/json"
local USER_AGENT: string = "Roblox/WinInet"

local PUBLISH_TO: string = "18772004646"
-- Variables
local File = Filesystem.readFile("Weaver.rbxl")
local game = Roblox.deserializePlace(File)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Asset: string = Roblox.serializeModel({ ReplicatedStorage.Weaver }, false)
local Cookie: string = assert(Process.env.LUNE_AUTH, "Need LUNE_AUTH env to publish Weaver")

local CSRF_Headers: { [string]: any } =
{
	["Content-Type"] = APPLICATION_JSON;
	["User-Agent"] = USER_AGENT;

	Accept = APPLICATION_JSON;
	Cookie = Cookie;
}
-- Main
local CSRF_Response: Net.FetchResponse = Net.request{
	url = "https://auth.roblox.com/";
	method = "POST";

	headers = CSRF_Headers;
	body = Asset;
}

local CSRF_Token: string | { string } = assert(CSRF_Response.headers["x-csrf-token"], "Couldn't fetch CSRF token")
local Upload_Headers: { [string]: any } =
{
	["Content-Type"] = "application/octet-stream";
	["X-CSRF-Token"] = CSRF_Token;
	["User-Agent"] = USER_AGENT;

	Accept = APPLICATION_JSON;
	Cookie = Cookie;
}
local Upload_Response: Net.FetchResponse = Net.request{
	url = `https://data.roblox.com/Data/Upload.ashx?assetid={ PUBLISH_TO }`;
	method = "POST";

	headers = Upload_Headers;
	body = Asset;
}
assert(
	Upload_Response.ok,
	`Asset failed to upload: Status code { Upload_Response.statusCode } ({ Upload_Response.statusMessage })\n{ Upload_Response.body }`
)