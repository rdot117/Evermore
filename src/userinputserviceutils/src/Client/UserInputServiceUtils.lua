local require = require(script.Parent.loader).load(script)

local UserInputService = game:GetService("UserInputService")

local Observable = require("Observe")
local Maid = require("Maid")

--[=[
	@class UserInputServiceUtils
]=]
local UserInputServiceUtils = {}

--[=[
	Returns an observable with the last input type

	@return Observable<UserInputType>
]=]
function UserInputServiceUtils.observeLastInputType()
	return Observable.new(function(sub)
		local maid = Maid.new()

		maid:GiveTask(UserInputService.LastInputTypeChanged:Connect(function(lastInputType)
			sub:Fire(lastInputType)
		end))
		sub:Fire(UserInputService:GetLastInputType())

		return maid
	end)
end

--[=[
	Checks if the provided input is from a keyboard

	@param input UserInputType
	@return bool
]=]
function UserInputServiceUtils.isKeyboardInput(input)
	return input.UserInputType == Enum.UserInputType.Keyboard
end

--[=[
	Checks if the provided input is touch

	@param input UserInputType
	@return bool
]=]
function UserInputServiceUtils.isTouchInput(input)
	return input.UserInputType == Enum.UserInputType.Touch
end

return UserInputServiceUtils