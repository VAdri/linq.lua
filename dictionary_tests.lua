local Linq = require "linq";
require "dictionary";

--- @type Dictionary|Enumerable
local Dictionary = Linq.Dictionary;

local sameTypeComparer = function(item1, item2) return type(item1) == type(item2); end;

describe("Dictionary:Add", function()
    it("adds a key/value pair if it doesn't already exist", function()
        local dic = Dictionary.New();

        assert.equal(0, dic.Length);
        assert.is_false(dic:ContainsKey(1));
        assert.is_false(dic:ContainsValue(1));
        dic:Add(1, 1);
        assert.is_true(dic:ContainsKey(1));
        assert.is_true(dic:ContainsValue(1));
        dic:Add(2, 1);
        assert.is_true(dic:ContainsKey(1));
        assert.is_true(dic:ContainsValue(1));
        dic:Add(3, "a");
        dic:Add("a", 1);
        local obj = {};
        dic:Add(obj, {});
        dic:Add(true, false);
        dic:Add(false, nil);
        assert.equal(7, dic.Length);

        assert.same(
            {
                [1] = 1,
                [2] = 1,
                [3] = "a",
                ["a"] = 1,
                [obj] = {},
                [true] = false,
                [false] = nil,
            },
            dic:ToTable()
        );
    end);

    it("adds a key/value pair when using a comparer", function()
        local dic = Dictionary.New(nil, sameTypeComparer);

        assert.equal(0, dic.Length);
        dic:Add(1, 1);
        dic:Add("a", 1);
        local obj = {};
        dic:Add(obj, {});
        dic:Add(true, false);
        assert.equal(4, dic.Length);

        assert.same(
            {
                [1] = 1,
                ["a"] = 1,
                [obj] = {},
                [true] = false,
            },
            dic:ToTable()
        );
    end);

    it("raises an error when trying to add a nil key", function()
        assert.has_error(
            function()
                local dic = Dictionary.New();
                dic:Add(nil);
            end,
            "Bad argument #1 to 'Add': 'key' cannot be a nil value."
        );
    end);

    it("raises an error when trying to add a duplicate key", function()
        local dic = Dictionary.New();
        dic:Add(1, 1);
        dic:Add(2, 1);
        local obj = {};
        dic:Add(obj, "a");
        dic:Add({}, "a");

        assert.has_error(
            function()
                dic:Add(1, 2);
            end,
            "An element with the same key already exists in the dictionary."
        );
        assert.has_error(
            function()
                dic:Add(obj, "a");
            end,
            "An element with the same key already exists in the dictionary."
        );
    end);

    it("raises an error when trying to add a duplicate key according to the comparer", function()
        local dic = Dictionary.New(nil, sameTypeComparer);
        dic:Add(1, 1);
        dic:Add("a", 1);

        assert.has_error(
            function()
                dic:Add(2, 2);
            end,
            "An element with the same key already exists in the dictionary."
        );
    end);
end);

describe("Dictionary:Clear", function()
    it("clears all items from the dictionary", function()
        local dic = Dictionary.New();

        assert.equal(0, dic.Length);
        dic:Add(1, 1);
        dic:Add(2, 1);
        dic:Add(3, "a");
        dic:Add("a", 1);
        dic:Add({}, {});
        dic:Add(true, false);
        dic:Add(false, nil);

        assert.equal(7, dic.Length);
        assert.is_true(dic:ContainsKey(1));
        assert.is_true(dic:ContainsValue("a"));
        dic:Clear();
        assert.equal(0, dic.Length);

        assert.same({}, dic:ToArray());
        assert.is_false(dic:ContainsKey(1));
        assert.is_false(dic:ContainsValue("a"));
    end);
end);

