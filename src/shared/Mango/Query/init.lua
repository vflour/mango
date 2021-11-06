--- @module Operators
--local operators = require "Operators"
local operators = require(script.Operators)

---Returns a filtered version of the collection based on the search query
---@param collection any The collection table
---@param query any The query itself
---@return any
function Query(collection,query)
    local output = {}
    for index,entry in pairs(collection) do
        if EvaluateEntry(entry, query) then
            table.insert(output,entry)
        end
    end    
    return output
end

function EvaluateEntry(entry, query)
    local valid = true
    -- loop through the query's fields and values
    for field,value in pairs(query) do
        -- if the value in the query you are either using an operation or evaluating an embedded table 
        if type(value)=="table" then 
            -- check for top level operation
            if operators:HasOperatorSyntax(field) then
                valid = operators:TopLevelOperation(field,entry,value,EvaluateEntry)
            elseif operators:TableIsOperation(value) then
                valid = operators:Operation(field,entry,value)
            else -- if its an embedded document
                valid = EvaluateEntry(entry[field],value)  
            end    
        else -- direct comparison
            valid = entry[field] == value
        end  
        if not valid then return valid end  
    end
    return valid
end    



return Query