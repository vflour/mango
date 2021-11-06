local Stages = {}
--- @module Expressions
local expressions = require(script.Parent.Expressions)
--- @module Query
local Query = require(script.Parent.Query)
--- @module Assert
local assertions = require(script.Parent.Settings).Dependencies.Assert

-- WHERE STAGE:
-- (https://docs.mongodb.com/manual/tutorial/query-documents/#std-label-read-operations-query-argument)
--- Evaluates on whether the query matches the input entries, and returns a filtered result
Stages["$where"] = function(input,query)
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
    local groups = GroupInputEntries(input,query)
    -- convert it to an output table
    local output = {}
    for groupId,groupData in pairs(groups) do
        local entry = {}
        entry.id = groupId
        for field,value in pairs(groupData) do -- group data key/value pairs are stored as seperate entries
            entry[field] = value
        end 
        table.insert(output,entry)
    end
    return output
end
--- Creates a group of entries.
function GroupInputEntries(input,query)
    local groups = {}
    for i, entry in ipairs(input) do
        local groupId = expressions:Evaluate(entry,query.id) 
        groups[EquivalentIndex(groups,groupId)] = {}
    end
    return groups
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
    local collection = Collection.Get(query.from)
    -- look through input
    local output = {} 
    for i,entry in ipairs(input) do
        local field = expressions:Evaluate(entry,query.localField)
        
        -- TODO: use indexes because this method is depressingly slow
        for i,foreignEntry in ipairs(collection) do
            local foreignField = expressions:Evaluate(foreignEntry,query.foreignField)

        end
    end

end

return Stages