describe("Dictionary:ContainsKey", function()
    it("indicates whether the key is in the dictionary", function()
        local dic = Dictionary.New({1, 2, 3, 3, a = 4});
        dic:Add(5, 3);

        assert.is_true(dic:ContainsKey("a"));
        assert.is_false(dic:ContainsKey("b"));
        assert.is_true(dic:ContainsKey(1));
        assert.is_true(dic:ContainsKey(5));
        assert.is_false(dic:ContainsKey(6));
    end);

    it("uses the comparer to determine if the key is in the dictionary", function()
        local dic = Dictionary.New({1, a=1, [false]=true}, sameTypeComparer);
        assert.is_true(dic:ContainsKey("b"));
        assert.is_false(dic:ContainsKey({}));
    end);

    it("raises an error when trying the given key is nil", function()
        local dic = Dictionary.New({1, a=1, [false]=true, b=2});
        assert.has_error(
            function()
                dic:ContainsKey(nil);
            end,
            "Bad argument #1 to 'ContainsKey': 'key' cannot be a nil value."
        );
    end);
end);

describe("Dictionary:ContainsValue", function()
    it("indicates whether the value is in the dictionary", function()
        local dic = Dictionary.New({1, 2, 3, 3, a = 4});
        local obj = {};
        dic:Add(5, obj);

        assert.is_true(dic:ContainsValue(1));
        assert.is_true(dic:ContainsValue(3));
        assert.is_true(dic:ContainsValue(4));
        assert.is_true(dic:ContainsValue(obj));
        assert.is_false(dic:ContainsValue(6));
        assert.is_false(dic:ContainsValue({}));
        assert.is_false(dic:ContainsValue("a"));
    end);
end);

describe("Dictionary.Keys", function()
    it("contains all the keys that are in the dictionary", function()
        local dic = Dictionary.New({1, 2, 3, 3, a = 4});

        assert.same({1, 2, 3, 4, "a"}, dic.Keys:ToTable());

        local obj = {};
        dic:Add(5, obj);
        assert.same({1, 2, 3, 4, "a", 5}, dic.Keys:ToTable());

        dic:Add(obj, false);
        assert.same({1, 2, 3, 4, "a", 5, obj}, dic.Keys:ToTable());

        dic:Remove(3);
        assert.same({1, 2, 4, "a", 5, obj}, dic.Keys:ToTable());

        dic:Add("b", nil);
        assert.same({1, 2, 4, "a", 5, obj, "b"}, dic.Keys:ToTable());

        dic:Add("c", true);
        assert.same({1, 2, 4, "a", 5, obj, "b", "c"}, dic.Keys:ToTable());

        dic:Remove(obj);
        assert.same({1, 2, 4, "a", 5, "b", "c"}, dic.Keys:ToTable());
    end);

    it("contains all the keys that are in the dictionary with a comparer", function()
        local dic = Dictionary.New({1, a = 4}, sameTypeComparer);

        assert.same({1, "a"}, dic.Keys:ToTable());

        local obj = {};
        dic:TryAdd(5, obj);
        assert.same({1, "a"}, dic.Keys:ToTable());

        dic:Add(obj, false);
        assert.same({1, "a", obj}, dic.Keys:ToTable());

        dic:Remove(1);
        assert.same({"a", obj}, dic.Keys:ToTable());

        dic:TryAdd("b", nil);
        assert.same({"a", obj}, dic.Keys:ToTable());

        dic:Add(false, true);
        assert.same({"a", obj, false}, dic.Keys:ToTable());

        dic:Remove({});
        assert.same({"a", false}, dic.Keys:ToTable());

        dic:Add(2);
        assert.same({"a", false, 2}, dic.Keys:ToTable());
    end);
end);

