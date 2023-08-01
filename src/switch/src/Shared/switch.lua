--[=[
	@class switch

	Custom switch implementation for Roblox

	Example usage:

	```lua
	switch(2)({
		case(1, function(value)
			print("I recieved case 1!")
			return true
		end),

		case(2, function(value) --> selected case
			print("I recieved case 2!")
			return true
		end),

		case(function(value)
			print("The value was nil :(")
			return true
		end),
	}):Subscribe(function(returnedValue)
		print(returnedValue) --> true
	end)
	```
]=]

local require = require(script.Parent.loader).load(script)

local Observable = require("Observable")
local Maid = require("Maid")

local function isNilCase(case)
	assert(typeof(case) == "table", "Bad case")
	return #case.Value == 0
end

local function verifyCases(cases)
	assert(typeof(cases) == "table", "Bad cases")

	local nilCase = false
	local values = {}
	for _, case in cases do
		assert(typeof(case.Compute) == "function", "Bad compute")

		for _, value in case.Value do
			assert(values[value] == nil, "[switch]: There are duplicate values in the cases!")
			values[value] = true
		end

		if isNilCase(case) then
			if nilCase == true then
				error("[switch]: There are duplicate nil cases!")
			else
				nilCase = true
			end
		end
	end
end

--[=[
	@function switch
	@within switch

	@param value any
	@param shouldYield bool
	@param ... any
	@return Observable
]=]

local function switch(value, shouldYield, ...)
	local args = table.pack(...)

	return function (cases)
		return Observable.new(function(sub)
			local maid = Maid.new()

			-- verify cases (will otherwise error)
			verifyCases(cases)

			-- run through cases
			for _, case in cases do
				if table.find(case.Value, value) then
					if (shouldYield or false) then
						sub:Fire(case.Compute(table.unpack(args)))
						sub:Complete()
					else
						task.spawn(function()
							sub:Fire(case.Compute(table.unpack(args)))
							sub:Complete()
						end)
					end

					break
				end
			end

			return maid
		end)
	end
end

return switch