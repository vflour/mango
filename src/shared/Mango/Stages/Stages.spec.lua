return function()
    ---@module Stages
    local Stages = require(script.Parent)
    ---@module Collection
    local Collection = require(script.Parent.Parent.Collection)
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
        it("Accumulator grouping",function()
            local query = {
                id={CompanyName="$Company.Name"},
                ["$sum"]="$group",
            }
            local groups = Stages:GroupInputEntries(collection,query)
            expect(groups[next(groups)]["$sum"][1]).to.equal(12)
        end)
        it("Accumulators",function()
            local query = {
                id={CompanyName="$Company.Name"},
                ["$min"]="$group",
                ["$max"]="$group",
                ["$avg"]="$group",
                ["$sum"]="$group",
            }
            local output = Stages["$group"](collection,query)
    
            expect(output[1]["min"]).to.equal(2)
            expect(output[1]["max"]).to.equal(12)
            expect(output[1]["avg"]).to.equal(7)
            expect(output[1]["sum"]).to.equal(14)
        end)
    end)

    describe("Lookup", function()
        local collection = Collection.Get("Customers")
        it("Foreign collection lookup", function()
            local query = {
                from="Books",
                localField="$Favourites.Book",
                foreignField="$id",
                as="FavouriteBook"
            }
            local output = Stages["$lookup"](collection._data,query)
            expect(output[1].FavouriteBook[1]).to.be.ok()
            expect(output[1].FavouriteBook[1].Title).to.be.ok()
            expect(output[1].FavouriteBook[1].Title).to.equal("Lolz")
        end)
        it("Self join lookup", function()
            local query = {
                from="Customers",
                localField="$Inviter",
                foreignField="$id",
                as="Inviter"
            }
            local output = Stages["$lookup"](collection._data,query)
            expect(output[2].Inviter[1]).to.be.ok()
            expect(output[2].Inviter[1].FirstName).to.equal("John")
        end)
    end)

    describe("Project", function()
        it("Exclusion",function()
            local query = {
                FirstName = 0,
                group = false
            }
            local output = Stages["$project"](collection,query)
            expect(output[1].FirstName).to.never.be.ok()
            expect(output[1].LastName).to.be.ok()
            expect(output[1].group).to.never.be.ok()
        end)
        it("Inclusion",function()
            local query = {
                FirstName = 1,
            }
            local output = Stages["$project"](collection,query)
            expect(output[1].FirstName).to.be.ok()
            expect(output[1].LastName).to.never.be.ok()
        end)
        it("Redefinition, Inclusion",function()
            local query = {
                FirstName = 1,
                Company = "$Company.Name",
                group = false,
            }
            local output = Stages["$project"](collection,query)
            expect(output[1].FirstName).to.be.ok()
            expect(output[1].LastName).to.never.be.ok()
            expect(output[1].group).to.never.be.ok()
            expect(output[1].Company).to.equal("Verizon")
        end)
    end)

    describe("Unwind", function()
        local collection = Collection.Get("Customers")
        it("Test if output",function()
            local query = {
                path="$Friends"
            }
            local output = Stages["$unwind"](collection._data,query)
            expect(output[1]).to.be.ok()
        end)
        it("Test individual entries",function()
            local query = {
                path="$Friends"
            }
            local output = Stages["$unwind"](collection._data,query)
            expect(output[1].id).to.equal(1)
            expect(output[1].Friends).to.equal(2)
            expect(output[2].id).to.equal(1)
            expect(output[2].Friends).to.equal(3)
            -- it should be id 2 since theres no more friends in id 1
            expect(output[3].id).to.equal(2)
        end)
        it("Include array index",function()
            local query = {
                path="$Friends",
                includeArrayIndex = "FriendLink"
            }
            local output = Stages["$unwind"](collection._data,query)
            expect(output[1].id).to.equal(1)
            expect(output[1].FriendLink).to.equal(2)
            expect(output[2].id).to.equal(1)
            expect(output[2].FriendLink).to.equal(3)
            -- test original array
            expect(output[1].Friends).to.be.a("table")
        end)
        it("Exclude Null and Empty Arrays",function()
            local query = {
                path="$Wallet",
            }
            local output = Stages["$unwind"](collection._data,query)

            expect(output[1].id).to.equal(2) -- added in because it's not an array
            expect(output[2].id).to.equal(4)
        end)
        it("Preserve Null and Empty Arrays",function()
            local query = {
                path="$Wallet",
                preserveNullAndEmptyArrays=true,
            }
            local output = Stages["$unwind"](collection._data,query)
            expect(output[1].id).to.equal(1) -- first entry should exist
            expect(output[2].id).to.equal(2) -- second entry should exist
            expect(output[3].id).to.equal(3) -- second entry should also exist

            expect(output[4].id).to.equal(4)
            expect(output[4].Wallet).to.equal("Steam")
            expect(output[5].Wallet).to.equal("Paypal")
        end)
    end)
end