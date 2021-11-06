local Dependencies = require(script.Parent.Settings).Dependencies
--- @module Assert
local assertions = Dependencies.Assert

type Accumulators = {
    Accumulators : {({[number]:any})->any}
}
local Accumulators : Accumulators = {}

---Returns true if the provided argument is in the accumulator table
---@param value string
---@return boolean
function Accumulators:IsAccumulator(value) : boolean
    return Accumulators.Accumulators[value] ~= nil
end

--- Accumulator operations
Accumulators.Accumulators = {}

--- The avg value in an array
Accumulators.Accumulators["$avg"] = function(array: {[number]:number} ) : number
    local sum = 0
    for i, value in ipairs(array) do
        assertions.assertType(value,"number")
        sum+=value
    end
    return sum/#array
end

--- The sum of all values in an array
Accumulators.Accumulators["$sum"] = function(array: {[number]:number} ) : number
    local sum = 0
    for i, value in ipairs(array) do
        assertions.assertType(value,"number")
        sum = sum+value
    end
    return sum
end

---The minimum value in an array
Accumulators.Accumulators["$min"] = function(array: {[number]:number} ) : number
    local min = array[1]
    for i, value in ipairs(array) do
        assertions.assertType(value,"number")
        if value < min then
            min = value
        end
    end
    return min     
end

--- The maximum value in an array
Accumulators.Accumulators["$max"] = function(array: {[number]:number} ) : number
    local max = array[1]
    for i, value in ipairs(array) do
        assertions.assertType(value,"number")
        if value > max then
            max = value
        end
    end
    return max    
end

return Accumulators