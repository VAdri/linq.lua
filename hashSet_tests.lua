local Linq = require "linq";
require "hashSet";

--- @type HashSet|Enumerable
local HashSet = Linq.HashSet;

local isSameProduct = function(product1, product2) return product1.Code == product2.Code; end;

describe("HashSet:Add", function()
    it("adds an item if it doesn't already exist", function()
        local hashSet = HashSet.New({"a", 12, false, {}});
        assert.equal(4, hashSet.Length);
        assert.is_true(hashSet:Add(1));
        assert.is_true(hashSet:Add(2));
        assert.is_true(hashSet:Add(3));
        assert.is_true(hashSet:Add(4));
        assert.is_true(hashSet:Add({}));
        assert.is_true(hashSet:Add({}));
        assert.is_true(hashSet:Add(true));
        assert.equal(11, hashSet.Length);
    end);

    it("adds an item if it doesn't already exist according to the comparer", function()
        local store = {
            { Name = "apple", Code = 9 },
            { Name = "orange", Code = 4 },
            { Name = "Apple", Code = 9 },
            { Name = "lemon", Code = 12 }
        };
        local hashSet = HashSet.New(store, isSameProduct);
        assert.equal(3, hashSet.Length);
        assert.is_true(hashSet:Add({ Name = "lemon", Code = 13 }));
        assert.equal(4, hashSet.Length);
    end);

    it("doesn't add an item if it already exist", function()
        local empty = {};
        local hashSet = HashSet.New({1, 2, 3, 4, empty});
        assert.equal(5, hashSet.Length);
        assert.is_false(hashSet:Add(1));
        assert.is_false(hashSet:Add(2));
        assert.is_false(hashSet:Add(3));
        assert.is_false(hashSet:Add(4));
        assert.is_true(hashSet:Contains(empty));
        assert.is_false(hashSet:Add(empty));
        assert.is_true(hashSet:Contains(empty));
        assert.equal(5, hashSet.Length);
    end);

    it("doesn't add an item if it already exist according to the comparer", function()
        local store = {
            { Name = "apple", Code = 9 },
            { Name = "orange", Code = 4 },
            { Name = "Apple", Code = 9 },
            { Name = "lemon", Code = 12 }
        };
        local hashSet = HashSet.New(store, isSameProduct);
        assert.equal(3, hashSet.Length);
        assert.is_false(hashSet:Add({ Name = "peach", Code = 12 }));
        assert.equal(3, hashSet.Length);
    end);

    it("raises an error when trying to add a nil value", function()
        assert.has_error(
            function()
                local hashSet = HashSet.New();
                hashSet:Add(nil);
            end,
            "Bad argument #1 to 'Add': 'item' cannot be a nil value."
        );
    end);
end);

describe("HashSet:Clear", function()
    it("clears all items from the set", function()
        local hashSet = HashSet.New({"a", 12, false, {}});
        assert.is_true(hashSet:Add(1));
        assert.is_true(hashSet:Add(2));
        assert.is_true(hashSet:Add(3));
        assert.is_true(hashSet:Add(4));
        assert.is_true(hashSet:Add({}));
        assert.is_true(hashSet:Add({}));
        assert.is_true(hashSet:Add(true));
        assert.is_true(hashSet:Contains("a"));
        assert.is_true(hashSet:Contains(1));
        assert.equal(11, hashSet.Length);
        hashSet:Clear();
        assert.is_false(hashSet:Contains("a"));
        assert.is_false(hashSet:Contains(1));
        assert.equal(0, hashSet.Length);
    end);
end);

describe("HashSet:Contains", function()
    it("uses the set comparer to determine if an item is in the set", function()
        local store = {
            { Name = "apple", Code = 9 },
            { Name = "orange", Code = 4 },
            { Name = "Apple", Code = 9 },
            { Name = "lemon", Code = 12 }
        };
        local hashSet = HashSet.New(store, isSameProduct);
        assert.is_true(hashSet:Contains(store[1]));
        assert.is_true(hashSet:Contains({ Name = "peach", Code = 12 }));
        assert.is_false(hashSet:Contains({ Name = "lemon", Code = 13 }));
    end);
end);

