--[=[
	@class case
]=]

--[=[
	@function case
	@within case

	@param ... any
	@param compute function
]=]
local function case(...)
	local args = {...}
	local n = #args

	local compute = args[n]
	assert(typeof(compute) == "function", "Bad compute")

	local values = {}

	if #args > 1 then
		for i = 1, n-1 do
			local value = args[i]
			values[i] = value
		end
	end

	return {
		Value = values,
		Compute = compute,
	}
end

return case