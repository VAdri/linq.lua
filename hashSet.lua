local Linq = require "linq";
require "list";

-- *********************************************************************************************************************
-- ** HashSet
-- *********************************************************************************************************************

--- @class HashSet : Enumerable
local HashSet = {};

--- Initializes a new instance of the {@see HashSet} class.
--- @param source table|nil @The collection whose elements are copied to the new set, or `nil` to start with an empty set.
--- @param comparer function|nil @The function to use when comparing values in the set, or `nil` to use the default equality comparer.
--- @return HashSet @The new instance of {@see HashSet}.
function HashSet.New(source, comparer)
    assert(source == nil or type(source) == "table");

    local set = Mixin({}, HashSet);
    set = setmetatable(set, {__index = function(t, key, ...) return Linq.Enumerable[key]; end});

    set.source = {};

    set.Comparer = comparer;
    set.Length = 0;

    source = Linq.Enumerable.IsEnumerable(source) and source:ToTable() or source;
    for _, v in pairs(source or {}) do set:Add(v); end

    set:_SetIterator();

    return set;
end

--- Iterates over all the elements in a set.
function HashSet:_SetIterator()
    local function getIterator()
        local index = 0;
        local key, value;
        if (self.comparer) then
            -- With a comparer we are not using a real set (slower)
            return function()
                key, value = next(self.source, key);
                if (not key) then return; end
                index = index + 1;
                return index, value;
            end
        else
            -- Without comparer we are using a real set (faster)
            return function()
                key = next(self.source, key);
                if (not key) then return; end
                index = index + 1;
                return index, key;
            end
        end
    end

    self.getIterator = getIterator;
end

--- For private use only.
function HashSet:_FindItemKey(item)
    if (self.Comparer) then
        for key, value in pairs(self.source) do if (self.Comparer(value, item)) then return key; end end
    else
        if (self.source[item]) then return item; end
    end

    return nil;
end

--- Adds the specified element to a set.
--- @param item any @The element to add to the set.
--- @return boolean @`true` if the element is added to the HashSet object; `false` if the element is already present.
HashSet.Add = Linq._Set.Add;

--- Removes all elements from a {@see HashSet} object.
function HashSet:Clear()
    wipe(self.source);
    self.Length = 0;
end

--- Determines whether a {@see HashSet} object contains the specified element.
--- @param item any @The element to locate in the {@see HashSet} object.
--- @return boolean @`true` if the {@see HashSet} object contains the specified element; otherwise, `false`.
function HashSet:Contains(item)
    if (self.Length == 0) then
        return false;
    else
        return self:_FindItemKey(item) ~= nil;
    end
end

--- Removes all elements in the specified collection from the current {@see HashSet} object.
--- @param other table @The collection of items to remove from the {@see HashSet} object.
function HashSet:ExceptWith(other)
    if (self.Length == 0) then
        -- The set is already empty
        return;
    elseif (other == self) then
        -- A set minus itself is empty
        self:Clear();
    else
        for _, value in pairs(other) do
            -- Remove every element in other from self
            self:Remove(value);
        end
    end
end

--- Modifies the current {@see HashSet} object to contain only elements that are present in that object and in the specified collection.
--- @param other table @The collection to compare to the current {@see HashSet} object.
function HashSet:IntersectWith(other)
    if (self.Length == 0 or other == self) then
        -- Intersection with empty set is empty
        -- Intersection with self is the same set
        return;
    else
        -- Mark items taht are contained in both sets
        local itemsToKeep = {};
        for _, value in pairs(other) do
            local key = self:_FindItemKey(value);
            if (key ~= nil) then itemsToKeep[key] = true; end
        end

        -- Remove items that have not been marked
        for key, _ in pairs(self.source) do
            if (not itemsToKeep[key]) then
                self.source[key] = nil;
                self.Length = self.Length - 1;
            end
        end
    end
end

--- Removes the specified element from a {@see HashSet} object.
--- @param item any @The element to remove.
--- @return boolean @`true` if the element is successfully found and removed; otherwise, `false`. This method returns `false` if item is not found in the HashSet object.
function HashSet:Remove(item)
    assert(item ~= nil, "Bad argument #1 to 'Linq.HashSet:Remove': 'item' cannot be a nil value.");

    if (self.Comparer) then
        for key, value in pairs(self.source) do
            if (self.Comparer(value, item)) then
                -- The item exists in the set
                table.remove(self.source, key);
                self.Length = self.Length - 1;
                return true;
            end
        end
        -- This item does not exist in the set
        return false;
    else
        if (self.source[item]) then
            -- The item exists in the set
            self.source[item] = nil;
            self.Length = self.Length - 1;
            return true;
        else
            -- This item does not exist in the set
            return false;
        end
    end
end

-- --- TODO: Code+Test+Doc
-- function HashSet:RemoveWhere(predicate) end

--- Modifies the current {@see HashSet} object to contain only elements that are present either in that object or in the specified collection, but not both.
--- @param other table @The collection to compare to the current {@see HashSet} object.
function HashSet:SymmetricExceptWith(other)
    if (self.Length == 0) then
        -- If set is empty, then symmetric difference is other.
        self:UnionWith(other);
    elseif (other == self) then
        -- The symmetric difference of a set with itself is the empty set.
        self:Clear();
    else
        -- Mark items that could not be added and those that were added from the other set
        local addedFromOther = {};
        local itemsToRemove = Linq.List.New();
        for _, value in pairs(other) do
            if (self:Add(value)) then
                table.insert(addedFromOther, value);
            else
                itemsToRemove:Add(value);
            end
        end
        for _, value in pairs(itemsToRemove:Except(addedFromOther):ToArray()) do
            -- Removes only items taht are marked as itemsToRemove but not addedFromOther
            self:Remove(value);
        end
    end
end

--- TODO: Test+Doc
function HashSet:TryGetValue(equalValue)
    if (self.Comparer) then
        for _, value in pairs(self.source) do
            if (self.Comparer(value, equalValue)) then
                -- The item exists in the set
                return true, value;
            end
        end
        -- This item does not exist in the set
        return false, equalValue;
    else
        if (self.source[equalValue]) then
            -- The item exists in the set
            return true, equalValue;
        else
            -- This item does not exist in the set
            return false, equalValue;
        end
    end
end

--- Modifies the current {@see HashSet} object to contain all elements that are present in itself, the specified collection, or both.
--- @param other table @The collection to compare to the current {@see HashSet} object.
function HashSet:UnionWith(other) for _, value in pairs(other) do self:Add(value); end end

-- *********************************************************************************************************************
-- ** Export
-- *********************************************************************************************************************

Linq.HashSet = HashSet;
