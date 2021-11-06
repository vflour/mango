local Expressions = {}
---@class ExpressionData
type ExpressionData = {
    Variables : {[string]:any},
}
---@class Expression
type Expression = {
    [string]:{}|string
}|string

---Evaluates the expression to return the retrieved data from the expression 
---@param data any
---@param expression any
function Expressions:Evaluate(data,expression,expressionData: ExpressionData?)
    local expressionData : ExpressionData = expressionData or {
        Variables = {}
    }
    -- case 1: expression is a table and you want to recursively evaluate it 
    if typeof(expression) == "table" then
        local result = {}  
        for field,value in pairs(expression) do
            result[field] = Expressions:Evaluate(data,value,expressionData)
        end
        return result  
    -- case 2: expression is a string and it could be a field path, a variable or just a literal       
    elseif typeof(expression) == "string" then
        if Expressions:IsFieldPath(expression) then
            local value = Expressions:GetFieldPathValue(data,expression)
            return value -- you want to return the value *only*
        elseif Expressions:IsVariable(expression) then
            return Expressions:GetVariable(data,expression)    
        end
    end  
    return expression
end

----------- EQUIVALENT TABLE

---Returns true for any tables to be equivalent to its copy
function Expressions:EquivalentTable(t1: {any},t2: {any}) : boolean
    local success,result =  pcall(function() -- call in pcall incase any errors
        for key,value in pairs(t1) do
            if typeof(value)=="table" then -- recursively search through the table
                if not Expressions:EquivalentTable(value,t2[key]) then
                    return false
                end
            else
                if t1[key] ~= t2[key] then
                    return false
                end    
            end   
        end 
        return true
    end) 
    return result == true and success
end 

--- Returns true for any equivalent tables or values.
---@param a any
---@param b any
---@return boolean
function Expressions:AreEquivalent(a,b)
    if typeof(a)~=typeof(b) then return false end
    if typeof(a) == "table" then
        return Expressions:EquivalentTable(a,b)
    else
        return a == b
    end
end

----------- FIELD PATH

---Returns true based on whether or not the value is supposed to be a field path
---@param value string
---@return boolean
function Expressions:IsFieldPath(value:string): boolean
    return Expressions:StartsWithDollarSign(value)
end

---Gets the value resulting from a field path in the entry
---@param data any
---@param path string
---@return any,string,any
function Expressions:GetFieldPathValue(data:any,path:string)
    assert(Expressions:IsFieldPath(path),tostring(path).." is not a valid path")
    path = string.gsub(path,"^%$","") -- remove the $ prefix
    local splitPath = string.split(path,".")
    local value,index,holder = data,nil,nil
    for i, childPath in ipairs(splitPath) do
        holder = value
        value = value[childPath]
        index = childPath       
    end
    return value,index,holder
end

----------- VALUE ASSERTIONS
function Expressions:CantHaveDollarSign(value)
    assert(not Expressions:StartsWithDollarSign(value),"Expression must not start with the '$' character")
end
function Expressions:StartsWithDollarSign(value)
    return string.match(value,"^%$%w*") ~= nil
end

----------- VARIABLES
---Returns whether or not the expression is a variable
---@param value string
---@return boolean
function Expressions:IsVariable(value:string) : boolean
    return string.match(value,"^%$%$%w*") ~= nil
end   

---Stores a variable to expression data
---@param expressionData ExpressionData
---@param name string
---@param value any
function Expressions:StoreVariable(expressionData: ExpressionData, name: string, value: any)
    expressionData.Variables[name] = value
end   

---Gets a variable from expression data
---@param expressionData ExpressionData
---@param name string
---@return any
function Expressions:GetVariable(expressionData: ExpressionData, name: string)
    local index : string = string.gsub(name,"^%$%$%","")
    local value : any = expressionData.Variables[index]
    assert(value,"Invalid variable: "..tostring(index))

    return value
end    

return Expressions