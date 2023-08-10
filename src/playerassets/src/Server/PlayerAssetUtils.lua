--[=[
	Util functions for retrieving gamepasses, catalog items, and checking for ownership.

	@class PlayerAssetUtils
]=]

local require = require(script.Parent.loader).load(script)

local HttpService = game:GetService("HttpService")

local PlayerAssetConstants = require("PlayerAssetConstants")
local RequestUtils = require("RequestUtils")

local PLACES_URL = "https://games.roproxy.com/v2/users/%s/games?accessFilter=2&limit=50&cursor=%s&sortOrder=Asc&"
local GAMEPASS_URL = "https://games.roproxy.com/v1/games/%s/game-passes?limit=100&sortOrder=Asc"
local CATALOG_URL = "https://catalog.roproxy.com/v2/search/items/details?Category=3&Subcategory=%s&Sort=4&Limit=30&CreatorName=%s&cursor=%s"
local IS_OWNED_URL = "https://inventory.roproxy.com/v1/users/%s/items/%s/%s/is-owned"
local CATEGORY_ORDER = {PlayerAssetConstants.SHIRT, PlayerAssetConstants.PANT, PlayerAssetConstants.T_SHIRT}

local CATEGORIES = {
	[PlayerAssetConstants.SHIRT] = {
		Id = 2,
	},

	[PlayerAssetConstants.PANT] = {
		Id = 11,
	},

	[PlayerAssetConstants.T_SHIRT] = {
		Id = 12
	},
}

local PlayerAssetUtils = {}

--[=[
	Gets all player's catalog items. Returns nil on failure.

	@param player Player
	@return catalogItems table 
]=]
function PlayerAssetUtils.getPlayerCatalogItems(player)
	local catalogItems = {}
	local cursor = ""

	for _, category in CATEGORY_ORDER do
		local categoryData = CATEGORIES[category]
		local categoryId = categoryData.Id

		local requestUrl = string.format(CATALOG_URL, categoryId, player.Name, cursor)
		
		local catalogSuccess, jsonCatalogResults = pcall(function()
			return HttpService:GetAsync(requestUrl, true)
		end)

		if not catalogSuccess then
			warn(jsonCatalogResults)
			return nil
		end

		local decodeSuccess, catalogResults = pcall(function()
			return HttpService:JSONDecode(jsonCatalogResults)
		end)

		if not decodeSuccess then
			warn(catalogResults)
			return nil
		end

		for _, item in catalogResults.data do
			local alreadyFound = false
			for _, existingItem in catalogItems do
				if existingItem.id == item.id then
					alreadyFound = true
					break
				end
			end

			if alreadyFound then
				continue
			end

			table.insert(catalogItems, item)
		end
	end

	return catalogItems
end

--[[
	Gets all player's places. Returns nil on failure.

	@param player Player
	@param cursor string
	@param previousResults table
	@return places table
]]
function PlayerAssetUtils.getPlayerPlaces(player, cursor, previousResults)
	local requestUrl = string.format(PLACES_URL, player.UserId, cursor)

	local httpSuccess, jsonResults = pcall(function()
		return HttpService:GetAsync(requestUrl, true)
	end)

	if not httpSuccess then
		warn(jsonResults)
		return nil
	end

	local success, results = pcall(function()
		return HttpService:JSONDecode(jsonResults)
	end)

	if not success then
		warn(results)
		return nil
	end

	-- go through page cursors
	local returnResults = if previousResults then previousResults else {}
	for _, data in results.data do
		table.insert(returnResults, data)
	end

	if results.nextPageCursor then

		-- if we dont have this return, even if one of the requests fail
		-- it will still return the `returnResults` table, but we want the overall request
		-- to then fail with that `return nil`
		return PlayerAssetUtils.getPlayerPlaces(player, results.nextPageCursor, returnResults)
	end

	return returnResults
end

--[=[
	Gets all gamepasses attributed to a place. Returns nil on failure.

	@param place table
	@return gamepasses table
]=]
function PlayerAssetUtils.getPlaceGamepasses(place)
	local requestUrl = string.format(GAMEPASS_URL, place.id)

	local httpSuccess, jsonResults = pcall(function()
		return HttpService:GetAsync(requestUrl, true)
	end)

	if not httpSuccess then
		warn(jsonResults)
		return nil
	end

	local success, results = pcall(function()
		return HttpService:JSONDecode(jsonResults)
	end)

	if not success then
		warn(results)
		return nil
	end

	local gamepasses = {}
	for _, gamepass in results.data do
		if not gamepass.price then
			continue
		end

		local alreadyFound = false
		for _, existingGamepass in gamepasses do
			if existingGamepass.id == gamepass.id then
				alreadyFound = true
				break
			end
		end

		if alreadyFound then
			continue
		end
		
		table.insert(gamepasses, gamepass)
	end

	return gamepasses
end

--[=[
	Gets all player's gamepasses. Returns nil on failure.

	@param player Player
	@return gamepasses table
]=]
function PlayerAssetUtils.getPlayerGamepasses(player)
	local gamepasses = {}

	local places = PlayerAssetUtils.getPlayerPlaces(player, "")
	if not places then
		return nil
	end

	for _, place in places do
		local placeGamepasses = PlayerAssetUtils.getPlaceGamepasses(place)
		if not placeGamepasses then
			return nil
		end

		for _, gamepass in placeGamepasses do
			table.insert(gamepasses, gamepass)
		end
	end

	return gamepasses
end

--[=[
	Checks if an asset is owned by the player (either gamepass or asset)

	@param player Player
	@param assetId number
	@param assetType InfoType
]=]
function PlayerAssetUtils.isAssetOwned(player, assetId, assetType)
	assert(assetType == Enum.InfoType.Asset or assetType == Enum.InfoType.GamePass, "Bad assetType")
	
	local stringAssetType = ""
	if assetType == Enum.InfoType.Asset then
		stringAssetType = "0"
	elseif assetType == Enum.InfoType.GamePass then
		stringAssetType = "1"
	end

	local requestUrl = string.format(IS_OWNED_URL, player.UserId, stringAssetType, assetId)

	local httpSuccess, jsonResults = pcall(function()
		return HttpService:GetAsync(requestUrl, true)
	end)

	if not httpSuccess then
		warn(jsonResults)
		return nil
	end

	local success, results = pcall(function()
		return HttpService:JSONDecode(jsonResults)
	end)

	if not success then
		warn(results)
		return nil
	end
	
	return results
end

--[=[
	Promises the player's catalog items, with retries

	@param player Player
	@return Promise<catalogItems>
]=]
function PlayerAssetUtils.promisePlayerCatalogItems(player)
	return RequestUtils.promiseRequestWithRetries(function()
		return PlayerAssetUtils.getPlayerCatalogItems(player)
	end)
end

--[=[
	Promises the player's gamepasses, with retries

	@param player Player
	@return Promise<gamepasses>
]=]
function PlayerAssetUtils.promisePlayerGamepasses(player)
	return RequestUtils.promiseRequestWithRetries(function()
		return PlayerAssetUtils.getPlayerGamepasses(player)
	end)
end

--[=[
	Promises if the player owns an asset, with retries

	@param player Player
	@param assetId number
	@param assetType InfoType
	@return Promise<isAssetOwned>
]=]
function PlayerAssetUtils.promiseIsAssetOwned(player, assetId, assetType)
	return RequestUtils.promiseRequestWithRetries(function()
		return PlayerAssetUtils.isAssetOwned(player, assetId, assetType)
	end)
end

return PlayerAssetUtils