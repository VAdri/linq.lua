local Linq;

if (LibStub) then
    Linq = LibStub("Linq");
else
    Linq = require "linq";
end

--- @type ReadOnlyCollection|OrderedEnumerable|Enumerable
local ReadOnlyCollection = Linq.ReadOnlyCollection;

-- *********************************************************************************************************************
-- ** List
-- *********************************************************************************************************************

--- @class List : ReadOnlyCollection
local List = {};

Mixin(List, ReadOnlyCollection);

--- Initializes a new instance of the {@see List} class.
--- @param source table|nil
--- @return List @The new instance of {@see List}.
function List.New(source)
    assert(source == nil or type(source) == "table");

    local list = Mixin({}, List);
    list = setmetatable(list, {__index = function(t, key, ...) return Linq.OrderedEnumerable[key]; end});

    list.Length = 0;

    -- Shallow copy because we don't want to modify the source sequence
    source = Linq.Enumerable.IsEnumerable(source) and source:ToTable() or source;
    list.source = {};
    for _, v in pairs(source or {}) do list:Add(v); end

    list:_ArrayIterator();

    return list;
end

--- Adds an object to the end of the {@see List}.
--- @param item any @The object to be added to the end of the {@see List}.
function List:Add(item)
    if (item ~= nil) then
        self.Length = self.Length + 1;
        table.insert(self.source, item);
    end
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
    table.remove(self.source, index);
    self.Length = #self.source;
end

-- *********************************************************************************************************************
-- ** Export
-- *********************************************************************************************************************

Linq.List = List;
Linq.ReadOnlyCollection = ReadOnlyCollection;
