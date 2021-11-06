return function()
    ---@module Stages
    local Stages = require(script.Parent)
    ---@module Expressions
    local expressions = require(script.Parent.Parent.Expressions)

    local collection = {
        {FirstName="John", LastName="Burgers", group=12, Company={ Name="Verizon", Country="Canada"} },
        {FirstName="Casey", LastName="Pines", group=2, Company={ Name="Verizon", Country="Canda"} },
        {FirstName="John", LastName="Field", group=3, Company={ Name="Bell", Country="USA"} },
        {FirstName="Finn", LastName="Michigan", group=5, Company={ Name="Europhone", Country="France"} },
    }

    describe("Expressions", function()
        it("Path value", function()
            local value = expressions:Evaluate(collection[1],"$FirstName")
            expect(value).to.equal("John")
        end)
        it("Embedded object path value", function()
            local value = expressions:Evaluate(collection[1],"$Company.Name")
            expect(value).to.equal("Verizon")
        end)
    end)

    describe("Group", function()
        it("Single id", function()
            local query = {
                id="$FirstName"
            }
            local output = Stages["$group"](collection,query)
            expect(output).to.be.ok()
            --expect(#output).to.equal(3)
        end)
        it("Embedded table id", function()
            local query = {
                id="$Company"
            }
            local output = Stages["$group"](collection,query)
            expect(#output).to.equal(2)
        end)
        it("Joint id", function()
            local query = {
                id={Name="$FirstName",Group="$group"}
            }
            local output = Stages["$group"](collection,query)
            expect(#output).to.equal(12)
        end)
    end)
end