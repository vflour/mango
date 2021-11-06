local TestEZ = require(game.ReplicatedStorage.Common.testez)
local result = TestEZ.TestBootstrap:run{game.ReplicatedStorage.Common.Mango.Stages["Stages.spec"]}
function printTable(t,layer)
    local indent = string.rep(" ",layer)
    for i,value in pairs(result) do
        print(indent,i,value)
    end
end
printTable(result,0)
printTable(result.children,1)