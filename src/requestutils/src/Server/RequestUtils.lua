--[=[
	@class RequestUtils
]=]

local require = require(script.Parent.loader).load(script)

local Promise = require("Promise")

local REQUEST_ATTEMPTS_LIMIT = 10
local REQUEST_TIME_BUFFER = 0.1

local RequestUtils = {
	REQUEST_ATTEMPTS_LIMIT = REQUEST_ATTEMPTS_LIMIT,
	REQUEST_TIME_BUFFER = REQUEST_TIME_BUFFER,
}

--[=[
	Safety make requests until a non-nil value is returned
	This can be useful for safely making HttpService calls, DataStoreService, etc
	
	@param request function
	@param limit number
	@param buffer number
	@return Promise<result>
]=]
function RequestUtils.promiseRequestWithRetries(request, limit, buffer)
	return Promise.new(function(resolve, reject)
		local attempts = 0
		local result = nil

		limit = limit or REQUEST_ATTEMPTS_LIMIT
		buffer = buffer or REQUEST_TIME_BUFFER

		repeat
			attempts += 1
			result = request()

			if result == nil then
				task.wait(buffer)
			end
		until attempts >= limit or result ~= nil

		if result ~= nil then
			resolve(result)
		else
			reject()
		end
	end)
end

return RequestUtils