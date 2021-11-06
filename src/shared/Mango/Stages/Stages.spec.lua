return function()
    ---@module Stages
    local Stages = require(script.Parent)
    ---@module Expressions
    local expressions = require(script.Parent.Parent.Expressions)

    local collection = {
        {FirstName="John", LastName="Burgers", group=12, Company={ Name="Verizon", Country="USA"} },
        {FirstName="Casey", LastName="Pines", group=2, Company={ Name="Verizon", Country="USA"} },
        {FirstName="John", LastName="Field", group=3, Company={ Name="Bell", Country="Canada"} },
        {FirstName="Finn", LastName="Michigan", group=5, Company={ Name="Europhone", Country="France"} },
    }

    describe("Expressions", function()
        it("Path value", function()
            local value = expressions:Evaluate(collection[1],"$FirstName")
            expect(value).to.equal("John")
        end)
        it("Expression value with paths", function()
            local value = expressions:Evaluate(collection[1],{Name="$FirstName",Group="$group"})
            expect(value.Name).to.equal("John")
            expect(value.Group).to.equal(12)
        end)
        it("Embedded object path", function()
            local value = expressions:Evaluate(collection[1],"$Company")
            expect(value.Name).to.equal("Verizon")
        end)
        it("Embedded object path value", function()
            local value = expressions:Evaluate(collection[1],"$Company.Name")
            expect(value).to.equal("Verizon")
        end)
        it("Equivalent tables",function()
            local isEquivalent = expressions:EquivalentTable(collection[1].Company,collection[2].Company)
            expect(isEquivalent).to.equal(true)
        end)
    end)

    describe("Group", function()
        it("Single id", function()
            local query = {
                id="$FirstName"
            }
            local output = Stages["$group"](collection,query)
            expect(#output).to.equal(3)
        end)
        it("Embedded table id", function()
            local query = {
                id="$Company"
            }
            local output = Stages["$group"](collection,query)
            expect(#output).to.equal(3)
        end)
        it("Joint id", function()
            local query = {
                id={Name="$FirstName",Group="$group"}
            }
            local output = Stages["$group"](collection,query)
            expect(#output).to.equal(4)
        end)

        it("Joint id and embedded table id",function()
            local query = {
                id={Company="$Company",CompanyName="$Company.Name"},
            }
            local output = Stages["$group"](collection,query)
            expect(#output).to.be.equal(3)
            expect(output[1].id.Company.Name).to.be.equal(output[1].id.CompanyName)
        end)
    end)
end