describe("HashSet:ExceptWith", function()
    it("removes all elements in the specified collection from the current object", function()
        local hashSet = HashSet.New({ 1, 1, 2, 3, 4, 5, 5 });
        hashSet:ExceptWith({ 3, 4, 4, 4, 5, 5, 6, 7, 8, 9, 9 });
        assert.same({ 1, 2 }, hashSet:ToArray());
    end);

    it("keeps an empty set when both sets are empty", function()
        local hashSet = HashSet.New();
        hashSet:ExceptWith({});
        assert.same({}, hashSet:ToArray());
    end);

    it("keeps the same elements when the other set is empty", function()
        local hashSet = HashSet.New({ 1, 1, 2, 3, 4, 5, 5 });
        hashSet:ExceptWith({});
        assert.same({ 1, 2, 3, 4, 5 }, hashSet:ToArray());
    end);

    it("keeps an empty set when the current set is empty", function()
        local hashSet = HashSet.New();
        hashSet:ExceptWith({ 3, 4, 4, 4, 5, 6, 7, 8, 9, 9 });
        assert.same({}, hashSet:ToArray());
    end);

    it("clears the set when both sequences contain the same elements", function()
        local obj = {};
        local hashSet = HashSet.New({"a", 12, false, obj});
        assert.is_true(hashSet:Add(1));
        assert.is_true(hashSet:Add(true));
        assert.equal(6, hashSet.Length);
        hashSet:ExceptWith({"a", 12, false, obj, 1, true});
        assert.equal(0, hashSet.Length);
    end);

    it("clears the set when both sequences contain the same elements", function()
        local obj = {};
        local hashSet = HashSet.New({"a", 12, false, obj});
        assert.is_true(hashSet:Add(1));
        assert.is_true(hashSet:Add(true));
        assert.equal(6, hashSet.Length);
        hashSet:ExceptWith({"a", 12, false, obj, 1, true});
        assert.equal(0, hashSet.Length);
    end);

    it("clears the set when the other sequence is the same set", function()
        local obj = {};
        local hashSet = HashSet.New({"a", 12, false, obj});
        assert.is_true(hashSet:Add(1));
        assert.is_true(hashSet:Add(true));
        assert.is_true(hashSet:Add({}));
        assert.equal(7, hashSet.Length);
        hashSet:ExceptWith(hashSet);
        assert.equal(0, hashSet.Length);
    end);
end);

describe("HashSet:IntersectWith", function()
    it("modifies the current object to contain only elements that are present in that object and in the specified collection", function()
        local hashSet = HashSet.New({ 1, 1, 2, 3, 4, 5, 5 });
        hashSet:IntersectWith({ 3, 4, 4, 4, 5, 5, 6, 7, 8, 9, 9 });
        assert.same({ 3, 4, 5 }, hashSet:ToArray());
    end);

    it("keeps an empty set when both sets are empty", function()
        local hashSet = HashSet.New();
        hashSet:IntersectWith({});
        assert.same({}, hashSet:ToArray());
    end);

    it("keeps an empty set when the current set is empty", function()
        local hashSet = HashSet.New();
        hashSet:IntersectWith({ 3, 4, 4, 4, 5, 6, 7, 8, 9, 9 });
        assert.same({}, hashSet:ToArray());
    end);

    it("keeps the set when both sequences contain the same elements", function()
        local obj = {};
        local hashSet = HashSet.New({"a", 12, false, obj});
        assert.is_true(hashSet:Add(1));
        assert.is_true(hashSet:Add(true));
        assert.equal(6, hashSet.Length);
        hashSet:IntersectWith({"a", 12, false, obj, 1, true});
        assert.equal(6, hashSet.Length);
    end);

    it("keeps the set when the other sequence contain the same elements and more", function()
        local obj = {};
        local hashSet = HashSet.New({"a", 12, false, obj});
        assert.is_true(hashSet:Add(1));
        assert.is_true(hashSet:Add(true));
        assert.equal(6, hashSet.Length);
        hashSet:IntersectWith({"a", 12, false, obj, 1, true, 13, "b", {}});
        assert.equal(6, hashSet.Length);
    end);

    it("keeps the set when the other sequence is the same set", function()
        local obj = {};
        local hashSet = HashSet.New({"a", 12, false, obj});
        assert.is_true(hashSet:Add(1));
        assert.is_true(hashSet:Add(true));
        assert.equal(6, hashSet.Length);
        hashSet:IntersectWith(hashSet);
        assert.equal(6, hashSet.Length);
    end);

    it("clears the set when the other set is empty", function()
        local hashSet = HashSet.New({ 1, 1, 2, 3, 4, 5, 5 });
        assert.equal(5, hashSet.Length);
        hashSet:IntersectWith({});
        assert.equal(0, hashSet.Length);
    end);
end);

