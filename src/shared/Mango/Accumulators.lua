local Accumulators = {}

function Accumulators:IsAccumulator(expression)
    return Accumulators.Accumulators[expression] ~= nil
end

--- Accumulator operations
Accumulators.Accumulators = {}

Accumulators.Accumulators["$avg"] = function(list)
    local sum = 0
    for i, value in ipairs(list) do
        sum+=value
    end
    return sum/#list
end

Accumulators.Accumulators["$sum"] = function(list)
    local sum = 0
    for i, value in ipairs(list) do
        sum = sum+value
    end
    return sum
end

Accumulators.Accumulators["$min"] = function(list)
    local min = list[1]
    for i, value in ipairs(list) do
        if value < min then
            min = value
        end
    end
    return min     
end

Accumulators.Accumulators["$max"] = function(list)
    local max = list[1]
    for i, value in ipairs(list) do
        if value > max then
            max = value
        end
    end
    return max    
end
return Accumulators