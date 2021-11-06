return function()
    local Collection = require(script.Parent)
    describe("Collection creation",function()
        local customers = Collection.Get("Customers")
        it("Collection count",function()
            expect(#customers._data).to.equal(4)
        end)
    end)
    describe("Customer collection query",function()
        local customers = Collection.Get("Customers")
        it("Get the customer with the id 4 and with name Echyzi",function()
            local query = {FirstName="Echyzi",id=4}
            local result = customers:FindOne(query)
            expect(result.FirstName).to.equal("Echyzi")
        end)
        it("Get all customers with an id of less than 3",function()
            local query = {id={["$lt"]=3}}
            local results = customers:Find(query)
            expect(#results).to.equal(2)
        end)
    end)
    describe("Customer collection aggregation",function()
        local customers = Collection.Get("Customers")
        it("Get the customer with the id 4 and with name Echyzi",function()
            local pipeline = {
                {["$match"]={FirstName="Echyzi",id=4}}
            }
            local result = customers:Aggregate(pipeline)
            expect(result[1].FirstName).to.equal("Echyzi")
        end)
    end)
end