describe("HashSet.New", function()
    it("creates a hash set using the given array as source", function()
        local hashSet = HashSet.New({1, 2, 3, 3});
        assert.same({1, 2, 3}, hashSet:ToArray());
    end);

    it("creates a hash set using the given enumerable as source", function()
        local hashSet = HashSet.New(Linq.Enumerable.From({1, 2, 3, 3}));
        assert.same({1, 2, 3}, hashSet:ToArray());
    end);

    it("creates a hash set that can be used with operations", function()
        local hashSet = HashSet.New({1, 2, a = 3, b = 3});
        assert.same({2, 4, 6}, hashSet:Select(function(n) return n * 2; end):ToTable());
    end);
end);

describe("HashSet:Remove", function()
    it("removes an item if it doesn't already exist", function()
        local empty = {};
        local hashSet = HashSet.New({"a", 12, false, empty});
        assert.is_true(hashSet:Add(1));
        assert.equal(5, hashSet.Length);
        assert.is_true(hashSet:Remove("a"));
        assert.is_true(hashSet:Remove(1));
        assert.is_true(hashSet:Remove(empty));
        assert.is_true(hashSet:Remove(false));
        assert.equal(1, hashSet.Length);
    end);

    it("removes an item if it exists according to the comparer", function()
        local store = {
            { Name = "apple", Code = 9 },
            { Name = "orange", Code = 4 },
            { Name = "Apple", Code = 9 },
            { Name = "lemon", Code = 12 }
        };
        local hashSet = HashSet.New(store, isSameProduct);
        assert.equal(3, hashSet.Length);
        assert.is_true(hashSet:Remove({ Name = "ananas", Code = 12 }));
        assert.equal(2, hashSet.Length);
    end);

    it("doesn't remove an item if it doesn't exist", function()
        local hashSet = HashSet.New({{}});
        assert.equal(1, hashSet.Length);
        assert.is_false(hashSet:Remove(1));
        assert.is_false(hashSet:Remove({}));
        assert.equal(1, hashSet.Length);
    end);

    it("doesn't remove an item if it doesn't exist according to the comparer", function()
        local store = {
            { Name = "apple", Code = 9 },
            { Name = "orange", Code = 4 },
            { Name = "Apple", Code = 9 },
            { Name = "lemon", Code = 12 }
        };
        local hashSet = HashSet.New(store, isSameProduct);
        assert.equal(3, hashSet.Length);
        assert.is_false(hashSet:Remove({ Name = "lemon", Code = 13 }));
        assert.equal(3, hashSet.Length);
    end);

    it("raises an error when trying to remove a nil value", function()
        assert.has_error(
            function()
                local hashSet = HashSet.New();
                hashSet:Remove(nil);
            end,
            "Bad argument #1 to 'Remove': 'item' cannot be a nil value."
        );
    end);
end);

describe("HashSet:SymmetricExceptWith", function()
    it("modifies the object to contain only elements that are present either in that object or in the specified collection, but not both", function()
        local hashSet = HashSet.New({ 1, 1, 2, 3, 4, 5, 5 });
        hashSet:SymmetricExceptWith({ 3, 4, 4, 4, 5, 5, 6, 7, 8, 9, 9 });
        assert.same({ 1, 2, 6, 7, 8, 9 }, hashSet:ToArray());
    end);

    it("keeps an empty set when both sets are empty", function()
        local hashSet = HashSet.New();
        hashSet:SymmetricExceptWith({});
        assert.same({}, hashSet:ToArray());
    end);

    it("keeps the same elements when the other set is empty", function()
        local hashSet = HashSet.New({ 1, 1, 2, 3, 4, 5, 5 });
        hashSet:SymmetricExceptWith({});
        assert.same({ 1, 2, 3, 4, 5 }, hashSet:ToArray());
    end);

    it("adds all the elements from the other set when the current set is empty", function()
        local hashSet = HashSet.New();
        hashSet:SymmetricExceptWith({ 3, 4, 4, 4, 5, 6, 7, 8, 9, 9 });
        assert.same({ 3, 4, 5, 6, 7, 8, 9 }, hashSet:ToArray());
    end);

    it("clears the set when both sequences contain the same elements", function()
        local obj = {};
        local hashSet = HashSet.New({"a", 12, false, obj});
        assert.is_true(hashSet:Add(1));
        assert.is_true(hashSet:Add(true));
        assert.equal(6, hashSet.Length);
        hashSet:SymmetricExceptWith({"a", 12, false, obj, 1, true});
        assert.equal(0, hashSet.Length);
    end);

    it("clears the set when the other sequence is the same set", function()
        local obj = {};
        local hashSet = HashSet.New({"a", 12, false, obj});
        assert.is_true(hashSet:Add(1));
        assert.is_true(hashSet:Add(true));
        assert.is_true(hashSet:Add({}));
        assert.equal(7, hashSet.Length);
        hashSet:SymmetricExceptWith(hashSet);
        assert.equal(0, hashSet.Length);
    end);
end);

