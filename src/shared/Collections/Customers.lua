local Customers = {}
Customers.Schema = {}
Customers.Data ={
    {
        id=1,
        FirstName="John",
        LastName="Shedletsky",
        Friends={2,3},
        Favourites = {
            Book="book_1"
        }
    },
    {
        id=2,
        FirstName="Muriel",
        LastName="None",
        Friends={1},
        Favourites = {
            Book="book_1"
        }
    },
    {
        id=3,
        FirstName="Pepper",
        LastName="Piper",
        Friends={1},
        Favourites = {
            Book="book_2"
        }
    },
    {
        id=4,
        FirstName="Echyzi",
        LastName="EnidMaybe",
        Friends={},
        Favourites = {
            Book="book_3"
        }
    }
}
return Customers