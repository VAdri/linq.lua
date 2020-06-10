local Linq = require "linq";
require "list";
require "hashSet";

--- @type List|OrderedEnumerable|Enumerable
local List = Linq.List;

--- @type Enumerable
local Enumerable = Linq.Enumerable;

-- =====================================================================================================================
-- == Integration Tests
-- =====================================================================================================================

describe("Immutability", function()
    it("doesn't modify the source sequence after filtering", function()
        local petOwners = {
            { Name = "Higa", Pets = { "Scruffy", "Sam" } },
            { Name = "Ashkenazi", Pets = { "Walker", "Sugar" } },
            { Name = "Price", Pets = { "Scratches", "Diesel" } },
            { Name = "Hines", Pets = { "Dusty" } }
        };

        local list = Enumerable.From(petOwners);
        local results = list:Where(function(petOwner) return #petOwner.Pets == 2; end):ToArray();

        assert.same(
            {
                { Name = "Higa", Pets = { "Scruffy", "Sam" } },
                { Name = "Ashkenazi", Pets = { "Walker", "Sugar" } },
                { Name = "Price", Pets = { "Scratches", "Diesel" } },
            },
            results
        );
        assert.same(
            {
                { Name = "Higa", Pets = { "Scruffy", "Sam" } },
                { Name = "Ashkenazi", Pets = { "Walker", "Sugar" } },
                { Name = "Price", Pets = { "Scratches", "Diesel" } },
                { Name = "Hines", Pets = { "Dusty" } }
            },
            petOwners
        );
        assert.same(petOwners, list.source);
    end);

    it("doesn't modify the source sequence after mapping", function()
        local petOwners = {
            { Name = "Higa", Pets = { "Scruffy", "Sam" } },
            { Name = "Ashkenazi", Pets = { "Walker", "Sugar" } },
            { Name = "Price", Pets = { "Scratches", "Diesel" } },
            { Name = "Hines", Pets = { "Dusty" } }
        };

        local list = Enumerable.From(petOwners);
        local results = list:Select(function(petOwner) return { Name = petOwner.Name, Pets = table.concat(petOwner.Pets, ",")}; end):ToArray();

        assert.same(
            {
                { Name = "Higa", Pets = "Scruffy,Sam" },
                { Name = "Ashkenazi", Pets = "Walker,Sugar" },
                { Name = "Price", Pets = "Scratches,Diesel" },
                { Name = "Hines", Pets = "Dusty" }
            },
            results
        );
        assert.same(
            {
                { Name = "Higa", Pets = { "Scruffy", "Sam" } },
                { Name = "Ashkenazi", Pets = { "Walker", "Sugar" } },
                { Name = "Price", Pets = { "Scratches", "Diesel" } },
                { Name = "Hines", Pets = { "Dusty" } }
            },
            petOwners
        );
        assert.same(petOwners, list.source);
    end);

    it("modifies the source sequence when the mapping modifiy the given item", function()
        local petOwners = {
            { Name = "Higa", Pets = { "Scruffy", "Sam" } },
            { Name = "Ashkenazi", Pets = { "Walker", "Sugar" } },
            { Name = "Price", Pets = { "Scratches", "Diesel" } },
            { Name = "Hines", Pets = { "Dusty" } }
        };

        local list = Enumerable.From(petOwners);
        local results = list
            :Select(
                function(petOwner)
                    petOwner.Pets = table.concat(petOwner.Pets, ",");
                    return { Name = petOwner.Name, Pets = petOwner.Pets};
                end
            )
            :ToArray();

        assert.same(
            {
                { Name = "Higa", Pets = "Scruffy,Sam" },
                { Name = "Ashkenazi", Pets = "Walker,Sugar" },
                { Name = "Price", Pets = "Scratches,Diesel" },
                { Name = "Hines", Pets = "Dusty" }
            },
            results
        );
        assert.same(
            {
                { Name = "Higa", Pets = "Scruffy,Sam" },
                { Name = "Ashkenazi", Pets = "Walker,Sugar" },
                { Name = "Price", Pets = "Scratches,Diesel" },
                { Name = "Hines", Pets = "Dusty" }
            },
            petOwners
        );
        assert.same(petOwners, list.source);
    end);
end);

describe("Chaining operations", function()
    it("filters multiple times", function()
        local grades = { 59, 82, 70, 56, 92, 98, 85 };
        local results = Enumerable.From(grades)
            :Where(function(n) return n >= 70; end)
            :Where(function(n) return n <= 95; end)
            :ToArray();
        assert.same({ 82, 70, 92, 85 }, results);
    end);

    it("executes the operations in the correct order", function()
        local numbers = Enumerable.Range(1, 5)
            :Select(function(n) return n - 1; end)
            :Select(function(n) return n * 2; end);
        assert.same({ 0, 2, 4, 6, 8 }, numbers:ToArray());
    end);

    it("skips multiple times", function()
        local grades = { 59, 82, 70, 56, 92, 98, 85 };
        assert.same({ 92, 98, 85 }, Enumerable.From(grades):Skip(3):Skip(1):ToArray());
    end);

    it("skips and takes", function()
        local grades = { 59, 82, 70, 56, 92, 98, 85 };
        assert.same({ 56, 92 }, Enumerable.From(grades):Skip(3):Take(2):ToArray());
    end);

    it("skips after filtering and selecting many", function()
        local petOwners = {
            { Name = "Higa", Pets = { "Scruffy", "Sam" } },
            { Name = "Ashkenazi", Pets = { "Walker", "Sugar" } },
            { Name = "Price", Pets = { "Scratches", "Diesel" } },
            { Name = "Hines", Pets = { "Dusty" } }
        };

        local results = Enumerable.From(petOwners)
            :SelectMany(
                function(petOwner) return petOwner.Pets; end,
                function(petOwner, petName) return { Owner = petOwner.Name, Pet = petName }; end
            )
            :Where(function(petOwner) return petOwner.Pet:sub(1, 1) == "S"; end)
            :Skip(1)
            :ToArray();

        assert.same(
            {
                { Owner = "Higa", Pet = "Sam" },
                { Owner = "Ashkenazi", Pet = "Sugar" },
                { Owner = "Price", Pet = "Scratches" },
            },
            results
        );
    end);
end);

describe("Multiple queries on the same instance", function()
    it("resets the iterator between each query", function()
        local array = Enumerable.Range(1, 5);
        assert.is_true(array:Contains(1));
        assert.is_true(array:Contains(3));
    end);
end);

describe("Deferred execution", function()
    it("doesn't traverse the pipeline until a result operation has been called", function()
        local enumeration = 0;

        local query = Enumerable.Range(1, 10)
            :Skip(3)
            :Take(3)
            :Select(function(n) enumeration = enumeration + 1; return n; end);

        assert.equal(0, enumeration);

        local results = query:ToArray();

        assert.equal(3, enumeration);
        assert.same({4, 5, 6}, results);
    end);

    it("traverse only elements that are taken in the final result", function()
        local initialEnumeration = 0;
        local finalEnumeration = 0;

        local query = Enumerable.Range(1, 10)
            :Select(function(n) initialEnumeration = initialEnumeration + 1; return n; end)
            :Skip(3)
            :Take(3)
            :Select(function(n) finalEnumeration = finalEnumeration + 1; return n; end);

        assert.equal(0, initialEnumeration);
        assert.equal(0, finalEnumeration);

        local results = query:ToArray();

        assert.equal(6, initialEnumeration);
        assert.equal(3, finalEnumeration);
        assert.same({4, 5, 6}, results);
    end);
end);

describe("Calling GetEnumerator", function()
    it("iterates over the elements", function()
        local i = 0;
        for key, value in Enumerable.Range(1, 10):GetEnumerator() do
            i = i + 1;
            assert.equal(i, key);
            assert.equal(i, value);
        end
    end);
end);

describe("Saving a query", function()
    it("allows to reuse the query", function()
        local input = {1, 2, 3, 4, 5};

        local query = Enumerable.From(input):Where(function(i) return i >= 2; end):Skip(1);

        assert.same({3, 4, 5}, query:ToArray());
        assert.same({5, 4, 3}, query:Reverse():ToArray());
        assert.same({4}, query:Skip(1):Take(1):ToArray());
        assert.same(12, query:Sum());
    end);

    it("reuse the enumerable with its new state", function()
        local first = {1, 2, 3, 4, 5};
        local second = List.New({6, 7, 8});
        local third = List.New({10, 11, 12});
        local except = List.New({3});

        local query = Enumerable.From(first):Concat(second):Except(except):Union(third);
        assert.same({1, 2, 4, 5, 6, 7, 8, 10, 11, 12}, query:ToArray());

        second:Add(9);
        third:Add(13);
        except:Add(7);
        assert.same({1, 2, 4, 5, 6, 8, 9, 10, 11, 12, 13}, query:ToArray());
    end);
end);

-- =====================================================================================================================
-- == Enumerable Unit Tests
-- =====================================================================================================================

describe("Enumerable:Aggregate", function()
    it("reduces the value correctly", function()
        local input = {"the", "quick", "brown", "fox", "jumps", "over", "the", "lazy", "dog"};
        local result = Enumerable.From(input):Aggregate("!", function(sentence, nextWord) return nextWord.." "..sentence; end);
        assert.equal("dog lazy the over jumps fox brown quick the !", result);
    end);
end);

describe("Enumerable:All", function()
    it("returns true on an empty input", function()
        local input = {};
        local result = Enumerable.From(input):All(function(i) return i >= 0; end);
        assert.is_true(result);
    end);

    it("returns true when all the elements satisfy the condition", function()
        local input = {0, 1, 2, 3};
        local result = Enumerable.From(input):All(function(i) return i >= 0; end);
        assert.is_true(result);
    end);

    it("returns false when one the elements does not satisfy the condition", function()
        local input = {0, 1, 2, 3, -1};
        local result = Enumerable.From(input):All(function(i) return i >= 0; end);
        assert.is_false(result);
    end);
end);

describe("Enumerable:Any", function()
    it("returns false on an empty input", function()
        local input = {};
        assert.is_false(Enumerable.From(input):Any());
        assert.is_false(Enumerable.From(input):Any(function(i) return i >= 0; end));
    end);

    it("returns true when any of the elements satisfy the condition", function()
        local input = {0, 1, 2, 3};
        local result = Enumerable.From(input):Any(function(i) return i >= 3; end);
        assert.is_true(result);
    end);

    it("returns false when none of the elements satisfy the condition", function()
        local input = {0, 1, 2, 3};
        local result = Enumerable.From(input):Any(function(i) return i < 0; end);
        assert.is_false(result);
    end);
end);

describe("Enumerable:Append", function()
    it("adds an element at the end of the sequence", function()
        local input = {1, 2, 3, 4, 5};
        assert.is_same({1, 2, 3, 4, 5, 6}, Enumerable.From(input):Append(6):ToArray());
    end);

    it("adds an element on an empty sequence", function()
        local input = {};
        assert.is_same({1}, Enumerable.From(input):Append(1):ToArray());
    end);
end);

describe("Enumerable:Average", function()
    it("calculates the average of the sequence", function()
        local input = {78, 92, 100, 37, 81};
        assert.equal(77.6, Enumerable.From(input):Average());
    end);

    it("calculates the average of the sequence after transformation", function()
        local input = {{ Age = 15, Name = "Cathy" }, { Age = 25, Name = "Alice" }, { Age = 50, Name = "Bob" }};
        assert.equal(30, Enumerable.From(input):Average(function(person) return person.Age; end));
    end);

    -- https://github.com/Olivine-Labs/busted/issues/453
    -- it("returns NaN if the source is empty", function()
    --     assert.same(0/0, Enumerable.From({}):Average());
    -- end);
end);

describe("Enumerable:Concat", function()
    it("concatenates two empty sequences", function()
        assert.same({}, Enumerable.From({}):Concat({}):ToArray());
    end);

    it("concatenates an empty sequence to a filled sequence", function()
        assert.same({1, 2, 3}, Enumerable.From({1, 2, 3}):Concat({}):ToArray());
        assert.same({1, 2, 3}, Enumerable.From({}):Concat({1, 2, 3}):ToArray());
    end);

    it("concatenates two filled sequences", function()
        assert.same({1, 2, 3, 3, 4, 5}, Enumerable.From({1, 2, 3}):Concat({3, 4, 5}):ToArray());
    end);

    it("concatenates with an enumerable", function()
        assert.same({1, 2, 3, 3, 4, 5}, Enumerable.From({1, 2, 3}):Concat(Enumerable.From({3, 4, 5})):ToArray());
    end);
end);

describe("Enumerable:Contains", function()
    it("is true when the sequence contains the element", function()
        assert.is_true(Enumerable.From({"apple", "banana", "peach"}):Contains("banana"));
        local element = {};
        assert.is_true(Enumerable.From({1, 2, element, 4}):Contains(element));
    end);

    it("is true when the sequence contains an element that is equal according to the comparer", function()
        local ignoreCaseComparer = function(fruit1, fruit2) return fruit1:lower() == fruit2:lower(); end
        assert.is_true(Enumerable.From({"apple", "banana", "peach"}):Contains("BANANA", ignoreCaseComparer));
    end);

    it("is false when the sequence does not contain the element", function()
        assert.is_false(Enumerable.From({"apple", "banana", "peach"}):Contains("ananas"));
        assert.is_false(Enumerable.From({1, 2, {}, 4}):Contains({}));
    end);

    it("is false when the sequence does not contain an element that is equal according to the comparer", function()
        local alwaysFalseComparer = function() return false; end
        assert.is_false(Enumerable.From({"apple", "banana", "peach"}):Contains("banana", alwaysFalseComparer));
    end);
end);

describe("Enumerable:Count", function()
    it("returns the number elements in the input sequence", function()
        assert.equal(5, Enumerable.From({1, 2, 3, 4, 5}):Count());
    end);

    it("returns a number that represents how many elements in the sequence satisfy the condition in the predicate function", function()
        assert.equal(3, Enumerable.From({1, 2, 3, 4, 5}):Count(function(i) return i >= 3; end));
    end);
end);

describe("Enumerable:DefaultIfEmpty", function()
    it("returns the default value if the source is empty", function()
        assert.same({1}, Enumerable.From({}):DefaultIfEmpty(1):ToArray());
        assert.same({"a"}, Enumerable.From({}):DefaultIfEmpty("a"):ToArray());
        assert.same({{}}, Enumerable.From({}):DefaultIfEmpty({}):ToArray());
    end);

    it("returns the source array if it is not empty", function()
        assert.same({1, 2, 3, 4, 5}, Enumerable.From({1, 2, 3, 4, 5}):DefaultIfEmpty(1):ToArray());
        assert.same({1, 2, 3, 4, 5}, Enumerable.From({1, 2, 3, 4, 5}):DefaultIfEmpty("a"):ToArray());
        assert.same({1, 2, 3, 4, 5}, Enumerable.From({1, 2, 3, 4, 5}):DefaultIfEmpty({}):ToArray());
    end);
end);

describe("Enumerable:Distinct", function()
    it("removes elements that are duplicate", function()
        assert.same({21, 46, 55, 17}, Enumerable.From({21, 46, 46, 55, 17, 21, 55, 55}):Distinct():ToArray());
    end);

    it("removes no element when there is no duplicate", function()
        assert.same({"a", "b", "c"}, Enumerable.From({"a", "b", "c"}):Distinct():ToArray());
        assert.same({{}, {}, {}}, Enumerable.From({{}, {}, {}}):Distinct():ToArray());
    end);

    it("removes elements that are duplicate according to the comparer", function()
        local input = {
            { Age = 1, Name = "Whiskers" },
            { Age = 4, Name = "Boots" },
            { Age = 8, Name = "Barley" },
            { Age = 4, Name = "Daisy" },
            { Age = 9, Name = "Felix" }
        };
        assert.same(
            {{ Age = 1, Name = "Whiskers" }, { Age = 4, Name = "Boots" }, { Age = 8, Name = "Barley" }, { Age = 9, Name = "Felix" }},
            Enumerable.From(input):Distinct(function(pet1, pet2) return pet1.Age == pet2.Age; end):ToArray()
        );
    end);

    it("removes no element when there is no duplicate according to the comparer", function()
        local input = {
            { Age = 1, Name = "Whiskers" },
            { Age = 8, Name = "Barley" },
            { Age = 4, Name = "Daisy" }
        };
        assert.same(
            {{ Age = 1, Name = "Whiskers" }, { Age = 8, Name = "Barley" }, { Age = 4, Name = "Daisy" }},
            Enumerable.From(input):Distinct(function(pet1, pet2) return pet1.Age == pet2.Age; end):ToArray()
        );
    end);
end);

describe("Enumerable:ElementAt", function()
    it("returns the element at the given index", function()
        assert.equal(2, Enumerable.From({1, 2, 3, 4}):ElementAt(2));
        assert.equal(3, Enumerable.From({a = 1, [1] = 2, [true] = 3, [{}] = 4}):ElementAt(2));
    end);

    it("raises an error if the index is lesser or equal to zero", function()
        assert.has_error(
            function() Enumerable.From({1, 2, 3, 4}):ElementAt(0); end,
            "index must be greater than zero."
        );
        assert.has_error(
            function() Enumerable.From({1, 2, 3, 4}):ElementAt(-1); end,
            "index must be greater than zero."
        );
    end);

    it("raises an error if the index is greater than the number of elements in source", function()
        assert.has_error(
            function() Enumerable.From({1, 2, 3, 4}):ElementAt(5); end,
            "index must be lesser or equal to the number of elements in source."
        );
    end);
end);

describe("Enumerable:ElementAt", function()
    it("returns the element at the given index", function()
        assert.equal(2, Enumerable.From({1, 2, 3, 4}):ElementAtOrDefault(2, "default"));
        assert.equal(2, Enumerable.From({1, 2, 3, 4}):ElementAtOrDefault(2, nil));
    end);

    it("returns the default value if the index is lesser or equal to zero", function()
        assert.equal("default", Enumerable.From({1, 2, 3, 4}):ElementAtOrDefault(0, "default"));
        assert.equal("default", Enumerable.From({1, 2, 3, 4}):ElementAtOrDefault(-1, "default"));
        assert.equal(nil, Enumerable.From({1, 2, 3, 4}):ElementAtOrDefault(-1, nil));
    end);

    it("returns the default value if the index is greater than the number of elements in source", function()
        assert.equal("default", Enumerable.From({1, 2, 3, 4}):ElementAtOrDefault(5, "default"));
        assert.equal(nil, Enumerable.From({1, 2, 3, 4}):ElementAtOrDefault(5, nil));
    end);
end);

describe("Enumerable.Empty", function()
    it("returns an empty enumerable", function()
        local empty = Enumerable.Empty();
        assert.same({}, empty:ToArray());
    end);

    it("returns an empty enumerable that can be used with operations", function()
        local empty = Enumerable.Empty();
        assert.same({1}, empty:Append(1):ToArray());
    end);
end);

describe("Enumerable:Except", function()
    it("returns the set difference of the elements of two sequences", function()
        assert.same({2, 2.1, 2.4, 2.5}, Enumerable.From({2.0, 2.1, 2.2, 2.3, 2.4, 2.5}):Except({2.2, 2.3}):ToArray());
    end);

    it("returns the set difference of the elements of two enumerables", function()
        assert.same(
            {2, 2.1, 2.4, 2.5},
            Enumerable.From({2.0, 2.1, 2.2, 2.3, 2.4, 2.5}):Except(List.New({2.2, 2.3})):ToArray()
        );
    end);

    it("returns the set difference of the elements of two sequences according to the given comparer", function()
        local ignoreCaseComparer = function(fruit1, fruit2) return fruit1:lower() == fruit2:lower(); end
        assert.same({"apple", "kiwi"}, Enumerable.From({"apple", "banana", "peach", "kiwi"}):Except({"BANANA", "peach"}, ignoreCaseComparer):ToArray());
    end);
end);

describe("Enumerable:First", function()
    it("returns the first element of a sequence", function()
        assert.equal(1, Enumerable.From({1, 2, 3, 4}):First());
        local element = {};
        assert.equal(element, Enumerable.From({element}):First());
        assert.equal(1, Enumerable.From({a = 1, b = 2, c = 3, d = 4}):First());
    end);

    it("returns the first element in a sequence that satisfies a specified condition", function()
        local startsWithB = function(fruit) return fruit and fruit:sub(1, 1) == "b"; end
        assert.equal("banana", Enumerable.From({"apple", "banana", "berry", "peach", "kiwi"}):First(startsWithB));
    end);

    it("raises an exception when the source sequence is empty", function()
        assert.has_error(function() Enumerable.From({}):First(); end, "The source sequence is empty.");
        local startsWithB = function(fruit) return fruit and fruit:sub(1, 1) == "b"; end
        assert.has_error(function() Enumerable.From({}):First(startsWithB); end, "The source sequence is empty.");
    end);

    it("raises an exception when no element satisfies the condition in predicate", function()
        local startsWithZ = function(fruit) return fruit and fruit:sub(1, 1) == "z"; end
        assert.has_error(function() Enumerable.From({"apple", "banana", "berry", "peach", "kiwi"}):First(startsWithZ); end, "No element satisfy the condition.");
    end);
end);

describe("Enumerable:FirstOrDefault", function()
    it("returns the first element of a sequence", function()
        assert.equal(1, Enumerable.From({1, 2, 3, 4}):FirstOrDefault(nil));
        local element = {};
        assert.equal(element, Enumerable.From({element}):FirstOrDefault("default"));
        assert.equal(1, Enumerable.From({a = 1, b = 2, c = 3, d = 4}):FirstOrDefault("default"));
    end);

    it("returns the first element in a sequence that satisfies a specified condition", function()
        local startsWithB = function(fruit) return fruit and fruit:sub(1, 1) == "b"; end
        assert.equal("banana", Enumerable.From({"apple", "banana", "berry", "peach", "kiwi"}):FirstOrDefault("default", startsWithB));
    end);

    it("returns the default value when the source sequence is empty", function()
        assert.equal("default", Enumerable.From({}):FirstOrDefault("default"));
        assert.equal(nil, Enumerable.From({}):FirstOrDefault());
        local startsWithB = function(fruit) return fruit and fruit:sub(1, 1) == "b"; end
        assert.equal("default", Enumerable.From({}):FirstOrDefault("default", startsWithB));
    end);

    it("returns the default value when no element satisfies the condition in predicate", function()
        local startsWithZ = function(fruit) return fruit and fruit:sub(1, 1) == "z"; end
        assert.equal("default", Enumerable.From({"apple", "banana", "berry", "peach", "kiwi"}):FirstOrDefault("default", startsWithZ));
    end);
end);

describe("Enumerable.From", function()
    it("creates an enumerable using the given array as source", function()
        local enumerable = Enumerable.From({1, 2, 3, 4});
        assert.same({1, 2, 3, 4}, enumerable:ToArray());
    end);

    it("creates an enumerable using the given enumerable as source", function()
        local enumerable = Enumerable.From(List.New({1, 2, 3, 4}));
        assert.same({1, 2, 3, 4}, enumerable:ToArray());
    end);

    it("creates an enumerable that can be used with operations", function()
        local enumerable = Enumerable.From({1, 2, a = 3, b = 4});
        assert.same({2, 4, a = 6, b = 8}, enumerable:Select(function(n) return n * 2; end):ToTable());
    end);
end);

describe("Enumerable:GroupBy", function()
    it("returns a collection of elements where each element  contains a collection of objects and a key", function()
        local pets = {
            { Name = "Barley", Age = 8.3 },
            { Name = "Boots", Age = 4.9 },
            { Name = "Whiskers", Age = 1.5 },
            { Name = "Daisy", Age = 4.3 }
        };

        local groups = Enumerable.From(pets)
            :GroupBy(
                function(pet) return math.floor(pet.Age); end,
                function(pet) return pet; end
            )
            :ToArray();

        assert.equal(3, #groups);

        assert.same({Key = 1, Values = {{ Name = "Whiskers", Age = 1.5 }}}, groups[1]);
        assert.same({Key = 4, Values = {{ Name = "Boots", Age = 4.9 }, { Name = "Daisy", Age = 4.3 }}}, groups[2]);
        assert.same({Key = 8, Values = {{ Name = "Barley", Age = 8.3 }}}, groups[3]);
    end);

    it("returns a collection of elements where each element represents a projection over a group and its key", function()
        local pets = {
            { Name = "Barley", Age = 8.3 },
            { Name = "Boots", Age = 4.9 },
            { Name = "Whiskers", Age = 1.5 },
            { Name = "Daisy", Age = 4.3 }
        };

        local groups = Enumerable.From(pets)
            :GroupBy(
                function(pet) return math.floor(pet.Age); end,
                function(pet) return pet.Age; end,
                function(baseAge, allAges) return {Key = baseAge, Count = #allAges, Min = math.min(unpack(allAges)), Max = math.max(unpack(allAges))} end
            )
            :ToArray();

        assert.equal(3, #groups);

        assert.same({Key = 1, Count = 1, Min = 1.5, Max = 1.5}, groups[1]);
        assert.same({Key = 4, Count = 2, Min = 4.3, Max = 4.9}, groups[2]);
        assert.same({Key = 8, Count = 1, Min = 8.3, Max = 8.3}, groups[3]);
    end);

    it("returns a collection of elements where each element represents a projection over a group and its key using a custom key comparer", function()
        local pets = {
            { Name = "Barley", Age = 8.3 },
            { Name = "Boots", Age = 4.9 },
            { Name = "Whiskers", Age = 1.5 },
            { Name = "Daisy", Age = 4.3 }
        };

        local groups = Enumerable.From(pets)
            :GroupBy(
                function(pet) return pet.Age; end,
                function(pet) return pet.Age; end,
                function(baseAge, allAges) return {Key = math.floor(baseAge), Count = #allAges, Min = math.min(unpack(allAges)), Max = math.max(unpack(allAges))} end,
                function(age1, age2) return math.floor(age1) == math.floor(age2); end
            )
            :ToArray();

        assert.equal(3, #groups);

        assert.same({Key = 4, Count = 2, Min = 4.3, Max = 4.9}, groups[1]);
        assert.same({Key = 8, Count = 1, Min = 8.3, Max = 8.3}, groups[2]);
        assert.same({Key = 1, Count = 1, Min = 1.5, Max = 1.5}, groups[3]);
    end);
end);

describe("Enumerable:GroupJoin", function()
    it("joins two sequences", function()
        local nopet = { Name = "Pet, Without" };
        local magnus = { Name = "Hedlund, Magnus" };
        local terry = { Name = "Adams, Terry" };
        local charlotte = { Name = "Weiss, Charlotte" };

        local barley = { Name = "Barley", Owner = terry };
        local boots = { Name = "Boots", Owner = terry };
        local whiskers = { Name = "Whiskers", Owner = charlotte };
        local daisy = { Name = "Daisy", Owner = magnus };

        local people = { nopet, magnus, terry, charlotte };
        local pets = { barley, boots, whiskers, daisy };

        local results = Enumerable.From(people)
            :GroupJoin(
                pets,
                function(person) return person; end,
                function(pet) return pet.Owner; end,
                function(person, pets) return { OwnerName = person.Name, Pets = pets }; end
            )
            :ToArray();

        assert.equal(4, #results);

        assert.same({OwnerName = "Pet, Without", Pets = {}}, results[1]);
        assert.same({OwnerName = "Hedlund, Magnus", Pets = {daisy}}, results[2]);
        assert.same({OwnerName = "Adams, Terry", Pets = {barley, boots}}, results[3]);
        assert.same({OwnerName = "Weiss, Charlotte", Pets = {whiskers}}, results[4]);
    end);

    it("joins two enumerables", function()
        local nopet = { Name = "Pet, Without" };
        local magnus = { Name = "Hedlund, Magnus" };
        local terry = { Name = "Adams, Terry" };
        local charlotte = { Name = "Weiss, Charlotte" };

        local barley = { Name = "Barley", Owner = terry };
        local boots = { Name = "Boots", Owner = terry };
        local whiskers = { Name = "Whiskers", Owner = charlotte };
        local daisy = { Name = "Daisy", Owner = magnus };

        local people = { nopet, magnus, terry, charlotte };
        local pets = { barley, boots, whiskers, daisy };

        local results = Enumerable.From(people)
            :GroupJoin(
                Enumerable.From(pets),
                function(person) return person; end,
                function(pet) return pet.Owner; end,
                function(person, pets) return { OwnerName = person.Name, Pets = pets }; end
            )
            :ToArray();

        assert.equal(4, #results);

        assert.same({OwnerName = "Pet, Without", Pets = {}}, results[1]);
        assert.same({OwnerName = "Hedlund, Magnus", Pets = {daisy}}, results[2]);
        assert.same({OwnerName = "Adams, Terry", Pets = {barley, boots}}, results[3]);
        assert.same({OwnerName = "Weiss, Charlotte", Pets = {whiskers}}, results[4]);
    end);

    it("joins two sequences using a key comparer", function()
        local magnus = { Name = "Hedlund, Magnus" };
        local terry1 = { Name = "Adams, Terry" };
        local terry2 = { Name = "Adams, Terry" };
        local charlotte = { Name = "Weiss, Charlotte" };

        local barley = { Name = "Barley", Owner = terry1 };
        local boots = { Name = "Boots", Owner = terry2 };
        local whiskers = { Name = "Whiskers", Owner = charlotte };
        local daisy = { Name = "Daisy", Owner = magnus };

        local people = { magnus, terry1, charlotte };
        local pets = { barley, boots, whiskers, daisy };

        local results = Enumerable.From(people)
            :GroupJoin(
                pets,
                function(person) return person; end,
                function(pet) return pet.Owner; end,
                function(person, pets) return { OwnerName = person.Name, Pets = pets }; end,
                function(outerKey, innerKey) return outerKey.Name == innerKey.Name; end
            )
            :ToArray();

        assert.equal(3, #results);

        assert.same({OwnerName = "Hedlund, Magnus", Pets = {daisy}}, results[1]);
        assert.same({OwnerName = "Adams, Terry", Pets = {barley, boots}}, results[2]);
        assert.same({OwnerName = "Weiss, Charlotte", Pets = {whiskers}}, results[3]);
    end);
end);

describe("Enumerable:Intersect", function()
    it("returns the elements that appear in each of two sequences", function()
        local id1 = { 44, 26, 92, 30, 71, 38 };
        local id2 = { 39, 59, 83, 47, 26, 4, 30 };
        assert.same({26, 30}, Enumerable.From(id1):Intersect(id2):ToArray());
    end);

    it("returns the elements that appear in each of two enumerable", function()
        local id1 = { 44, 26, 92, 30, 71, 38 };
        local id2 = { 39, 59, 83, 47, 26, 4, 30 };
        assert.same({26, 30}, Enumerable.From(id1):Intersect(Enumerable.From(id2)):ToArray());
    end);

    it("returns the elements that appear in each of two sequences according to the comparer", function()
        local store1 = { { Name = "apple", Code = 9 }, { Name = "orange", Code = 4 } };
        local store2 = { { Name = "Apple", Code = 9 }, { Name = "lemon", Code = 12 } };
        local isSameProduct = function(product1, product2) return product1.Code == product2.Code; end;
        assert.same({{ Name = "apple", Code = 9 }}, Enumerable.From(store1):Intersect(store2, isSameProduct):ToArray());
    end);
end);

describe("Enumerable:IsEnumerable", function()
    it("returns true if the given object is an Enumerable", function()
        assert.is_true(Enumerable.IsEnumerable(Enumerable.From({})));
        assert.is_true(Enumerable.IsEnumerable(List.New()));
        assert.is_true(Enumerable.IsEnumerable(Enumerable.Empty():ToHashSet()));
    end);

    it("returns false if the given object is not an Enumerable", function()
        assert.is_false(Enumerable.IsEnumerable({}));
        assert.is_false(Enumerable.IsEnumerable(1));
        assert.is_false(Enumerable.IsEnumerable(nil));
        assert.is_false(Enumerable.IsEnumerable(function() end));
        assert.is_false(Enumerable.IsEnumerable("a"));
        assert.is_false(Enumerable.IsEnumerable(true));
    end);

    it("returns true if the given object is not an Enumerable but implements the GetEnumerator function (unfortunately)", function()
        -- Unfortunately, this will return true...
        assert.is_true(Enumerable.IsEnumerable({GetEnumerator = Enumerable.GetEnumerator}));
    end);

    it("returns false if the given object is not an Enumerable that implements a wrong GetEnumerator", function()
        -- ... but this will not
        assert.is_false(Enumerable.IsEnumerable({GetEnumerator = function() end}));
    end);
end);

describe("Enumerable:Join", function()
    it("joins two sequences", function()
        local nopet = { Name = "Pet, Without" };
        local magnus = { Name = "Hedlund, Magnus" };
        local terry = { Name = "Adams, Terry" };
        local charlotte = { Name = "Weiss, Charlotte" };

        local barley = { Name = "Barley", Owner = terry };
        local boots = { Name = "Boots", Owner = terry };
        local whiskers = { Name = "Whiskers", Owner = charlotte };
        local daisy = { Name = "Daisy", Owner = magnus };

        local people = { nopet, magnus, terry, charlotte };
        local pets = { barley, boots, whiskers, daisy };

        local results = Enumerable.From(people)
            :Join(
                pets,
                function(person) return person; end,
                function(pet) return pet.Owner; end,
                function(person, pet) return { OwnerName = person.Name, PetName = pet.Name }; end
            )
            :ToArray();

        assert.equal(4, #results);

        assert.same({OwnerName = "Hedlund, Magnus", PetName = "Daisy"}, results[1]);
        assert.same({OwnerName = "Adams, Terry", PetName = "Barley"}, results[2]);
        assert.same({OwnerName = "Adams, Terry", PetName = "Boots"}, results[3]);
        assert.same({OwnerName = "Weiss, Charlotte", PetName = "Whiskers"}, results[4]);
    end);

    it("joins two enumerables", function()
        local nopet = { Name = "Pet, Without" };
        local magnus = { Name = "Hedlund, Magnus" };
        local terry = { Name = "Adams, Terry" };
        local charlotte = { Name = "Weiss, Charlotte" };

        local barley = { Name = "Barley", Owner = terry };
        local boots = { Name = "Boots", Owner = terry };
        local whiskers = { Name = "Whiskers", Owner = charlotte };
        local daisy = { Name = "Daisy", Owner = magnus };

        local people = { nopet, magnus, terry, charlotte };
        local pets = { barley, boots, whiskers, daisy };

        local results = Enumerable.From(people)
            :Join(
                Enumerable.From(pets),
                function(person) return person; end,
                function(pet) return pet.Owner; end,
                function(person, pet) return { OwnerName = person.Name, PetName = pet.Name }; end
            )
            :ToArray();

        assert.equal(4, #results);

        assert.same({OwnerName = "Hedlund, Magnus", PetName = "Daisy"}, results[1]);
        assert.same({OwnerName = "Adams, Terry", PetName = "Barley"}, results[2]);
        assert.same({OwnerName = "Adams, Terry", PetName = "Boots"}, results[3]);
        assert.same({OwnerName = "Weiss, Charlotte", PetName = "Whiskers"}, results[4]);
    end);

    it("joins two sequences using a key comparer", function()
        local magnus = { Name = "Hedlund, Magnus" };
        local terry1 = { Name = "Adams, Terry" };
        local terry2 = { Name = "Adams, Terry" };
        local charlotte = { Name = "Weiss, Charlotte" };

        local barley = { Name = "Barley", Owner = terry1 };
        local boots = { Name = "Boots", Owner = terry2 };
        local whiskers = { Name = "Whiskers", Owner = charlotte };
        local daisy = { Name = "Daisy", Owner = magnus };

        local people = { magnus, terry1, charlotte };
        local pets = { barley, boots, whiskers, daisy };

        local results = Enumerable.From(people)
            :Join(
                pets,
                function(person) return person; end,
                function(pet) return pet.Owner; end,
                function(person, pet) return { OwnerName = person.Name, PetName = pet.Name }; end,
                function(outerKey, innerKey) return outerKey.Name == innerKey.Name; end
            )
            :ToArray();

        assert.equal(4, #results);

        assert.same({OwnerName = "Hedlund, Magnus", PetName = "Daisy"}, results[1]);
        assert.same({OwnerName = "Adams, Terry", PetName = "Barley"}, results[2]);
        assert.same({OwnerName = "Adams, Terry", PetName = "Boots"}, results[3]);
        assert.same({OwnerName = "Weiss, Charlotte", PetName = "Whiskers"}, results[4]);
    end);
end);

describe("Enumerable:Last", function()
    it("returns the last element of a sequence", function()
        assert.equal(4, Enumerable.From({1, 2, 3, 4}):Last());
        local element = {};
        assert.equal(element, Enumerable.From({element}):Last());
    end);

    it("returns the last element in a sequence that satisfies a specified condition", function()
        local startsWithB = function(fruit) return fruit and fruit:sub(1, 1) == "b"; end
        assert.equal("berry", Enumerable.From({"apple", "banana", "berry", "peach", "kiwi"}):Last(startsWithB));
    end);

    it("raises an exception when the source sequence is empty", function()
        assert.has_error(function() Enumerable.From({}):Last(); end, "The source sequence is empty.");
        local startsWithB = function(fruit) return fruit and fruit:sub(1, 1) == "b"; end
        assert.has_error(function() Enumerable.From({}):Last(startsWithB); end, "The source sequence is empty.");
    end);

    it("raises an exception when no element satisfies the condition in predicate", function()
        local startsWithZ = function(fruit) return fruit and fruit:sub(1, 1) == "z"; end
        assert.has_error(
            function() Enumerable.From({"apple", "banana", "berry", "peach", "kiwi"}):Last(startsWithZ); end,
            "No element satisfy the condition."
        );
    end);
end);

describe("Enumerable:LastOrDefault", function()
    it("returns the last element of a sequence", function()
        assert.equal(4, Enumerable.From({1, 2, 3, 4}):LastOrDefault(nil));
        local element = {};
        assert.equal(element, Enumerable.From({element}):LastOrDefault("default"));
    end);

    it("returns the last element in a sequence that satisfies a specified condition", function()
        local startsWithB = function(fruit) return fruit and fruit:sub(1, 1) == "b"; end
        assert.equal("berry", Enumerable.From({"apple", "banana", "berry", "peach", "kiwi"}):LastOrDefault("default", startsWithB));
    end);

    it("returns the default value when the source sequence is empty", function()
        assert.equal("default", Enumerable.From({}):LastOrDefault("default"));
        assert.equal(nil, Enumerable.From({}):LastOrDefault());
        local startsWithB = function(fruit) return fruit and fruit:sub(1, 1) == "b"; end
        assert.equal("default", Enumerable.From({}):LastOrDefault("default", startsWithB));
    end);

    it("returns the default value when no element satisfies the condition in predicate", function()
        local startsWithZ = function(fruit) return fruit and fruit:sub(1, 1) == "z"; end
        assert.equal("default", Enumerable.From({"apple", "banana", "berry", "peach", "kiwi"}):LastOrDefault("default", startsWithZ));
    end);
end);

describe("Enumerable:Max", function()
    it("returns the maximum value in a sequence of values", function()
        local numbers = { 466855135, 4294967296, 81125 };
        assert.equal(4294967296, Enumerable.From(numbers):Max());
    end);

    it("returns the maximum value in a sequence of values after applying a transform", function()
        local pets = { { Name = "Boots", Age = 4 }, { Name = "Barley", Age = 8 }, { Name = "Whiskers", Age = 1 } };
        assert.equal(14, Enumerable.From(pets):Max(function(pet) return pet.Age + pet.Name:len(); end));
    end);

    it("raises an error when the sequence is empty", function()
        assert.has_error(function() Enumerable.From({}):Max(); end, "Sequence contains no elements");
    end);
end);

describe("Enumerable:Min", function()
    it("returns the minimum value in a sequence of values", function()
        local numbers = { 466855135, 4294967296, 81125 };
        assert.equal(81125, Enumerable.From(numbers):Min());
    end);

    it("returns the minimum value in a sequence of values after applying a transform", function()
        local pets = { { Name = "Boots", Age = 4 }, { Name = "Barley", Age = 8 }, { Name = "Whiskers", Age = 1 } };
        assert.equal(9, Enumerable.From(pets):Min(function(pet) return pet.Age + pet.Name:len(); end));
    end);

    it("raises an error when the sequence is empty", function()
        assert.has_error(function() Enumerable.From({}):Min(); end, "Sequence contains no elements");
    end);
end);

describe("Enumerable:Prepend", function()
    it("adds an element at the begining of the sequence", function()
        local input = {1, 2, 3, 4, 5};
        assert.is_same({6, 1, 2, 3, 4, 5}, Enumerable.From(input):Prepend(6):ToArray());
    end);

    it("adds an element on an empty sequence", function()
        local input = {};
        assert.is_same({1}, Enumerable.From(input):Prepend(1):ToArray());
    end);
end);

describe("Enumerable.Range", function()
    it("returns an enumerable containing the sequence of integers from start to start+count", function()
        local range = Enumerable.Range(12, 4);
        assert.same({12, 13, 14, 15}, range:ToArray());
        range = Enumerable.Range(55, 1);
        assert.same({55}, range:ToArray());
        range = Enumerable.Range(-5, 10);
        assert.same({-5, -4, -3, -2, -1, 0, 1, 2, 3, 4}, range:ToArray());
    end);

    it("returns an enumerable that can be used with operations", function()
        local range = Enumerable.Range(12, 4);
        assert.same({10, 12, 13, 14, 15}, range:Prepend(10):ToArray());
    end);

    it("returns an empty enumerable when count is 0", function()
        local range = Enumerable.Range(124, 0);
        assert.same({}, range:ToArray());
    end);

    it("raises an errpr when count is less than 0", function()
        assert.has_error(
            function() Enumerable.Range(124, -1); end,
            "count is less than 0."
        );
    end);
end);

describe("Enumerable.Repeat", function()
    it("returns an enumerable that contains one repeated value", function()
        local repeated = Enumerable.Repeat(12, 4);
        assert.same({12, 12, 12, 12}, repeated:ToArray());
        local obj = {};
        repeated = Enumerable.Repeat(obj, 2);
        assert.same({obj, obj}, repeated:ToArray());
        assert.equal(obj, repeated:ToArray()[1]);
        assert.equal(obj, repeated:ToArray()[2]);
        repeated = Enumerable.Repeat("I like programming.", 3);
        assert.same({"I like programming.", "I like programming.", "I like programming."}, repeated:ToArray());
    end);

    it("returns an enumerable that can be used with operations", function()
        local repeated = Enumerable.Repeat("a", 4);
        assert.same({"b", "a", "a", "a", "a"}, repeated:Prepend("b"):ToArray());
    end);

    it("returns an empty enumerable when count is 0", function()
        local range = Enumerable.Repeat("I like programming.", 0);
        assert.same({}, range:ToArray());
    end);

    it("raises an errpr when count is less than 0", function()
        assert.has_error(
            function() Enumerable.Repeat("I like programming.", -1); end,
            "count is less than 0."
        );
    end);
end);

describe("Enumerable:Reverse", function()
    it("inverts the order of the elements in a sequence", function()
        assert.same({"e", "l", "p", "p", "a"}, Enumerable.From({"a", "p", "p", "l", "e"}):Reverse():ToArray());
    end);
end);

describe("Enumerable:Select", function()
    it("projects each element of a sequence into a new form", function()
        local fruits = { "apple", "banana", "mango", "orange", "passionfruit", "grape" };
        local results = Enumerable.From(fruits):Select(function(item, index) return {index = index, str = item:sub(1, index - 1)}; end):ToArray();
        assert.same({{ index = 1, str = "" }, { index = 2, str = "b" }, { index = 3, str = "ma" }, { index = 4, str = "ora" }, { index = 5, str = "pass" }, { index = 6, str = "grape" }}, results);
    end);
end);

describe("Enumerable:SelectMany", function()
    it("projects each element of a sequence and flattens the resulting sequences into one sequence", function()
        local petOwners = {
            { Name = "Higa", Pets = { "Scruffy", "Sam" } },
            { Name = "Ashkenazi", Pets = { "Walker", "Sugar" } },
            { Name = "Price", Pets = { "Scratches", "Diesel" } },
            { Name = "Hines", Pets = { "Dusty" } }
        };

        local results = Enumerable.From(petOwners):SelectMany(
            function(petOwner) return petOwner.Pets; end,
            function(petOwner, petName) return { Owner = petOwner.Name, Pet = petName }; end
        ):ToArray();

        assert.same(
            {
                { Owner = "Higa", Pet = "Scruffy" },
                { Owner = "Higa", Pet = "Sam" },
                { Owner = "Ashkenazi", Pet = "Walker" },
                { Owner = "Ashkenazi", Pet = "Sugar" },
                { Owner = "Price", Pet = "Scratches" },
                { Owner = "Price", Pet = "Diesel" },
                { Owner = "Hines", Pet = "Dusty" }
            },
            results
        );
    end);
end);

describe("Enumerable:SequenceEqual", function()
    it("is true when both sequences are equal", function()
        local pet1 = { Name = "Turbo", Age = 2 };
        local pet2 = { Name = "Peanut", Age = 8 };

        local pets1 = { pet1, pet2 };
        local pets2 = { pet1, pet2 };

        assert.is_true(Enumerable.From(pets1):SequenceEqual(pets2));
    end);

    it("is true when both enumerables are equal", function()
        local pet1 = { Name = "Turbo", Age = 2 };
        local pet2 = { Name = "Peanut", Age = 8 };

        local pets1 = { pet1, pet2 };
        local pets2 = { pet1, pet2 };

        assert.is_true(Enumerable.From(pets1):SequenceEqual(Enumerable.From(pets2)));
    end);

    it("is false when both sequences are not equal", function()
        local pet1 = { Name = "Turbo", Age = 2 };
        local pet2 = { Name = "Peanut", Age = 8 };

        local pets1 = { pet1, pet2 };
        local pets2 = { pet1, { Name = "Peanut", Age = 8 } };

        assert.is_false(Enumerable.From(pets1):SequenceEqual(pets2));
    end);

    it("is false when both sequences have the same elements but not with the same key", function()
        local list1 = { 1, 2, 3 };
        local list2 = { 1, 2, a = 3 };
        assert.is_false(Enumerable.From(list1):SequenceEqual(list2));
    end);

    it("is true when both sequences are equal according to the given comparer", function()
        local list1 = { 1.1, 2.2, 3.3 };
        local list2 = { 1, 2, 3 };
        assert.is_true(Enumerable.From(list1):SequenceEqual(list2, function(i1, i2) return math.floor(i1) == math.floor(i2); end));
    end);

    it("is false when both sequences are not equal according to the given comparer", function()
        local list1 = { 1.1, 2.2, 3.3 };
        local list2 = { 1, 2, 3 };
        assert.is_false(Enumerable.From(list1):SequenceEqual(list2, function(i1, i2) return math.ceil(i1) == math.ceil(i2); end));
    end);
end);

describe("Enumerable:Single", function()
    it("returns the single element of a sequence", function()
        assert.equal(1, Enumerable.From({1}):Single());
        local element = {};
        assert.equal(element, Enumerable.From({element}):Single());
        assert.equal(1, Enumerable.From({a = 1}):Single());
    end);

    it("returns the single element in a sequence that satisfies a specified condition", function()
        local startsWithP = function(fruit) return fruit and fruit:sub(1, 1) == "p"; end
        assert.equal("peach", Enumerable.From({"apple", "banana", "berry", "peach", "kiwi"}):Single(startsWithP));
    end);

    it("raises an exception when the source sequence is empty", function()
        assert.has_error(function() Enumerable.From({}):Single(); end, "The source sequence is empty.");
        local startsWithB = function(fruit) return fruit and fruit:sub(1, 1) == "b"; end
        assert.has_error(function() Enumerable.From({}):Single(startsWithB); end, "The source sequence is empty.");
    end);

    it("raises an exception when no element satisfies the condition in predicate", function()
        local startsWithZ = function(fruit) return fruit and fruit:sub(1, 1) == "z"; end
        assert.has_error(
            function() Enumerable.From({"apple", "banana", "berry", "peach", "kiwi"}):Single(startsWithZ); end,
            "No element satisfy the condition."
        );
    end);

    it("raises an exception when the sequence contain more than one element", function()
        assert.has_error(
            function() Enumerable.From({"apple", "banana", "berry", "peach", "kiwi"}):Single(); end,
            "The sequence contain more than one element."
        );
    end);

    it("raises an exception when more than one element satisfies the condition in predicate", function()
        local startsWithB = function(fruit) return fruit and fruit:sub(1, 1) == "b"; end
        assert.has_error(
            function() Enumerable.From({"apple", "banana", "berry", "peach", "kiwi"}):Single(startsWithB); end,
            "More than one element satisfies the condition in predicate."
        );
    end);
end);

describe("Enumerable:SingleOrDefault", function()
    it("returns the single element of a sequence", function()
        assert.equal(1, Enumerable.From({1}):SingleOrDefault("default"));
        local element = {};
        assert.equal(element, Enumerable.From({element}):SingleOrDefault());
        assert.equal(1, Enumerable.From({a = 1}):SingleOrDefault());
    end);

    it("returns the single element in a sequence that satisfies a specified condition", function()
        local startsWithP = function(fruit) return fruit and fruit:sub(1, 1) == "p"; end
        assert.equal("peach", Enumerable.From({"apple", "banana", "berry", "peach", "kiwi"}):SingleOrDefault("default", startsWithP));
    end);

    it("returns the default value when the source sequence is empty", function()
        assert.equal(nil, Enumerable.From({}):SingleOrDefault());
        local startsWithB = function(fruit) return fruit and fruit:sub(1, 1) == "b"; end
        assert.equal("default", Enumerable.From({}):SingleOrDefault("default", startsWithB));
    end);

    it("returns the default value when no element satisfies the condition in predicate", function()
        local startsWithZ = function(fruit) return fruit and fruit:sub(1, 1) == "z"; end
        assert.equal("default", Enumerable.From({"apple", "banana", "berry", "peach", "kiwi"}):SingleOrDefault("default", startsWithZ));
    end);

    it("raises an exception when the sequence contain more than one element", function()
        assert.has_error(
            function() Enumerable.From({"apple", "banana", "berry", "peach", "kiwi"}):SingleOrDefault("default"); end,
            "The sequence contain more than one element."
        );
    end);

    it("raises an exception when more than one element satisfies the condition in predicate", function()
        local startsWithB = function(fruit) return fruit and fruit:sub(1, 1) == "b"; end
        assert.has_error(
            function() Enumerable.From({"apple", "banana", "berry", "peach", "kiwi"}):SingleOrDefault(nil, startsWithB); end,
            "More than one element satisfies the condition in predicate."
        );
    end);
end);

describe("Enumerable:Skip", function()
    it("bypasses a specified number of elements in a sequence and then returns the remaining elements", function()
        local grades = { 59, 82, 70, 56, 92, 98, 85 };
        assert.same({56, 92, 98, 85}, Enumerable.From(grades):Skip(3):ToArray());
        assert.same({85}, Enumerable.From(grades):Skip(6):ToArray());
    end);

    it("returns an empty result when the skip count is greater or equal to the number of elements", function()
        local grades = { 59, 82, 70, 56, 92, 98, 85 };
        assert.same({}, Enumerable.From(grades):Skip(7):ToArray());
        assert.same({}, Enumerable.From(grades):Skip(10):ToArray());
    end);

    it("returns the same sequence when the skip count is 0 or less", function()
        local grades = { 59, 82, 70, 56, 92, 98, 85 };
        assert.same(grades, Enumerable.From(grades):Skip(0):ToArray());
        assert.same(grades, Enumerable.From(grades):Skip(-1):ToArray());
    end);
end);

describe("Enumerable:SkipWhile", function()
    it("bypasses elements in a sequence as long as a specified condition is true and then returns the remaining elements", function()
        local grades = { 56, 59, 70, 82, 85, 92, 98 };
        assert.same({82, 85, 92, 98}, Enumerable.From(grades):SkipWhile(function(n) return n >= 80; end):ToArray());
    end);

    it("returns an empty result when the skip predicate is never satisfied", function()
        local grades = { 56, 59, 70, 82, 85, 92, 98 };
        assert.same({}, Enumerable.From(grades):SkipWhile(function(n) return n >= 100; end):ToArray());
    end);

    it("returns the same sequence when the skip predicate is always satisfied", function()
        local grades = { 56, 59, 70, 82, 85, 92, 98 };
        assert.same(grades, Enumerable.From(grades):SkipWhile(function(n) return n >= 0; end):ToArray());
    end);
end);

describe("Enumerable:Sum", function()
    it("computes the sum of a sequence of numeric values", function()
        local points = { nil, 0, 92.83, nil, 100.0, 37.46, 81.1 };
        assert.equal(311.39, Enumerable.From(points):Sum());
    end);

    it("computes the sum of a sequence of numeric values after applying the transform", function()
        local packages = {
            { Company = "Coho Vineyard", Weight = 25.2 },
            { Company = "Lucerne Publishing", Weight = 18.7 },
            { Company = "Wingtip Toys", Weight = 6.0 },
            { Company = "Adventure Works", Weight = 33.8 }
        };
        assert.equal(82, Enumerable.From(packages):Sum(function(package) return math.floor(package.Weight); end));
    end);
end);

describe("Enumerable:Take", function()
    it("returns a specified number of contiguous elements from the start of a sequence", function()
        local grades = { 59, 82, 70, 56, 92, 98, 85 };
        assert.same({59, 82, 70}, Enumerable.From(grades):Take(3):ToArray());
        assert.same({59, 82, 70, 56, 92, 98}, Enumerable.From(grades):Take(6):ToArray());
    end);

    it("returns an empty result when the take count is 0 or less", function()
        local grades = { 59, 82, 70, 56, 92, 98, 85 };
        assert.same({}, Enumerable.From(grades):Take(0):ToArray());
        assert.same({}, Enumerable.From(grades):Take(-1):ToArray());
    end);

    it("returns the same sequence when the skip count is greater or equal to the number of elements", function()
        local grades = { 59, 82, 70, 56, 92, 98, 85 };
        assert.same(grades, Enumerable.From(grades):Take(7):ToArray());
        assert.same(grades, Enumerable.From(grades):Take(10):ToArray());
    end);
end);

describe("Enumerable:TakeWhile", function()
    it("returns elements from a sequence as long as a specified condition is true, and then skips the remaining elements", function()
        local grades = { 56, 59, 70, 82, 85, 92, 98 };
        assert.same({56, 59, 70}, Enumerable.From(grades):TakeWhile(function(n) return n <= 80; end):ToArray());
    end);

    it("returns an empty result when the take predicate is never satisfied", function()
        local grades = { 56, 59, 70, 82, 85, 92, 98 };
        assert.same({}, Enumerable.From(grades):TakeWhile(function(n) return n >= 100; end):ToArray());
    end);

    it("returns the same sequence when the take predicate is always satisfied", function()
        local grades = { 56, 59, 70, 82, 85, 92, 98 };
        assert.same(grades, Enumerable.From(grades):TakeWhile(function(n) return n >= 0; end):ToArray());
    end);
end);

describe("Enumerable:ToArray", function()
    it("returns the source list without modification when no operations have been applied", function()
        local input = {1, 2, 3, nil, "a", "b", "c", {}, true, false};

        local list = Enumerable.From(input);
        local result = list:ToArray();

        assert.not_equal(input, result);
        assert.same({1, 2, 3, --[[nil,]] "a", "b", "c", {}, true, false}, result);
    end);

    it("ignores the keys from the input table", function()
        local input = {4, a = 1, b = 2, c = 3};
        local array = Enumerable.From(input):ToArray();

        assert.equal(4, array[1]);
        assert.is_true(Enumerable.From(array):Contains(1));
        assert.is_true(Enumerable.From(array):Contains(2));
        assert.is_true(Enumerable.From(array):Contains(3));
        assert.is_nil(array.a);
        assert.is_nil(array.b);
        assert.is_nil(array.c);
    end);
end);

describe("Enumerable:ToHashSet", function()
    it("returns an instance of HashSet", function()
        local input = {1, 2, 3, "a", "b", "c", {}, true, false};
        local hashSet = Enumerable.From(input):ToHashSet();
        assert.same(Linq.HashSet.New, hashSet.New);
        assert.not_same(Linq.Enumerable.From, hashSet.New);
    end);

    it("adds only values in the set that are not equal", function()
        local empty = {};
        local input = {1, 1, 1, 2, "a", "a", "a", "b", empty, empty, empty, {}, true, true, false, false};
        local hashSet = Enumerable.From(input):ToHashSet();
        assert.equal(8, hashSet.Length);
    end);

    it("adds only values in the set that are not equal according to the given comparer", function()
        local empty = {};
        local input = {1, 2, 3, "a", "b", "c", empty, {}, {}, true, false};
        local sameTypeComparer = function(item1, item2) return type(item1) == type(item2); end;
        local hashSet = Enumerable.From(input):ToHashSet(sameTypeComparer);
        assert.equal(4, hashSet.Length);
    end);
end);

describe("Enumerable:ToList", function()
    it("returns an instance of List", function()
        local input = {1, 2, 3, nil, "a", "b", "c", {}, true, false};
        local list = Enumerable.From(input):ToList();
        assert.same(Linq.List.New, list.New);
        assert.not_same(Linq.HashSet.New, list.New);
    end);
end);

-- describe("Enumerable:ToDictionary", function()
--     it("", function()
--         local packages = {
--             { Company = "Coho Vineyard", Weight = 25.2, TrackingNumber = 89453312 },
--             { Company = "Lucerne Publishing", Weight = 18.7, TrackingNumber = 89112755 },
--             { Company = "Wingtip Toys", Weight = 6.0, TrackingNumber = 299456122 },
--             { Company = "Adventure Works", Weight = 33.8, TrackingNumber = 4665518773 }
--         };

--         local dictionary = Enumerable.From(packages):ToDictionary(function(item) return item.TrackingNumber; end);
--     end);

--     it("raises an error when the same key is added twice", function()
--         local packages = {
--             { Company = "Coho Vineyard", Weight = 25.2, TrackingNumber = 89453312 },
--             { Company = "Lucerne Publishing", Weight = 18.7, TrackingNumber = 89112755 },
--             { Company = "Wingtip Toys", Weight = 6.0, TrackingNumber = 299456122 },
--             { Company = "Wingtip Toys2", Weight = 6.0, TrackingNumber = 299456122 },
--             { Company = "Adventure Works", Weight = 33.8, TrackingNumber = 4665518773 }
--         };

--         assert.has_error(
--             function() Enumerable.From(packages):ToDictionary(function(item) return item.TrackingNumber; end); end,
--             "An item with the same key has already been added."
--         );
--     end);
-- end);

describe("Enumerable:ToTable", function()
    it("keeps the same keys from the input table", function()
        local input = {4, a = 1, b = 2, c = 3};
        local table = Enumerable.From(input):ToTable();

        assert.equal(4, table[1]);
        assert.equal(1, table.a);
        assert.equal(2, table.b);
        assert.equal(3, table.c);
    end);

    it("keeps the same keys from the input table after applying full-streaming operations", function()
        local input = {4, a = 1, b = 2, c = 3};
        local table = Enumerable.From(input)
            :Where(function(n) return n >= 2; end)
            :Select(function(n) return n * 2; end)
            :ToTable();

        assert.equal(8, table[1]);
        assert.is_nil(table.a);
        assert.equal(4, table.b);
        assert.equal(6, table.c);
    end);

    it("adds an element with Append by incrementing the max index by 1", function()
        local input = {4, a = 1, b = 2, c = 3, [6] = 5};
        local table = Enumerable.From(input)
            :Append("test")
            :ToTable();

        assert.equal(4, table[1]);
        assert.equal(1, table.a);
        assert.equal(2, table.b);
        assert.equal(3, table.c);
        assert.equal(5, table[6]);
        assert.equal("test", table[7]);
    end);

    it("keeps the keys from the input table but not the keys of the concatenated table", function()
        local input = {4, a = 1, b = 2, c = 3, [6] = 5};
        local table = Enumerable.From(input)
            :Concat({"test", a = 1})
            :ToTable();

        assert.equal(4, table[1]);
        assert.equal(1, table.a);
        assert.equal(2, table.b);
        assert.equal(3, table.c);
        assert.equal(5, table[6]);
        assert.equal("test", table[7]);
        assert.equal(1, table[8]);
    end);
end);

describe("Enumerable:Where", function()
    it("filters out the elements according to the predicate", function()
        local input = {1, 2, 3, 4, 5};

        local result = Enumerable.From(input):Where(function(i) return i >= 3; end):ToArray();

        assert.not_equal(input, result);
        assert.same({3, 4, 5}, result);
    end);
end);

describe("Enumerable:Union", function()
    it("produces the set union of two sequences", function()
        local ints1 = { 5, 3, 9, 7, 5, 9, 3, 7 };
        local ints2 = { 8, 3, 6, 4, 4, 9, 1, 0 };
        assert.same({5, 3, 9, 7, 8, 6, 4, 1, 0}, Enumerable.From(ints1):Union(ints2):ToArray());
    end);

    it("produces the set union of two enumerables", function()
        local ints1 = { 5, 3, 9, 7, 5, 9, 3, 7 };
        local ints2 = { 8, 3, 6, 4, 4, 9, 1, 0 };
        assert.same({5, 3, 9, 7, 8, 6, 4, 1, 0}, Enumerable.From(ints1):Union(Enumerable.From(ints2)):ToArray());
    end);

    it("produces the set union of two sequences according to the given comparer", function()
        local store1 = { { Name = "apple", Code = 9 }, { Name = "orange", Code = 4 } };
        local store2 = { { Name = "apple", Code = 9 }, { Name = "lemon", Code = 12 }, { Name = "peach", Code = 4 } };
        local function isSameProduct(product1, product2) return product1.Code == product2.Code; end
        assert.same({ store1[1], store1[2], store2[2] }, Enumerable.From(store1):Union(store2, isSameProduct):ToArray());
    end);
end);

describe("Enumerable:Zip", function()
    it("produces a sequence of tuples with elements from the two specified sequences", function()
        local numbers = { 1, 2, 3 };
        local words = { "one", "two", "three" };
        assert.same({{1, "one"}, {2, "two"}, {3, "three"}} , Enumerable.From(numbers):Zip(words):ToArray());
    end);

    it("produces a sequence of tuples with elements from the two specified enumerables", function()
        local numbers = { 1, 2, 3 };
        local words = { "one", "two", "three" };
        assert.same({{1, "one"}, {2, "two"}, {3, "three"}} , Enumerable.From(numbers):Zip(Enumerable.From(words)):ToArray());
    end);

    it("applies the specified function to the corresponding elements of the two sequences", function()
        local numbers = { 1, 2, 3 };
        local words = { "one", "two", "three" };
        local function join(number, word) return number.." "..word; end
        assert.same({"1 one", "2 two", "3 three"} , Enumerable.From(numbers):Zip(words, join):ToArray());
    end);

    it("ignores excessive elements on the first sequence", function()
        local numbers = { 1, 2, 3, 4 };
        local words = { "one", "two", "three" };
        assert.same({{1, "one"}, {2, "two"}, {3, "three"}} , Enumerable.From(numbers):Zip(words):ToArray());
    end);

    it("ignores excessive elements on the second sequence", function()
        local numbers = { 1, 2, 3 };
        local words = { "one", "two", "three", "four" };
        assert.same({{1, "one"}, {2, "two"}, {3, "three"}} , Enumerable.From(numbers):Zip(words):ToArray());
    end);

    it("returns an empty array when the first sequence is empty", function()
        local numbers = {};
        local words = { "one", "two", "three", "four" };
        assert.same({} , Enumerable.From(numbers):Zip(words):ToArray());
    end);

    it("returns an empty array when the second sequence is empty", function()
        local numbers = { 1, 2, 3 };
        local words = {};
        assert.same({} , Enumerable.From(numbers):Zip(words):ToArray());
    end);

    it("returns an empty array when both sequences are empty", function()
        local numbers = {};
        local words = {};
        assert.same({} , Enumerable.From(numbers):Zip(words):ToArray());
    end);
end);

-- =====================================================================================================================
-- == OrderedEnumerable Unit Tests
-- =====================================================================================================================