describe("HashSet:TryGetValue", function()
    it("returns true and the value in the set", function()
        local hashSet = HashSet.New({1, 2, 3, 3, a = 4, "b", false});
        local obj = {};
        hashSet:Add(obj);
        local hasValue, value = hashSet:TryGetValue(1);
        assert.is_true(hasValue);
        assert.equal(1, value);
        hasValue, value = hashSet:TryGetValue(4);
        assert.is_true(hasValue);
        assert.equal(4, value);
        hasValue, value = hashSet:TryGetValue(obj);
        assert.is_true(hasValue);
        assert.equal(obj, value);
        hasValue, value = hashSet:TryGetValue("b");
        assert.is_true(hasValue);
        assert.equal("b", value);
        hasValue, value = hashSet:TryGetValue(false);
        assert.is_true(hasValue);
        assert.equal(false, value);
    end);

    it("returns true and the value in the set according to the comparer", function()
        local store = {
            { Name = "apple", Code = 9 },
            { Name = "orange", Code = 4 },
            { Name = "Apple", Code = 9 },
            { Name = "lemon", Code = 12 }
        };
        local hashSet = HashSet.New(store, isSameProduct);
        hashSet:Add("b", nil);
        local hasValue, value = hashSet:TryGetValue({ Name = "potato", Code = 9 });
        assert.is_true(hasValue);
        assert.equal(store[1], value);
        hasValue, value = hashSet:TryGetValue(store[2]);
        assert.is_true(hasValue);
        assert.equal(store[2], value);
    end);

    it("returns false and nil if the given key is not in the set", function()
        local hashSet = HashSet.New({1, 2, 3, 3, a = 4, "b", false});
        local obj = {};
        hashSet:Add(obj);
        local hasValue, value = hashSet:TryGetValue(0);
        assert.is_false(hasValue);
        assert.is_nil(value);
        hasValue, value = hashSet:TryGetValue("a");
        assert.is_false(hasValue);
        assert.is_nil(value);
        hasValue, value = hashSet:TryGetValue(true);
        assert.is_false(hasValue);
        assert.is_nil(value);
        hasValue, value = hashSet:TryGetValue({});
        assert.is_false(hasValue);
        assert.is_nil(value);
    end);

    it("returns false and nil if the given key is not in the set according to the comparer", function()
        local hashSet = HashSet.New({1, 2, 3, 3, "a"}, function() return false; end);
        local hasValue, value = hashSet:TryGetValue(1);
        assert.is_false(hasValue);
        assert.equal(nil, value);
        hasValue, value = hashSet:TryGetValue(3);
        assert.is_false(hasValue);
        assert.equal(nil, value);
        hasValue, value = hashSet:TryGetValue("a");
        assert.is_false(hasValue);
        assert.equal(nil, value);
    end);
end);

describe("HashSet:UnionWith", function()
    it("modifies the object to contain all elements that are present in itself, the specified collection, or both", function()
        local hashSet = HashSet.New({ 2, 2, 4, 6, 8, 8, 8 });
        hashSet:UnionWith({ 1, 3, 3, 5, 5, 5, 7, 9, 9, 9, 9 });
        assert.same({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, hashSet:ToArray());
    end);

    it("keeps an empty set when both sets are empty", function()
        local hashSet = HashSet.New();
        hashSet:UnionWith({});
        assert.same({}, hashSet:ToArray());
    end);

    it("keeps the same elements when the other set is empty", function()
        local hashSet = HashSet.New({ 1, 1, 2, 3, 4, 5, 5 });
        hashSet:UnionWith({});
        assert.same({ 1, 2, 3, 4, 5 }, hashSet:ToArray());
    end);

    it("adds all the elements from the other set when the current set is empty", function()
        local hashSet = HashSet.New();
        hashSet:UnionWith({ 3, 4, 4, 4, 5, 6, 7, 8, 9, 9 });
        assert.same({ 3, 4, 5, 6, 7, 8, 9 }, hashSet:ToArray());
    end);
end);
