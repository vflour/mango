local Stages = {}
local Dependencies = require(script.Parent.Settings).Dependencies
--- @module Assert
local assertions = Dependencies.Assert
--- @module Table
local Table = Dependencies.Table
--- @module Expressions
local expressions = require(script.Parent.Expressions)
--- @module Query
local Query = require(script.Parent.Query)
--- @module Accumulators
local Accumulators = require(script.Parent.Accumulators)

-- MATCH STAGE:
-- (https://docs.mongodb.com/manual/tutorial/query-documents/#std-label-read-operations-query-argument)
--- Evaluates on whether the query matches the input entries, and returns a filtered result
Stages["$match"] = function(input,query)
    return Query(input,query)
end

-- GROUP STAGE:
-- (https://docs.mongodb.com/manual/reference/operator/aggregation/group/#mongodb-pipeline-pipe.-group)
--- Groups the input entries specified in the id field by following expression 
type groupQuery = {
    id : any,
    [string] : any,
}
Stages["$group"] = function(input,query:groupQuery)
    assert(query.id,"No id field to group by with")
    -- create a groups subtable
    local groups = Stages:GroupInputEntries(input,query)
    -- convert it to an output table
    local output = {}
    for groupId,groupData in pairs(groups) do
        local entry = {}
        entry.id = groupData.id
        for accumulator,accumulatorList in pairs(groupData) do -- group data key/value pairs are stored as seperate entries
            if accumulator == "id" then continue end
            entry[string.gsub(accumulator,"^%$","")] = Accumulators.Accumulators[accumulator](accumulatorList)
        end 
        table.insert(output,entry)
    end
    return output
end

--- Creates a group of entries containing the group's id and the collection of all values used for the accumulators
---@param input any
---@param query any
---@return any
function Stages:GroupInputEntries(input,query)
    local groups = {}
    local groupOrder = {}
    for i, entry in ipairs(input) do
        local groupId = expressions:Evaluate(entry,query.id) 
        local index = EquivalentIndex(groups,groupId)
        local groupData = groups[index]==nil and {} or groups[index]

        if groups[index]==nil then
            groupData.id = index
            table.insert(groupOrder,groupData)
        end
        for accumulator,expression in pairs(query) do
            if accumulator ~= "id" then
                assertions.assert(Accumulators:IsAccumulator(accumulator),tostring(accumulator).." is not a valid accumulator")
                
                local accumulatorList = groupData[accumulator] == nil and {} or groupData[accumulator]
                table.insert(accumulatorList,expressions:Evaluate(entry,expression))
                groupData[accumulator] = accumulatorList
            end
        end
        groups[index] = groupData
    end
    return groupOrder
end

---Returns true if there is an equivalent index in the group table
---@param groupTable any
---@param index any
---@return any
function EquivalentIndex(groupTable,index)
    if typeof(index) ~= "table" then return index end -- shouldnt be a table
    for groupIndex, groupData in pairs(groupTable) do
        -- group data has to be a table so that it may be compared to indexTable
        if typeof(groupData)~="table" then continue end
        if expressions:EquivalentTable(groupIndex,index) then -- return the original index if the tables are equivalent
            return groupIndex
        end
    end
    -- the index table is a new index
    return index
end    
   

type lookupQuery = {
    from: string,
    localField: string,
    foreignField: string,
    as: string,
}
-- LOOKUP STAGE:
-- (https://docs.mongodb.com/manual/reference/operator/aggregation/lookup/#mongodb-pipeline-pipe.-lookup)
--- Performs a left outer join on another collection and stores it in an array
Stages["$lookup"] = function(input,query:lookupQuery)
    -- type validation
    assertions.assertType(query.from,"string")
    assertions.assertType(query.localField,"string")
    assertions.assertType(query.foreignField,"string")
    assertions.assertType(query.as,"string")

    -- first get the collection
    local Collection = require(script.Parent.Collection)
    local collection = Collection.Get(query.from)._data
    -- look through input
    local output = {} 
    for i,entry in ipairs(input) do
        local field = expressions:Evaluate(entry,query.localField)
        local newEntry = Table.deepCopy(entry)
        local joinOutput = {}
        -- TODO: use indexes because this method is depressingly slow
        for i,foreignEntry in ipairs(collection) do
            local foreignField = expressions:Evaluate(foreignEntry,query.foreignField)
            if expressions:AreEquivalent(field,foreignField) then
                table.insert(joinOutput,foreignEntry)
            end
        end
        newEntry[query.as]=joinOutput
        table.insert(output,newEntry)
    end
    return output
end

type projectQuery = {
    id: number|boolean|{any},
    [string]: any,
}
-- PROJECT STAGE:
-- (https://docs.mongodb.com/manual/reference/operator/aggregation/project/)
--- Excludes or includes fields in an entry
Stages["$project"] = function(input,query:projectQuery)
    local output = {}
    local isExcluding = IsExcluding(query)
    for i,entry in ipairs(input) do
        local data = isExcluding == true and Table.deepCopy(entry) or {} -- if youre only excluding then just display the table + exclusions
        for field,expression in pairs(query) do
            if expression == 1 or expression==true then -- 1 or true means youre showing
                data[field] = entry[field]    
            elseif expression == 0 or expression == false then -- 0 or false means youre hiding
                data[field] = nil
            else
                data[field] = expressions:Evaluate(entry,expression) -- set an expression
            end
        end
        table.insert(output,data)
    end
    return output
end

---Returns true if the query is meant to exclude fields only
---@param query any
---@return boolean
function IsExcluding(query)
    for field,value in pairs(query) do
        if value == 1 or value==true then
            return false
        end
    end
    return true
end

type unwindQuery = {
    path: string,
    includeArrayIndex: string?,
    preserveNullAndEmptyArrays: boolean?
}

-- UNWIND STAGE:
-- (https://docs.mongodb.com/manual/reference/operator/aggregation/unwind/index.html)
--- Separates a field (that is an array) into multiple documents
Stages["$unwind"] = function(input,query:projectQuery)
    -- type validation for query
    assertions.assertType(query.path,"string")
    assertions.assertType(query.includeArrayIndex,"string","nil")
    assertions.assertType(query.preserveNullAndEmptyArrays,"boolean","nil")
    if query.includeArrayIndex then
        expressions:CantHaveDollarSign(query.includeArrayIndex)
    end
    -- loop through entries and insert copies
    local output = {}
    for _,entry in ipairs(input) do
        local arrayField = expressions:GetFieldPathValue(entry,query.path)
        arrayField = arrayField==nil and {} or arrayField -- if null then its an empty array
        -- insert a copy if preserveNullAndEmptyArrays is true or the path does not point to an array
        if WillInsertCopyAnyway(arrayField,query.preserveNullAndEmptyArrays) then
            local data = Table.deepCopy(entry)
            table.insert(output,data)
            continue
        end
        --if its an array then loop through entries
        for _, value in pairs(arrayField) do
            local data = Table.deepCopy(entry)
            -- set the COPY's holder of the path 
            if query.includeArrayIndex then
                data[query.includeArrayIndex]=value            
            else
                local arrayCopy,index,holder = expressions:GetFieldPathValue(data,query.path)
                holder[index] = value
            end
            table.insert(output,data)
        end
    end
    return output
end

--- Returns true if the unwind expression should insert a hard copy into the output array
---@param arrayField any
---@param preserveNullAndEmptyArrays boolean?
---@return boolean
function WillInsertCopyAnyway(arrayField,preserveNullAndEmptyArrays)
    if typeof(arrayField)~="table" then return true end
    if #arrayField == 0 and next(arrayField) then return true end -- embedded documents are NOT arrays
    return preserveNullAndEmptyArrays==true and #arrayField==0
end

return Stages