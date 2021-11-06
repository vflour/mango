local Stages = {}
local Dependencies = require(script.Parent.Settings).Dependencies
--- @module Expressions
local expressions = require(script.Parent.Expressions)
--- @module Query
local Query = require(script.Parent.Query)
--- @module Accumulators
local Accumulators = require(script.Parent.Accumulators)
--- @module Assert
local assertions = Dependencies.Assert
--- @module Table
local Table = Dependencies.Table

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
--- Creates a group of entries.
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

function EquivalentIndex(groupTable,indexTable)
    if typeof(indexTable) ~= "table" then return indexTable end -- shouldnt be a table
    for groupIndex, groupData in pairs(groupTable) do
        -- group data has to be a table so that it may be compared to indexTable
        if typeof(groupData)~="table" then continue end
        if expressions:EquivalentTable(groupIndex,indexTable) then -- return the original index if the tables are equivalent
            return groupIndex
        end
    end
    -- the index table is a new table
    return indexTable
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

return Stages