describe("Dictionary.New", function()
    it("creates a dictionary using the given table as source", function()
        local dic = Dictionary.New({1, 2, 3, 3, a = 4});

        assert.same(
            {
                [1] = 1,
                [2] = 2,
                [3] = 3,
                [4] = 3,
                ["a"] = 4,
            },
            dic:ToTable()
        );
    end);

    it("creates a dictionary using the given dictionary as source", function()
        local dic1 = Dictionary.New({1, 2, 3, 3, a = 4});
        dic1:Add(5, 3);

        local dic2 = Dictionary.New(dic1);
        assert.same(dic1:ToTable(), dic2:ToTable());
        assert.same(
            {
                [1] = 1,
                [2] = 2,
                [3] = 3,
                [4] = 3,
                ["a"] = 4,
                [5] = 3,
            },
            dic2:ToTable()
        );
    end);

    it("creates a dictionary using the given enumerable as source", function()
        local dic = Dictionary.New(Linq.Enumerable.From({1, 2, 3, 3, a = 4}));

        assert.same(
            {
                [1] = 1,
                [2] = 2,
                [3] = 3,
                [4] = 3,
                ["a"] = 4,
            },
            dic:ToTable()
        );
    end);

    it("creates a dictionary that can be used with operations", function()
        local hashSet = Dictionary.New({1, 2, a = 3, b = 3});
        assert.same({2, 4, 6, 6}, hashSet:Select(function(n) return n * 2; end):ToArray());
    end);

    it("raises an error when trying to initialize with a duplicate key according to the comparer", function()
        assert.has_error(
            function()
                Dictionary.New({1, a=1, [false]=true, b=2}, sameTypeComparer);
            end,
            "An element with the same key already exists in the dictionary."
        );
    end);
end);

describe("Dictionary:Remove", function()
    it("removes the entry with the given key in the dictionary and return its value", function()
        local obj = {};
        local dic = Dictionary.New({1, a=1, [false]=true, b=2, [obj] = obj});
        dic:Add(true, nil);

        assert.is_true(dic:ContainsKey(1));
        assert.is_true(dic:ContainsValue(obj));

        assert.equal(6, dic.Length);
        local removed, value = dic:Remove(1);
        assert.is_true(removed);
        assert.equal(1, value);
        removed, value = dic:Remove("a");
        assert.is_true(removed);
        assert.equal(1, value);
        removed, value = dic:Remove(false);
        assert.is_true(removed);
        assert.equal(true, value);
        removed, value = dic:Remove(true);
        assert.is_true(removed);
        assert.equal(nil, value);
        removed, value = dic:Remove(obj);
        assert.is_true(removed);
        assert.equal(obj, value);
        assert.equal(1, dic.Length);

        assert.is_false(dic:ContainsKey(1));
        assert.is_false(dic:ContainsValue(obj));
    end);

    it("removes the entry with the given key in the dictionary according to the comparerand return its real value", function()
        local obj = {};
        local dic = Dictionary.New({1, a=1, [false]=true, [obj] = obj}, sameTypeComparer);

        assert.equal(4, dic.Length);
        local removed, value = dic:Remove(2);
        assert.is_true(removed);
        assert.equal(1, value);
        removed, value = dic:Remove("b");
        assert.is_true(removed);
        assert.equal(1, value);
        removed, value = dic:Remove(true);
        assert.is_true(removed);
        assert.equal(true, value);
        removed, value = dic:Remove({});
        assert.is_true(removed);
        assert.equal(obj, value);
        assert.equal(0, dic.Length);
    end);

    it("returns false when the given key is not in the dictionary", function()
        local obj = {};
        local dic = Dictionary.New({1, a=1, [false]=true, b=2, [obj] = obj});

        assert.equal(5, dic.Length);
        local removed, value = dic:Remove(2);
        assert.is_false(removed);
        assert.is_nil(value);
        removed, value = dic:Remove("c");
        assert.is_false(removed);
        assert.is_nil(value);
        removed, value = dic:Remove(true);
        assert.is_false(removed);
        assert.is_nil(value);
        removed, value = dic:Remove({});
        assert.is_false(removed);
        assert.is_nil(value);
        assert.equal(5, dic.Length);
    end);

    it("returns false when the given key is not in the dictionary according to the comparer", function()
        local obj = {};
        local dic = Dictionary.New({1, a=1, [false]=true, b=2, [obj] = obj}, function() return false; end);

        assert.equal(5, dic.Length);
        local removed, value = dic:Remove(1);
        assert.is_false(removed);
        assert.is_nil(value);
        removed, value = dic:Remove("a");
        assert.is_false(removed);
        assert.is_nil(value);
        removed, value = dic:Remove(false);
        assert.is_false(removed);
        assert.is_nil(value);
        removed, value = dic:Remove(true);
        assert.is_false(removed);
        assert.is_nil(value);
        removed, value = dic:Remove(obj);
        assert.is_false(removed);
        assert.is_nil(value);
        removed, value = dic:Remove({});
        assert.is_false(removed);
        assert.is_nil(value);
        assert.equal(5, dic.Length);
    end);

    it("raises an error when the given key is nil", function()
        local dic = Dictionary.New({1, a=1, [false]=true, b=2});
        assert.has_error(
            function()
                dic:Remove(nil);
            end,
            "Bad argument #1 to 'Remove': 'key' cannot be a nil value."
        );
    end);
end);

