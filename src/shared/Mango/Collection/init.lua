--- @module Assert
local assertions = require(script.Parent.Settings).Dependencies.Assert
--- @module Query
local Query = require(script.Parent.Query)
--- @module Settings
local Settings = require(script.Parent.Settings)
--- @module Stages
local Stages = require(script.Parent.Stages)

---@class Collection
local Collection = {}
Collection.__index = Collection

function Collection.Get(collectionName)
	assertions.assertType(collectionName,"string")
    -- try get collection ms
    local collectionFile = Settings.CollectionFolder:FindFirstChild(collectionName)
    assertions.assert(collectionFile,"Could not get collection "..collectionName)
    assertions.assertIsA(collectionFile,"ModuleScript")
	---@type Collection
	local collection = {} 
	collection._data = require(collectionFile).Data
	setmetatable(collection,Collection)
	return collection
end

--- Finds all results in the collection using the filter
---@param filter any
function Collection:Find(filter)
	assertions.assertType(filter,"table")
	return Query(self._data,filter)
end

---Similar to Find, but will throw an error if there is not exactly one entry found
---@param filter any
---@return any
function Collection:FindOne(filter)
	local findResult = self:Find(filter)
	-- throw error if findResult is not one
	assertions.assert(#findResult<2,"Too many entries found")
	assertions.assert(#findResult>0,"No entries found")
	return findResult[1]
end

function Collection:Aggregate(pipeline)
	local input = self._data
	for i,stage in ipairs(pipeline) do
		-- check stage name
		local stageName = next(stage)
		assertions.assert(Stages[stageName],tostring(stageName).." is not a valid pipeline stage")
		-- perform stage
		input = Stages[stageName](input,stage[stageName])
	end
	return input
end	

return Collection