local Database = {}
Database.Active = false

local Depends = require(game.ReplicatedStorage.Scripts:WaitForChild("Depends"))("Assert")
--- @module Assert
local assertions = Depends.Assert
--- @module Query
local Query = require(script.Query)

local DATA_PATH = game.ReplicatedStorage.Data

----------------------------- DATABASE CACHE RETRIEVAL
local Cache = {}
Cache.Capacity = 5
Cache._collections = {}
Cache._order = {}

-- Retrieve related collections that will likely be used alongside the initial collection
-- (mainly related foreign keys)
local RELATED_COLLECTIONS = {
	Shop = {"Item"},
	Equippable = {"Item"},
	Usable = {"Action","Item","ActionLogic"},
	Spell = {"Action","ActionLogic"},
	Action = {"ActionLogic"},
	NPCBattle = {"NPC","Reward"},
	Room = {"Milestone","Reward"},
	Milestone = {"Act"}
}
---retrives a collection from the cache
---@param collectionName any
---@return any
function Cache:Get(collectionName)
	local collection = self._collections[collectionName]
	-- "freshen" the collection so it doesnt get kicked
	if collection then
		local index = table.find(self._order,collectionName)
		table.remove(self._order,index) -- remove and re-insert collection in order
		table.insert(self._order,1,collectionName)	
	else
		self:Store(collectionName)
	end
	self:_evictCollections()
	return collection
end

--- stores a collection into the cache and caches related collections
---@param collectionName string
function Cache:Store(collectionName)
	self:_insertCollection(collectionName,self:_requireModule(collectionName))
	-- store related collections
	local related = RELATED_COLLECTIONS[collectionName]
	if related then
		for _,relatedName in ipairs(related) do
			self:_insertCollection(relatedName,self:_requireModule(relatedName))
		end
	end
end
--- inserts a collection into _collections and _order
function Cache:_insertCollection(collectionName,collection)
	self._collections[collectionName] = collection
	table.insert(self._order,1,collectionName) -- insert it as the most recent collection
end
--- requires a module from the data folder
function Cache:_requireModule(collectionName)
	local moduleScript = DATA_PATH:FindFirstChild(collectionName)
	assertions.assert(moduleScript,"Coulld not retrieve collection "..collectionName)
	local collectionModule = require(moduleScript)
	return collectionModule.Data
end
--- clears the least used collections from the cache
function Cache:_evictCollections()
	if #self._collections > self.Capacity then -- check only if reached max capacity
		for i = self.Capacity+1, #self._collections do 
			local collectionName = self._order[i]
			table.remove(self._order,i) -- remove from order
			self._collections[collectionName] = nil -- remove from collections table
		end
	end
	print(self._collections,self._order) -- debug
end

----------------------------- DATABASE SCHEMA VALIDATION
---Check collection for any entries
---@param collection any collection data
---@param i any compared entry index
---@param key any
---@param value any 
function CheckUnique(collection,i,key,value)
	for index,entry in pairs(collection) do
		-- assert for identical entry, except for the entry itself
		assertions.assert(entry[key]~=value or i~=index,string.format("Key %s is unique, value %s already exists",tostring(key),tostring(value)))
	end
end

---Validate the object in an entry (no recursion for now because of schema constraint layout)
---@param collection any
---@param i any index to the key
---@param object any The object being evaluated
---@param schemaObject any The schema object
function ValidateObjectInCollection(collection,i,object,schemaObject)
	for key,value in pairs(object) do
		local schema = schemaObject[key]
		local evaluate,extra = schema,nil -- extra exists incase you want to evaluate required
		if typeof(schema)=="table" then -- if the schema has constraints like unique or required, its a table
			if schema.unique then
				CheckUnique(collection,i,key,value)
			end
			evaluate = schema.type
			extra = schema.required == true and "nil" or nil
		end
		-- add additional context to error
		xpcall(assertions.assertType,function(msg)
			error("Could not validate schema: "..msg)
		end,evaluate,extra)
	end
end

---Validate the collection module
---@param collection any
function ValidateCollection(collection)
	assertions.assert(collection.Data,"No Data field present in collection.")
	assertions.assert(collection.Schema,"No schema present in collection")
	assertions.assert(collection.Schema["%INDEX%"], "No primary key type indicator present for schema")
	for i,entry in pairs(collection) do
		assertions.assertType(entry,collection.Schema["%INDEX%"])
		ValidateObjectInCollection(collection,i,entry,collection.Schema)
	end
end

--- Validate all of the collection modules in the Data folder
function ValidateAllCollections()
	local modules = DATA_PATH:GetChildren()
	for i,module : ModuleScript in ipairs(modules) do
		if module:IsA("ModuleScript") then
			local collection = require(module)
			-- if collection schema validation failed, handle it
			xpcall(ValidateCollection,function(msg)
				error("Could not check collection name "..module.Name..": "..msg)
			end,collection)
		end
	end
end 
----------------------------- DATABASE OBJECT
--- Retrieves the collection (from cache or require)
---@param collectionName string
---@return Collection
function Database:GetCollection(collectionName)
	assertions.assert(self.Active,"Database is not initialized")
	assertions.assertType(collectionName,"string")
	---@type Collection
	local collection = {} 
	collection._data = {}
	setmetatable(collection,Collection)
	return collection
end

-- Init the script
function Main()
	script.Parent.OnInvoke = function()
		return Database
	end
	ValidateAllCollections()
	Database.Active = true
end
Main()


