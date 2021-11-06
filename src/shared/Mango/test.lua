local data = {
    firstName="Cedric",
    lastName="Keeley",
    class=6,
    bag={
        pencils=6,
        pockets=1,
        hasZipper=true,
    } 
        
}
local associators = {
    ["$and"]=true
}
local operators = {
    ["$or"]=true
}
-- layer 1
function eval(data, query)
    for key,value in pairs(query) do
        if data[key]~=value then
            return false
        end
    end
    return true
end    
print("Evaluations:")
print(eval(data,{firstName="Cedric",lastName="Keeley"}))

-- layer 2: basic operations
-- very shittily implemented
function operation(datavalue,queryvalue)
    return datavalue==queryvalue
end
function eval2(data, query)
    for key,value in pairs(query) do
        if type(value)=="table" then
            local result = evalOperators(key,data,value)
            if not result then
                return false
            end
        else    
            if key=="$eq" then
                if not operation(key,data,value) then
                    return false
                end        
            end
            if data[key]~=value then
                return false
            end
        end
    end
    return true
end    
function evalOperators(key,data,operatorTable)
    for i,value in pairs(operatorTable) do
        if i=="$eq" then
            if not operation(data[key],value) then
                return false
            end
        end    
    end
    return true
end
print("Operations:")
print(eval2(data,{firstName="Cedric",class={["$eq"]=6} }))

-- layer 3: and/or associations
-- very shittily implemented

function eval3(data, query)
    for key,value in pairs(query) do
        if string.match(key,"^%$")~=nil then
            local associatorMatch = evalAssociators(key,data,value)   
            if not associatorMatch then 
                return false
            end             
        end

        if type(value)=="table" then
            local result = evalOperators(key,data,value)
            if not result then
                return false
            end
        else    
            if key=="$eq" then
                if not operation(key,data,value) then
                    return false
                end        
            end
            if data[key]~=value then
                return false
            end
        end
    end
    return true
end    

function evalAssociators(key,data,query)
    local validationList = {}
    for i,subQuery in ipairs(query) do
        validationList[i] = eval3(data,subQuery)
    end

    if associators[key] then
        return association(validationList)
    else
        error(key.." is not a valid high level operator")    
    end    
end 
function association(validationList)
    for i,v in ipairs(validationList) do
        if v==false then
            return false
        end
    end
    return true
end


print("Associations:")
print(eval3(data,{["$and"]={{firstName="Cedric"},{class={["$eq"]=6}}} }))