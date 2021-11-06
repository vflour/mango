return function()
    local Query = require(script.Parent)
    local collection = {
        {FirstName="John",LastName="Burgers",group=12},
        {FirstName="Casey",LastName="Pines",group=2}
    }

    --[[describe("Test Equality evaluation for FirstName John", function()
        it("Test if there's an output", function()
            local query = {FirstName="John"}
            local output = Query(collection,query)
            expect(output[1]).to.be.ok()
        end)
        it("There shouldn't be a second entry", function()
            local query = {FirstName="John"}
            local output = Query(collection,query)
            expect(output[2]).to.never.be.ok()
        end)
        it("The FirstName should be John", function()
            local query = {FirstName="John"}
            local output = Query(collection,query)
            expect(output[1].FirstName).to.equal("John")
        end)
    end)

    describe("Test operator syntax", function()
        it("eq operator", function()
            local query = {group={["$eq"]=12}}
            local output = Query(collection,query)
            
            expect(output[1].group).to.equal(12)
            return output
        end)
        it("gt operator", function()
            local query = {group={["$gt"]=2}}
            local output = Query(collection,query)
            
            expect(#output).to.equal(1)
            return output
        end)
        it("gte operator", function()
            local query = {group={["$gte"]=2}}
            local output = Query(collection,query)
            
            expect(#output).to.equal(2)
            return output
        end)
        it("lt operator", function()
            local query = {group={["$lt"]=12}}
            local output = Query(collection,query)
            
            expect(#output).to.equal(1)
            return output
        end)
        it("lte operator", function()
            local query = {group={["$lte"]=12}}
            local output = Query(collection,query)
            
            expect(#output).to.equal(2)
            return output
        end)
        it("in operator", function()
            local query = {LastName={["$in"]={"Pines","Burgers"}}}
            local output = Query(collection,query)
            
            expect(#output).to.equal(2)
            return output
        end)
        it("nin operator", function()
            local query = {LastName={["$nin"]={"Pines"}}}
            local output = Query(collection,query)
            
            expect(output[1].FirstName).to.equal("John")
            return output
        end)
        it("exists operator", function()
            local query = {PotatoSack={["$exists"]=false}}
            local output = Query(collection,query)
            
            expect(#output).to.equal(2)
            return output
        end)
        it("type operator", function()
            local query = {group={["$type"]="number"}}
            local output = Query(collection,query)
            
            expect(#output).to.equal(2)
            return output
        end)
        it("pattern operator", function()
            local query = {FirstName={["$pattern"]="Jo%w"}}
            local output = Query(collection,query)
            
            expect(#output).to.equal(1)
            return output
        end)
    end)

    describe("Test high level operators", function()
        FOCUS()
        local collection = {
            {FirstName="John",LastName="Burgers",group=12},
            {FirstName="Casey",LastName="Pines",group=2},
            {FirstName="John",LastName="Field",group=3},
            {FirstName="Finn",LastName="Michigan",group=5},
        }
        it("and operator", function()
            local query = {
                ["$and"]={
                    {FirstName="John"},
                    {LastName="Burgers"}
                }
            }
            local output = Query(collection,query)
            expect(#output).to.equal(1)
        end)
        it("or operator", function()
            local query = {
                ["$or"]={
                    {FirstName="John"},
                    {FirstName="Finn"}
                }
            }
            local output = Query(collection,query)
            expect(#output).to.equal(3)
        end)
        --FIXME("Check the documentation for this. Unsure if it's correct.")
        it("nor operator", function()
            local query = {
                ["$nor"]={
                    {FirstName="John"},
                }
            }
            local output = Query(collection,query)
            expect(#output).to.equal(2)
        end)
        it("not operator", function()
            local query = {
                ["$not"]={
                    ["$or"]={
                        {FirstName="John"},
                        {FirstName="Finn"},
                    }
                }
            }
            local output = Query(collection,query)
            expect(#output).to.equal(1)
        end)
    end)--]]
end