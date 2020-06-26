local Linq;

if (LibStub) then
    Linq = LibStub("Linq");
else
    Linq = require "linq";
end

--- @type ReadOnlyCollection|Enumerable
local ReadOnlyCollection = Linq.ReadOnlyCollection;

local assert, type, pairs, setmetatable = assert, type, pairs, setmetatable;
local wipe = wipe;

-- *********************************************************************************************************************
-- ** List
-- *********************************************************************************************************************

--- @class List : ReadOnlyCollection
local List = {};

local ListMT = {__index = function(t, key, ...) return List[key] or Linq.Enumerable[key]; end};

Mixin(List, ReadOnlyCollection);

--- Initializes a new instance of the {@see List} class.
--- @param source table|nil
--- @return List @The new instance of {@see List}.
function List.New(source)
    assert(source == nil or type(source) == "table");

    local list = setmetatable({}, ListMT);

    list.Length = 0;

    list.source = {};

    -- Shallow copy because we don't want to modify the source sequence
    if (Linq.Enumerable.IsEnumerable(source)) then
        for _, v in source:GetEnumerator() do list:Add(v); end
    else
        for _, v in pairs(source or {}) do list:Add(v); end
    end

    list:_ArrayIterator();

    return list;
end

--- Adds an object to the end of the {@see List}.
--- @param item any @The object to be added to the end of the {@see List}.
function List:Add(item)
    self.Length = self.Length + 1;

    -- Not using table.insert here because item can be nil
    self.source[self.Length] = item;
end

--- Adds the elements of the specified collection to the end of the {@see List}.
--- @param collection table @The collection whose elements should be added to the end of the {@see List}.
function List:AddRange(collection) for _, v in pairs(collection) do self:Add(v); end end

--- Removes all elements from the {@see List}.
function List:Clear()
    wipe(self.source);
    self.Length = 0;
end

--- Removes the element at the specified index of the {@see List}.
--- @param index number @The one-based index of the element to remove.
function List:RemoveAt(index)
    assert(index >= 1, "index is less than 1.");
    assert(index <= self.Length, "index is equal to or greater than Length.");

    -- Remove the element at the current index by moving each element in the index below
    -- (we cannot use table.remove because the table can contain nil values)
    for i = index, self.Length do self.source[i] = self.source[i + 1]; end
    self.Length = self.Length - 1;
end

-- *********************************************************************************************************************
-- ** Export
-- *********************************************************************************************************************

Linq.List = List;
Linq.ReadOnlyCollection = ReadOnlyCollection;