describe("Dictionary:TryAdd", function()
    it("adds a key/value pair if it doesn't already exist", function()
        local dic = Dictionary.New();

        assert.equal(0, dic.Length);
        assert.is_true(dic:TryAdd(1, 1));
        assert.is_true(dic:TryAdd(2, 1));
        assert.is_true(dic:TryAdd(3, "a"));
        assert.is_true(dic:TryAdd("a", 1));
        local obj = {};
        assert.is_true(dic:TryAdd(obj, {}));
        assert.is_true(dic:TryAdd(true, false));
        assert.is_true(dic:TryAdd(false, nil));
        assert.is_true(dic:TryAdd(4, 1));
        assert.equal(8, dic.Length);

        assert.same(
            {
                [1] = 1,
                [2] = 1,
                [3] = "a",
                ["a"] = 1,
                [obj] = {},
                [true] = false,
                [false] = nil,
                [4] = 1,
            },
            dic:ToTable()
        );
    end);

    it("adds a key/value pair when using a comparer", function()
        local dic = Dictionary.New(nil, sameTypeComparer);

        assert.equal(0, dic.Length);
        assert.is_true(dic:TryAdd(1, 1));
        assert.is_true(dic:TryAdd("a", 1));
        local obj = {};
        assert.is_true(dic:TryAdd(obj, {}));
        assert.is_true(dic:TryAdd(true, false));
        assert.equal(4, dic.Length);

        assert.same(
            {
                [1] = 1,
                ["a"] = 1,
                [obj] = {},
                [true] = false,
            },
            dic:ToTable()
        );
    end);

    it("raises an error when trying to add a nil key", function()
        assert.has_error(
            function()
                local dic = Dictionary.New();
                dic:TryAdd(nil);
            end,
            "Bad argument #1 to 'TryAdd': 'key' cannot be a nil value."
        );
    end);

    it("doesn't add a key/value pair when the key is a duplicate", function()
        local dic = Dictionary.New();

        assert.equal(0, dic.Length);
        local obj = {};
        assert.is_true(dic:TryAdd(1, 1));
        assert.is_true(dic:TryAdd(2, 1));
        assert.is_true(dic:TryAdd(3, "a"));
        assert.is_true(dic:TryAdd("a", 1));
        assert.is_true(dic:TryAdd(obj, obj));
        assert.is_true(dic:TryAdd(true, false));
        assert.is_true(dic:TryAdd(false, nil));
        assert.equal(7, dic.Length);
        assert.is_false(dic:TryAdd(1, 1));
        assert.is_false(dic:TryAdd("a", "a"));
        assert.is_false(dic:TryAdd(obj, 1));
        assert.is_false(dic:TryAdd(true, nil));
        assert.is_false(dic:TryAdd(false, true));
        assert.equal(7, dic.Length);
    end);

    it("doesn't add a key/value pair when the key is a duplicate according to the comparer", function()
        local dic = Dictionary.New(nil, sameTypeComparer);

        assert.equal(0, dic.Length);
        assert.is_true(dic:TryAdd(1, 1));
        assert.is_true(dic:TryAdd("a", 1));
        assert.is_true(dic:TryAdd({}, {}));
        assert.is_true(dic:TryAdd(true, false));
        assert.equal(4, dic.Length);
        assert.is_false(dic:TryAdd(1, "a"));
        assert.is_false(dic:TryAdd("a", 1));
        assert.is_false(dic:TryAdd({}, {}));
        assert.is_false(dic:TryAdd(true, nil));
        assert.equal(4, dic.Length);
    end);
end);

