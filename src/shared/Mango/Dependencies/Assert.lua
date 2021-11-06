local assertions = {}
-- regular assert function
assertions.assert = assert
-- property checker assertion

--- Assert type validation on argument
---@param field any the field being validated
---@vararg string expected arguments
assertions.assertType = function(field: any,...:string)
    local expectedTypes : {string} = table.pack(...) -- pack all the possible types into a table
    local typeString = table.concat(expectedTypes," || ")

    for _,expectedType in ipairs(expectedTypes) do
        assert(typeof(expectedType)=="string","Value for expected type "..tostring(expectedType).." must be a string")
        -- basically if its valid at least once then exit
        if typeof(field)==expectedType then
            return
        end
    end
    assert(false,"Expected "..typeString.." for field "..tostring(field).." got "..typeof(field))
end
--- Assert instance validation on argument
---@param field any the field being validated
---@vararg string expected arguments
assertions.assertIsA = function(field: any,...:string)
    -- first assert instance
    assertions.assertType(field,"Instance")
    -- then assert IsA relationship
    local expectedTypes : {string} = table.pack(...) -- pack all the possible types into a table
    local typeString = table.concat(expectedTypes," || ")
    for _,expectedType in ipairs(expectedTypes) do
        assert(typeof(expectedType)=="string","Value for expected type "..tostring(expectedType).." must be a string")
        if field:IsA(expectedType) then
            return 
        end
    end
    assert(false,"Expected "..typeString.." for field "..tostring(field).." got Instance of type "..typeof(field))
end

return assertions