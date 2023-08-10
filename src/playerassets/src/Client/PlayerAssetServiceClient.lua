--[=[
	@class PlayerAssetServiceClient
]=]

local require = require(script.Parent.loader).load(script)

local Players = game:GetService("Players")

local Maid = require("Maid")
local Observable = require("Observable")
local GoodSignal = require("GoodSignal")
local GetRemoteEvent = require("GetRemoteEvent")

local UpdatePlayerAssets = GetRemoteEvent("UpdatePlayerAssets")

local PlayerAssetServiceClient = {}
PlayerAssetServiceClient.ServiceName = "PlayerAssetServiceClient"

--[=[
	Starts the clientside, in charge of recieving/managing loaded player assets from PlayerAssetService.

	@param serviceBag ServiceBag
]=]
function PlayerAssetServiceClient:Init(serviceBag)
	self._serviceBag = assert(serviceBag, "No serviceBag")

	self._maid = Maid.new()
	self._cachedAssets = {}

	self.PlayerAssetsUpdated = GoodSignal.new()
	self._maid:GiveTask(self.PlayerAssetsUpdated)

	self._maid:GiveTask(UpdatePlayerAssets.OnClientEvent:Connect(function(replicationData)
		local updatedPlayers = {}

		for userIdString, userAssets in replicationData do
			local userId = tonumber(userIdString)
			local replicatedPlayer = Players:GetPlayerByUserId(userId)
			if not replicatedPlayer then
				warn("Couldn't find player to replicate data to: ", replicatedPlayer.Name)
				continue
			end

			updatedPlayers[replicatedPlayer] = true
			self._cachedAssets[userId] = userAssets
		end

		self.PlayerAssetsUpdated:Fire(updatedPlayers)
	end))
end

function PlayerAssetServiceClient:ObservePlayerAssets(target)
	return Observable.new(function(sub)
		local maid = Maid.new()

		maid:GiveTask(self.PlayerAssetsUpdated:Connect(function(updatedPlayers)
			if updatedPlayers[target] then
				sub:Fire(self._cachedAssets[target.UserId])
			end
		end))
		sub:Fire(self._cachedAssets[target.UserId])

		return maid
	end)
end

function PlayerAssetServiceClient:_onPlayerRemoving(player)
	self._cachedAssets[player.UserId] = nil
end

return PlayerAssetServiceClient