describe("Dictionary:TryGetValue", function()
    it("returns true and the value associated to the given key", function()
        local dic = Dictionary.New({1, 2, 3, 3, a = 4});
        local obj = {};
        dic:Add(5, obj);
        dic:Add(obj, 6);

        local hasValue, value = dic:TryGetValue(1);
        assert.is_true(hasValue);
        assert.equal(1, value);
        hasValue, value = dic:TryGetValue("a");
        assert.is_true(hasValue);
        assert.equal(4, value);
        hasValue, value = dic:TryGetValue(5);
        assert.is_true(hasValue);
        assert.equal(obj, value);
        hasValue, value = dic:TryGetValue(obj);
        assert.is_true(hasValue);
        assert.equal(6, value);
    end);

    it("returns true and the value associated to the given key according to the comparer", function()
        local dic = Dictionary.New({1, [false]=true, b=nil, [{}] = "a"}, sameTypeComparer);
        dic:Add("b", nil);

        local hasValue, value = dic:TryGetValue(2);
        assert.is_true(hasValue);
        assert.equal(1, value);
        hasValue, value = dic:TryGetValue("a");
        assert.is_true(hasValue);
        assert.equal(nil, value);
        hasValue, value = dic:TryGetValue(true);
        assert.is_true(hasValue);
        assert.equal(true, value);
        hasValue, value = dic:TryGetValue({});
        assert.is_true(hasValue);
        assert.equal("a", value);
    end);

    it("returns false and nil if the given key is not in the dictionary", function()
        local dic = Dictionary.New({1, 2, 3, 3, a = 4});
        local obj = {};
        dic:Add(5, obj);
        dic:Add(obj, 6);

        local hasValue, value = dic:TryGetValue(0);
        assert.is_false(hasValue);
        assert.is_nil(value);
        hasValue, value = dic:TryGetValue("b");
        assert.is_false(hasValue);
        assert.is_nil(value);
        hasValue, value = dic:TryGetValue({});
        assert.is_false(hasValue);
        assert.is_nil(value);
    end);

    it("returns false and nil if the given key is not in the dictionary according to the comparer", function()
        local dic = Dictionary.New({1, 2, 3, 3, a = 4}, function() return false; end);
        dic:Add("a", 5);

        local hasValue, value = dic:TryGetValue(1);
        assert.is_false(hasValue);
        assert.equal(nil, value);
        hasValue, value = dic:TryGetValue("a");
        assert.is_false(hasValue);
        assert.equal(nil, value);
    end);

    it("raises an error when the given key is nil", function()
        local dic = Dictionary.New({1, a=1, [false]=true, b=2});
        assert.has_error(
            function()
                dic:TryGetValue(nil);
            end,
            "Bad argument #1 to 'TryGetValue': 'key' cannot be a nil value."
        );
    end);
end);

describe("Dictionary.Values", function()
    it("contains all the values that are in the dictionary", function()
        local dic = Dictionary.New({1, 2, 3, 3, a = 4});

        assert.same({1, 2, 3, 3, 4}, dic.Values:ToTable());

        local obj = {};
        dic:Add(5, obj);
        assert.same({1, 2, 3, 3, 4, obj}, dic.Values:ToTable());

        dic:Add(obj, false);
        assert.same({1, 2, 3, 3, 4, obj, false}, dic.Values:ToTable());

        dic:Remove(3);
        assert.same({1, 2, 3, 4, obj, false}, dic.Values:ToTable());

        dic:Add("b", nil);
        assert.same({1, 2, 3, 4, obj, false}, dic.Values:ToTable());

        dic:Add("c", true);
        assert.same({1, 2, 3, 4, obj, false, [8] = true}, dic.Values:ToTable());

        dic:Remove(obj);
        assert.same({1, 2, 3, 4, obj, [7] = true}, dic.Values:ToTable());
    end);
end);
