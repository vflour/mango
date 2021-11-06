
--local Depends = require(game.ReplicatedStorage.Scripts:WaitForChild("Depends"))("Assert")
--- @module Assert
local assertions = require(script.Parent.Settings).Dependencies.Assert
--local assertions = Depends.Assert

type Operator ={
    TopLevel: {({table},{table})->boolean},
    Operator:{(any,any)->boolean},
}
local Operators : Operator = {}

function Operators:HasOperatorSyntax(expression)
    return string.match(expression,"^%$") ~= nil
end
function Operators:TableIsOperation(query)
    local firstN = next(query)
    for key, value in pairs(query) do
        -- only way to check if theres one entry is thru pairs :sadge: 
        if key ~= firstN then return false end
    end
    return Operators:HasOperatorSyntax(firstN)
end

---Default operators: Used under entry fields. Returns a boolean based on how the function evaluates the value and query
Operators.Operator = {} -- Operators that are used under entry fields.

--- Evaluate regular operator
function Operators:Operation(field,data,operatorTable)
    for key,value in pairs(operatorTable) do
        if Operators.Operator[key] then
            if not Operators.Operator[key](data[field],value) then
                return false
            end
        else
            error(key.." is not a valid operator")    
        end    
    end
    return true
end

--- COMPARISON OPERATORS
Operators.Operator["$eq"] = function(value,query)
    return value==query         
end
Operators.Operator["$neq"] = function(value,query)
    return value~=query         
end
Operators.Operator["$lt"] = function(value,query)
    return value < query
end
Operators.Operator["$lte"] = function(value,query)
    return value <= query
end
Operators.Operator["$gt"] = function(value,query)
    return value > query
end
Operators.Operator["$gte"] = function(value,query)
    return value >= query
end
Operators.Operator["$in"] = function(value,query)
    return table.find(query,value)~=nil
end
Operators.Operator["$nin"] = function(value,query)
    return table.find(query,value)==nil
end
--- ELEMENT OPERATORS
Operators.Operator["$exists"] = function(value,query)
    return (value~=nil)==query
end
Operators.Operator["$type"] = function(value,query)
    return typeof(value)==query
end
--- EVALUATION OPERATORS
Operators.Operator["$pattern"] = function(value,query)
    return string.find(value,query)~=nil
end
--- LOGICAL OPERATORS

---Top Level operators sit alongside fields themselves and are called after the sub-queries under it have been evaluated. Usually used to evaluate multiple expressions at once
Operators.TopLevel = {}
function Operators:TopLevelOperation(key,data,operation,callback)
    if Operators.TopLevel[key] then
        return Operators.TopLevel[key](data,operation,callback)
    else
        error(key.." is not a valid high level operator")    
    end   
end

function GetValidationList(data,operation,callback)
    local validationList = {}
    for i,subQuery in ipairs(operation) do
        validationList[i] = callback(data,subQuery)
    end
    return validationList
end    
-- LOGICAL OPERATORS
--- logical and: (x==v1 && x==v2)
Operators.TopLevel["$and"] = function(data,operation,callback)
    for i,valid in ipairs(GetValidationList(data,operation,callback)) do 
        if not valid then
            return false 
        end
    end
    return true
end

---Logical not (!)
--- got lazy and didnt want to add a new case for not, so its now similar to and/or 
Operators.TopLevel["$not"] = function(data,operation,callback)
    return not callback(data,operation)
end

--- logical or: (x==v1 || x==v2)
Operators.TopLevel["$or"] = function(data,operation,callback)
    for i,valid in ipairs(GetValidationList(data,operation,callback)) do 
        if valid then
            return true 
        end
    end
    return false
end

--- logical not or: (x~=v1 || x~=v2)
Operators.TopLevel["$nor"] = function(data,operation,callback)
    for i,valid in ipairs(GetValidationList(data,operation,callback)) do 
        if not valid then
            return true 
        end
    end
    return false
end

return Operators
