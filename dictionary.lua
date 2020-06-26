local Linq;

if (LibStub) then
    Linq = LibStub("Linq");
else
    Linq = require "linq";
    require "list";
end

local assert, type, pairs, ipairs, next, setmetatable = assert, type, pairs, ipairs, next, setmetatable;

-- *********************************************************************************************************************
-- ** Dictionary
-- *********************************************************************************************************************

--- @class Dictionary : Enumerable
local Dictionary = {};

local DictionaryMT = {__index = function(t, key, ...) return Dictionary[key] or Linq.Enumerable[key]; end};

--- Initializes a new instance of the {@see Dictionary} class.
--- @param source table|nil @The collection whose elements are copied to the new set, or `nil` to start with an empty set.
--- @param comparer function|nil @The function to use when comparing values in the set, or `nil` to use the default equality comparer.
--- @return Dictionary @The new instance of {@see Dictionary}.
function Dictionary.New(source, comparer)
    assert(source == nil or type(source) == "table");

    local dic = setmetatable({}, DictionaryMT);

    dic.Keys = Linq.List.New();
    dic.Values = Linq.List.New();

    dic.Comparer = comparer;
    dic.Length = 0;

    if (Linq.Enumerable.IsEnumerable(source)) then
        for k, v in source:GetEnumerator() do dic:Add(k, v); end
    else
        for k, v in pairs(source or {}) do dic:Add(k, v); end
    end

    dic:_DicIterator();

    return dic;
end

function Dictionary:_FindKeyIndex(key)
    if (self.Comparer) then
        for i, k in self.Keys:GetEnumerator() do if (self.Comparer(k, key)) then return i; end end
    else
        for i, k in self.Keys:GetEnumerator() do if (k == key) then return i; end end
    end
    return nil;
end

--- Iterates over all the elements in a set.
function Dictionary:_DicIterator()
    self.getIterator = function()
        local index, key;
        return function()
            index, key = next(self.Keys.source, index);
            if (not index) then return; end
            return key, self.Values.source[index];
            -- return index, {Key = key, Value = self.Values[index]};
        end
    end
end

--- Adds the specified key and value to the dictionary.
--- @param key any @The key of the element to add.
--- @param value any @The value of the element to add. It can be `nil`.
function Dictionary:Add(key, value)
    assert(key ~= nil, "Bad argument #1 to 'Add': 'key' cannot be a nil value.");
    if (not self:TryAdd(key, value)) then error("An element with the same key already exists in the dictionary."); end
end

--- Removes all elements from a {@see Dictionary} object.
function Dictionary:Clear()
    self.Keys:Clear();
    self.Values:Clear();
    self.Length = 0;
end

--- Determines whether the dictionary contains the specified key.
--- @param key any @The key to locate in the dictionary.
--- @return boolean @`true` if the dictionary contains an element with the specified key; otherwise, `false`.
function Dictionary:ContainsKey(key)
    assert(key ~= nil, "Bad argument #1 to 'ContainsKey': 'key' cannot be a nil value.");
    return self:_FindKeyIndex(key) ~= nil;
end

--- Determines whether the dictionary contains a specific value.
--- @param value any @The value to locate in the dictionary. The value can be `nil`.
--- @return boolean @`true` if the dictionary contains an element with the specified value; otherwise, `false`.
function Dictionary:ContainsValue(value)
    for _, v in self.Values:GetEnumerator() do if (v == value) then return true; end end
    return false;
end

--- Removes the value with the specified key from the dictionary.
--- @param key any @The key of the element to remove.
--- @return boolean @`true` if the element is successfully found and removed; otherwise, `false`.
--- @return any @The removed element, if any; otherwise, `nil`.
function Dictionary:Remove(key)
    assert(key ~= nil, "Bad argument #1 to 'Remove': 'key' cannot be a nil value.");
    if (self.Length == 0) then return false, nil; end

    local index = self:_FindKeyIndex(key);
    if (index == nil) then
        return false, nil;
    else
        local value = self.Values.source[index];

        self.Keys:RemoveAt(index);
        self.Values:RemoveAt(index);
        -- tremove(self.Keys, index);

        -- -- Remove the element at the current index by moving each element in the index below
        -- -- (we cannot use table.remove because the table can contain nil values)
        -- local value = self.Values[index];
        -- for i = index, self.Length do
        --     self.Values[i] = self.Values[i + 1];
        -- end

        self.Length = self.Keys.Length;
        return true, value;
    end
end

--- Attempts to add the specified key and value to the dictionary.
--- @param key any @The key of the element to add.
--- @param value any @The value of the element to add. It can be `nil`.
--- @return boolean @`true` if the key/value pair was added to the dictionary successfully; otherwise, `false`.
function Dictionary:TryAdd(key, value)
    assert(key ~= nil, "Bad argument #1 to 'TryAdd': 'key' cannot be a nil value.");
    if (self:_FindKeyIndex(key)) then
        return false;
    else
        -- self.Length = self.Length + 1;

        -- tinsert(self.Keys, key);

        -- -- Not using table.insert here because values can be nil so Keys and Values would be out of sync
        -- self.Values[self.Length] = value;

        self.Keys:Add(key);
        self.Values:Add(value);

        self.Length = self.Keys.Length;
        return true;
    end
end

--- Gets the value associated with the specified key.
--- @param key any @The key of the value to get.
--- @return boolean @`true` if the dictionary contains an element with the specified key; otherwise, `false`.
--- @return any @When this method returns, contains the value associated with the specified key, if the key is found; otherwise, `nil`.
function Dictionary:TryGetValue(key)
    assert(key ~= nil, "Bad argument #1 to 'TryGetValue': 'key' cannot be a nil value.");
    local index = self:_FindKeyIndex(key);
    if (index ~= nil) then
        return true, self.Values.source[index];
    else
        return false, nil;
    end
end

-- *********************************************************************************************************************
-- ** Export
-- *********************************************************************************************************************

Linq.Dictionary = Dictionary;
