local Linq;

if (LibStub) then
    Linq = LibStub("Linq");
else
    Linq = require "linq";
end

--- @type Set|Enumerable
local Set = Linq.Set;

local assert, type, pairs, setmetatable = assert, type, pairs, setmetatable;
local tinsert = table.insert;

-- *********************************************************************************************************************
-- ** HashSet
-- *********************************************************************************************************************

--- @class HashSet : Set
local HashSet = {};

local HashSetMT = {__index = function(t, key, ...) return HashSet[key] or Linq.Enumerable[key]; end};

Mixin(HashSet, Set);

--- Initializes a new instance of the {@see HashSet} class.
--- @param source table|nil @The collection whose elements are copied to the new set, or `nil` to start with an empty set.
--- @param comparer function|nil @The function to use when comparing values in the set, or `nil` to use the default equality comparer.
--- @return HashSet @The new instance of {@see HashSet}.
function HashSet.New(source, comparer)
    assert(source == nil or type(source) == "table");

    local set = setmetatable({}, HashSetMT);

    set.source = {};

    set.Comparer = comparer;
    set.Length = 0;

    if (Linq.Enumerable.IsEnumerable(source)) then
        for _, v in source:GetEnumerator() do set:Add(v); end
    else
        for _, v in pairs(source or {}) do set:Add(v); end
    end

    set:_SetIterator();

    return set;
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
        local itemsToRemove = {};
        for _, value in pairs(other) do
            if (self:Add(value)) then
                tinsert(addedFromOther, value);
            else
                tinsert(itemsToRemove, value);
            end
        end
        for _, value in pairs(Linq.Enumerable.From(itemsToRemove):Except(addedFromOther):ToArray()) do
            -- Removes only items taht are marked as itemsToRemove but not addedFromOther
            self:Remove(value);
        end
    end
end

--- Searches the set for a given value and returns the equal value it finds, if any.
--- @param equalValue any @The value to search for.
--- @return boolean @A value indicating whether the search was successful.
--- @return any @The value from the set that the search found, or `nil` when the search yielded no match.
function HashSet:TryGetValue(equalValue)
    if (self.Comparer) then
        for _, value in pairs(self.source) do
            if (self.Comparer(value, equalValue)) then
                -- The item exists in the set
                return true, value;
            end
        end
        -- This item does not exist in the set
        return false, nil;
    else
        if (self.source[equalValue]) then
            -- The item exists in the set
            return true, equalValue;
        else
            -- This item does not exist in the set
            return false, nil;
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
