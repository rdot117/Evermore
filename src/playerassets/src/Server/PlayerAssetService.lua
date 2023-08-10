--[=[
	@class PlayerAssetService

	Responsible for retrieving player gamepasses/catalog items
	and efficiently replicating them to all players
]=]

local require = require(script.Parent.loader).load(script)

local Players = game:GetService("Players")

local Maid = require("Maid")
local GoodSignal = require("GoodSignal")
local PlayerAssetUtils = require("PlayerAssetUtils")
local GetRemoteEvent = require("GetRemoteEvent")

local UpdatePlayerAssets = GetRemoteEvent("UpdatePlayerAssets")

local PlayerAssetService = {}
PlayerAssetService.ServiceName = "PlayerAssetService"

--[=[
	Used to start the service. Intended to be used with ServiceBag
	
	@param serviceBag ServiceBag
]=]
function PlayerAssetService:Init(serviceBag)
	self._serviceBag = assert(serviceBag, "No serviceBag")
	self._donationService = self._serviceBag:GetService(require("DonationService"))

	self._maid = Maid.new()
	self._cachedPlayerAssets = {}

	self.PlayerAssetsUpdated = GoodSignal.new()
	self._maid:GiveTask(self.PlayerAssetsUpdated)

	self._maid:GiveTask(self.PlayerAssetsUpdated:Connect(function(player)
		UpdatePlayerAssets:FireAllClients({
			[player.UserId] = self._cachedPlayerAssets[player.UserId],
		})
	end))

	for _, player in Players:GetPlayers() do
		task.spawn(PlayerAssetService._onPlayerAdded, PlayerAssetService, player)
	end

	Players.PlayerAdded:Connect(function(player)
		self:_onPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_onPlayerRemoving(player)
	end)
end

function PlayerAssetService:_onPlayerAdded(player)
	local maid = Maid.new()
	self._maid[player] = maid

	UpdatePlayerAssets:FireClient(player, self._cachedPlayerAssets)

	self._cachedPlayerAssets[player.UserId] = {}
	self._cachedPlayerAssets[player.UserId].Gamepasses = {}
	self._cachedPlayerAssets[player.UserId].CatalogItems = {}

	maid:GiveTask(function()
		self._cachedPlayerAssets[player.UserId] = nil
	end)

	maid:GivePromise(PlayerAssetUtils.promisePlayerGamepasses(player):Then(function(gamepasses)
		if not self._cachedPlayerAssets[player.UserId] then
			return
		end
		
		self._cachedPlayerAssets[player.UserId].Gamepasses = gamepasses
		self.PlayerAssetsUpdated:Fire(player)
	end))

	maid:GivePromise(PlayerAssetUtils.promisePlayerCatalogItems(player):Then(function(catalogItems)
		if not self._cachedPlayerAssets[player.UserId] then
			return
		end

		self._cachedPlayerAssets[player.UserId].CatalogItems = catalogItems
		self.PlayerAssetsUpdated:Fire(player)
	end))
end

function PlayerAssetService:_onPlayerRemoving(player)
	self._maid[player] = nil
end

function PlayerAssetService:Destroy()
	self._maid:DoCleaning()
end

return PlayerAssetService