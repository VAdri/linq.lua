local Linq = require "linq";
require "list";

--- @type List|ReadOnlyCollection|OrderedEnumerable|Enumerable
local List = Linq.List;

describe("List:Add", function()
    it("adds an item", function()
        local list = List.New({"a", 12, false, {}});
        assert.equal(4, list.Length);
        list:Add(1);
        list:Add(1);
        list:Add(2);
        list:Add("a");
        list:Add(3);
        list:Add(4);
        list:Add({});
        list:Add({});
        list:Add(true);
        list:Add(false);
        assert.equal(14, list.Length);
    end);

    it("doesn't add nil values", function()
        local list = List.New({"a", 12, false, nil, {}});
        assert.equal(4, list.Length);
        list:Add(nil);
        assert.equal(4, list.Length);
    end);
end);

describe("List:AddRange", function()
    it("adds items", function()
        local list = List.New({"a", 12, false, {}});
        assert.equal(4, list.Length);
        list:AddRange({1, 12, "a", 3, 4, {}, {}, true, false});
        assert.equal(13, list.Length);
    end);

    it("doesn't add nil values", function()
        local list = List.New({"a", 12, false, nil, {}});
        assert.equal(4, list.Length);
        list:AddRange({nil, 1});
        assert.equal(5, list.Length);
    end);

    it("doesn't change when the list is empty", function()
        local list = List.New({"a", 12, false, nil, {}});
        assert.equal(4, list.Length);
        list:AddRange({});
        assert.equal(4, list.Length);
    end);
end);

describe("List:Clear", function()
    it("clears all items from the list", function()
        local list = List.New({"a", 12, false, {}});
        list:Add(1);
        list:Add(2);
        list:Add(3);
        list:Add(4);
        list:Add({});
        list:Add({});
        list:Add(true);
        list:Add(false);
        assert.is_true(list:Contains("a"));
        assert.is_true(list:Contains(1));
        assert.equal(12, list.Length);
        list:Clear();
        assert.is_false(list:Contains("a"));
        assert.is_false(list:Contains(1));
        assert.equal(0, list.Length);
    end);
end);

describe("List.New", function()
    it("creates an list using the given array as source", function()
        local list = List.New({1, 2, 3, 4});
        assert.same({1, 2, 3, 4}, list:ToArray());
    end);

    it("creates an list using the given enumerable as source", function()
        local list = List.New(Linq.Enumerable.From({1, 2, 3, 4}));
        assert.same({1, 2, 3, 4}, list:ToArray());
    end);

    it("creates an list that can be used with operations", function()
        local list = List.New({1, 2, a = 3, b = 4});
        assert.same({2, 4, 6, 8}, list:Select(function(n) return n * 2; end):ToTable());
    end);
end);

describe("List:RemoveAt", function()
    it("removes an item at the specified index", function()
        local list = List.New({"a", 12, false, {}});
        assert.equal(4, list.Length);
        list:RemoveAt(4);
        assert.equal(3, list.Length);
        assert.same({"a", 12, false}, list:ToArray());
        list:RemoveAt(1);
        assert.equal(2, list.Length);
        assert.same({12, false}, list:ToArray());
    end);

    it("raises an error when the index is out of range", function()
        local list = List.New({"a", 12, false, nil, {}});
        assert.has_error(function() list:RemoveAt(5); end, "index is equal to or greater than Length.");
        assert.has_error(function() list:RemoveAt(10); end, "index is equal to or greater than Length.");
        assert.same({"a", 12, false, {}}, list:ToArray());
    end);

    it("raises an error when the index is equal or less than 0", function()
        local list = List.New({"a", 12, false, nil, {}});
        assert.has_error(function() list:RemoveAt(0); end, "index is less than 1.");
        assert.has_error(function() list:RemoveAt(-1); end, "index is less than 1.");
        assert.has_error(function() list:RemoveAt(-10); end, "index is less than 1.");
        assert.same({"a", 12, false, {}}, list:ToArray());
    end);
end);
