local assertions = {}
-- regular assert function
assertions.assert = assert
-- property checker assertion

--- Assert type validation on argument
---@param field any the field being validated
---@vararg string expected arguments
assertions.assertType = function(field: any,...:string)
    local expectedTypes : {string} = table.pack(...) -- pack all the possible types into a table
    local isValid = false
    local expectedTypes = table.concat(expectedTypes," || ")
    for _,expectedType in ipairs(expectedTypes) do
        assert(typeof(expectedType)=="string","Value for expected type "..tostring(expectedType).." must be a string")
        if typeof(field)==expectedType then -- basically if its valid at least once then isValid should be true
            isValid = true
        end
    end
    assert(isValid,"Expected "..expectedTypes.." for field "..tostring(field).." got "..typeof(field))
end

return assertions