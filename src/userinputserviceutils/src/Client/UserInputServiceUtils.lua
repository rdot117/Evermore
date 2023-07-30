local require = require(script.Parent.loader).load(script)

local UserInputService = game:GetService("UserInputService")

local Observable = require("Observe")
local Maid = require("Maid")

local UserInputServiceUtils = {}

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

function UserInputServiceUtils.isKeyboardInput(input)
	return input.UserInputType == Enum.UserInputType.Keyboard
end

function UserInputServiceUtils.isTouchInput(input)
	return input.UserInputType == Enum.UserInputType.Touch
end

return UserInputServiceUtils