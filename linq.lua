local Linq;

if (LibStub) then
    local MAJOR, MINOR = "Linq", 1;
    Linq = LibStub:NewLibrary(MAJOR, MINOR);
else
    require "globals";
    Linq = {};
end

local wrap, yield = coroutine.wrap, coroutine.yield;
local next = next;

-- *********************************************************************************************************************
-- ** Helpers
-- *********************************************************************************************************************

local function equalityComparer(item1, item2) return item1 == item2; end

local function defaultSort(item1, item2)
    if (item1 == item2) then
        return 0;
    else
        return item1 < item2 and -1 or 1;
    end
end

local function alwaysTrue() return true; end

local function defaultGrouping(key, elements) return {Key = key, Values = elements}; end

local function noTransform(value) return value; end

local Set = {
    Add = function(self, item)
        assert(item ~= nil, "Bad argument #1 to 'Add': 'item' cannot be a nil value.");

        if (self.Comparer) then
            for _, value in pairs(self.source) do
                if (self.Comparer(value, item)) then
                    -- The item already exists in the set
                    return false;
                end
            end
            -- This item does not exist in the set
            table.insert(self.source, item);
            self.Length = self.Length + 1;
            return true;
        else
            if (self.source[item]) then
                -- The item already exists in the set
                return false;
            else
                -- This item does not exist in the set
                self.source[item] = true;
                self.Length = self.Length + 1;
                return true;
            end
        end
    end,
};

-- *********************************************************************************************************************
-- ** Enumerable
-- *********************************************************************************************************************

--- @class Enumerable
local Enumerable = {};

local EnumerableMT = {__index = function(t, key, ...) return Linq.Enumerable[key]; end};

-- ========================
-- == Deferred execution ==
-- ========================

--- Appends a value to the end of the sequence.
--- @param element any @The value to append to source.
--- @return Enumerable @An {@see Enumerable} that ends with element.
function Enumerable:Append(element)
    local function getIterator()
        local getNext = self.getIterator();

        local appended = false;
        local maxIndex = 1;
        return function()
            if (appended) then
                -- We already reached the end of the sequence
                return;
            end

            local key, value = getNext();
            if (key ~= nil) then
                if type(key) == "number" and key > maxIndex then maxIndex = key + 1; end
                return key, value;
            else
                appended = true;
                return maxIndex, element;
            end
        end
    end

    return setmetatable({getIterator = getIterator}, EnumerableMT);
end

--- Concatenates two sequences.
--- @param second table|Enumerable @The sequence to concatenate to the first sequence.
--- @return Enumerable @An {@see Enumerable} that contains the concatenated elements of the two input sequences.
function Enumerable:Concat(second)
    local function getIterator()
        local getNext = self.getIterator();
        local secondNext = Enumerable.IsEnumerable(second) and second:GetEnumerator() or next;

        local finished = false;
        local appending = false;
        local maxIndex = 1;
        local key2, value2;
        return function()
            if (finished) then
                -- We already reached the end of both sequences
                return;
            end

            if (not appending) then
                local key, value = getNext();
                if (key ~= nil) then
                    if type(key) == "number" and key > maxIndex then maxIndex = key; end
                    return key, value;
                else
                    appending = true;
                end
            end

            if (appending) then
                key2, value2 = secondNext(second, key2);
                if (key2 ~= nil) then
                    maxIndex = maxIndex + 1;
                    return maxIndex, value2;
                else
                    finished = true;
                end
            end
        end
    end

    return setmetatable({getIterator = getIterator}, EnumerableMT);
end

--- Returns the elements of the specified sequence or the specified value in a singleton collection if the sequence is empty.
--- @param defaultValue any @The value to return if the sequence is empty.
--- @return Enumerable @An {@see Enumerable} that contains defaultValue if source is empty; otherwise, source.
function Enumerable:DefaultIfEmpty(defaultValue)
    local function getIterator()
        local getNext = self.getIterator();

        local isEmpty = true;
        return function()
            local key, value = getNext();

            if (key == nil and isEmpty) then key, value = 1, defaultValue; end

            isEmpty = false;
            return key, value;
        end
    end

    return setmetatable({getIterator = getIterator}, EnumerableMT);
end

--- Returns distinct elements from a sequence by using the given comparer or the default equality comparer to compare values.
--- @param comparer function|nil @A comparer to compare values, or nil to use the default equality comparer.
--- @return Enumerable @An {@see Enumerable} that contains distinct elements from the source sequence.
function Enumerable:Distinct(comparer)
    local function getIterator()
        local getNext = self.getIterator();

        local set = Mixin({Comparer = comparer, Length = 0, source = {}}, Set);
        return function()
            local key, value = getNext();
            while (key ~= nil) do
                if (set:Add(value)) then
                    return key, value;
                else
                    key, value = getNext();
                end
            end
        end
    end

    return setmetatable({getIterator = getIterator}, EnumerableMT);
end

--- Produces the set difference of two sequences.
---
--- **Remarks:**
---
--- The set difference of two sets is defined as the members of the first set that don't appear in the second set.
---
--- This method returns those elements in first that don't appear in second. It doesn't return those elements in second that don't appear in first. Only unique elements are returned.
---
--- @param second table|Enumerable @A table whose elements that also occur in the first sequence will cause those elements to be removed from the returned sequence.
--- @param comparer function|nil @A comparer to compare values, or nil to use the default equality comparer.
--- @return Enumerable @An {@see Enumerable} that contains the set difference of the elements of two sequences.
function Enumerable:Except(second, comparer)
    comparer = comparer or equalityComparer;

    local function getIterator()
        local getNext = self.getIterator();
        local secondArray = Enumerable.IsEnumerable(second) and second:ToArray() or second;

        return function()
            local key, value = getNext();
            while (key ~= nil) do
                local ignore = false;
                for _, exceptValue in pairs(secondArray) do
                    if (comparer(exceptValue, value)) then
                        -- This is a restricted value
                        ignore = true;
                        break
                    end
                end

                if (ignore) then
                    -- There is a restricted value, ignore this item an go to the next
                    key, value = getNext();
                else
                    return key, value;
                end
            end
        end
    end

    return setmetatable({getIterator = getIterator}, EnumerableMT);
end

--- Groups the elements of a sequence according to a specified key selector function and creates a result value from each group and its key.
--- Key values can be compared by using a specified comparer, and the elements of each group can be projected by using a specified function.
--- @param keySelector function @A function to extract the key for each element.
--- @param elementSelector function @A function to map each source element to an element in a grouping.
--- @param resultSelector function|nil @A function to create a result value from each group, or nil to return the list of elements.
--- @param comparer function|nil @A function to compare keys with, or nil to use the default equality comparer.
--- @return Enumerable @An {@see Enumerable} where each element represents a projection over a group and its key.
function Enumerable:GroupBy(keySelector, elementSelector, resultSelector, comparer)
    resultSelector = resultSelector or defaultGrouping;
    comparer = comparer or equalityComparer;

    local function getIterator()
        -- This is non-streaming so we need to process all the results first
        local groups = {};
        for _, value in self:GetEnumerator() do
            local key = keySelector(value);
            local element = elementSelector(value);

            if (comparer ~= equalityComparer) then
                -- Select the key using the comparer
                for k, _ in pairs(groups) do if (comparer(k, key)) then key = k; end end
            end

            groups[key] = groups[key] or {};
            table.insert(groups[key], element);
        end

        local key, value = nil, nil;
        return function()
            key, value = next(groups, key);
            if (key ~= nil) then return key, resultSelector(key, value); end
        end
    end

    return setmetatable({getIterator = getIterator}, EnumerableMT);
end

--- Correlates the elements of two sequences based on key equality and groups the results.
--- @param inner table|Enumerable @The sequence to join to the first sequence.
--- @param outerKeySelector function @A function to extract the join key from each element of the first sequence.
--- @param innerKeySelector function @A function to extract the join key from each element of the second sequence.
--- @param resultSelector function @A function to create a result element from an element from the first sequence and a collection of matching elements from the second sequence.
--- @param keyComparer function|nil @A function to compare keys with, or nil to use the default equality comparer.
--- @return Enumerable @An {@see Enumerable} that contains elements that are obtained by performing a grouped join on two sequences.
function Enumerable:GroupJoin(inner, outerKeySelector, innerKeySelector, resultSelector, keyComparer)
    keyComparer = keyComparer or equalityComparer;

    local function getIterator()
        local getNext = self.getIterator();
        local innerArray = Enumerable.IsEnumerable(inner) and inner:ToArray() or inner;

        return function()
            local key, outerValue = getNext();
            if (key == nil) then return; end

            local join = {};
            for _, innerValue in pairs(innerArray) do
                if (keyComparer(outerKeySelector(outerValue), innerKeySelector(innerValue))) then
                    table.insert(join, innerValue);
                end
            end

            return key, resultSelector(outerValue, join);
        end
    end

    return setmetatable({getIterator = getIterator}, EnumerableMT);
end

--- Produces the set intersection of two sequences.
--- @param second table|Enumerable @An array whose distinct elements that also appear in the first sequence will be returned.
--- @param comparer function|nil @A function to compare values, or nil to use the default equality comparer.
--- @return Enumerable @An {@see Enumerable} that contains the elements that form the set intersection of two sequences.
function Enumerable:Intersect(second, comparer)
    comparer = comparer or equalityComparer;

    local function getIterator()
        local getNext = self.getIterator();
        local secondArray = Enumerable.IsEnumerable(second) and second:ToArray() or second;

        return function()
            local key, value = getNext();
            while (key ~= nil) do
                local ignore = true;
                for _, exceptValue in pairs(secondArray) do
                    if (comparer(exceptValue, value)) then
                        -- This value is included
                        ignore = false;
                        break
                    end
                end

                if (ignore) then
                    -- There is no included value, ignore this item an go to the next
                    key, value = getNext();
                else
                    return key, value;
                end
            end
        end
    end

    return setmetatable({getIterator = getIterator}, EnumerableMT);
end

--- Correlates the elements of two sequences based on matching keys.
--- @param inner table|Enumerable @The sequence to join to the first sequence.
--- @param outerKeySelector function @A function to extract the join key from each element of the first sequence.
--- @param innerKeySelector function @A function to extract the join key from each element of the second sequence.
--- @param resultSelector function @A function to create a result element from two matching elements.
--- @param comparer function|nil @A function to compare keys with, or nil to use the default equality comparer.
--- @return Enumerable @An {@see Enumerable} that contains elements that are obtained by performing an inner join on two sequences.
function Enumerable:Join(inner, outerKeySelector, innerKeySelector, resultSelector, comparer)
    comparer = comparer or equalityComparer;

    local function getIterator()
        local getNext = self.getIterator();
        local innerArray = Enumerable.IsEnumerable(inner) and inner:ToArray() or inner;

        local index = 0;
        local joined = {};
        local key, outerValue = getNext();
        return function()
            while (key ~= nil) do
                for _, innerValue in pairs(innerArray) do
                    if (not joined[innerValue] and comparer(outerKeySelector(outerValue), innerKeySelector(innerValue))) then
                        -- Return the result and keep the same outerValue for next iteration
                        index = index + 1;
                        joined[innerValue] = true;
                        return index, resultSelector(outerValue, innerValue);
                    end
                end

                -- Nothing was returned so we can use the next outerValue
                key, outerValue = getNext();
            end
        end
    end

    return setmetatable({getIterator = getIterator}, EnumerableMT);
end

--- Adds a value to the beginning of the sequence.
--- @param element any @The value to prepend to source.
--- @return Enumerable @An {@see Enumerable} that begins with element.
function Enumerable:Prepend(element)
    local function getIterator()
        local getNext = self.getIterator();

        local index = 1;
        local prepended = false;
        return function()
            if (prepended) then
                local key, value = getNext();
                if (key == nil) then return; end

                index = index + 1;
                return index, value;
            else
                prepended = true;
                return 1, element;
            end
        end
    end

    return setmetatable({getIterator = getIterator}, EnumerableMT);
end

--- Inverts the order of the elements in a sequence.
--- @returns Enumerable @An {@see Enumerable} whose elements correspond to those of the input sequence in reverse order.
function Enumerable:Reverse()
    local function getIterator()
        -- This is non-streaming so we need to get all the results first
        local currentResults = self:ToArray();

        local i = #currentResults;
        local key = 0;
        return function()
            if (i == 0) then return; end
            local value = currentResults[i];
            i = i - 1;
            key = key + 1;
            return key, value;
        end
    end

    return setmetatable({getIterator = getIterator}, EnumerableMT);
end

--- Projects each element of a sequence into a new form.
--- @param selector function @A transform function to apply to each source element.
--- @return Enumerable @An {@see Enumerable} whose elements are the result of invoking the transform function on each element of source.
function Enumerable:Select(selector)
    local function getIterator()
        local getNext = self.getIterator();

        return function()
            local key, value = getNext();
            if (key ~= nil) then return key, selector(value, key, self.source); end
        end
    end

    return setmetatable({getIterator = getIterator}, EnumerableMT);
end

--- Projects each element of a sequence and flattens the resulting sequences into one sequence.
--- @param collectionSelector function @A transform function to apply to each element of the input sequence.
--- @param resultSelector function|nil @A transform function to apply to each element of the intermediate sequence, or nil to do no transformation.
--- @return Enumerable @An {@see Enumerable} whose elements are the result of invoking the one-to-many transform function collectionSelector on each element of source and then mapping each of those sequence elements and their corresponding source element to a result element.
function Enumerable:SelectMany(collectionSelector, resultSelector)
    local function getIterator()
        local getNext = self.getIterator();

        local index = 0;
        local key, valueSource = getNext();
        local collectionKey;
        return function()
            while (key ~= nil) do
                local collection = collectionSelector(valueSource, key, self.source);
                local valueResult = nil;
                collectionKey, valueResult = next(collection, collectionKey);
                if (collectionKey ~= nil) then
                    index = index + 1;
                    if (resultSelector) then
                        return index, resultSelector(valueSource, valueResult);
                    else
                        return index, valueResult;
                    end
                end

                if (collectionKey == nil) then
                    -- We go to the next item only if we have finished returning the collection
                    key, valueSource = getNext();
                end
            end
        end
    end

    return setmetatable({getIterator = getIterator}, EnumerableMT);
end

--- Bypasses a specified number of elements in a sequence and then returns the remaining elements.
--- @param count number @The number of elements to skip before returning the remaining elements.
--- @return Enumerable @An {@see Enumerable} that contains the elements that occur after the specified index in the input sequence.
function Enumerable:Skip(count)
    local function getIterator()
        local getNext = self.getIterator();

        local index = 1;
        return function()
            local key, value = getNext();
            while (key ~= nil) do
                if (index > count) then
                    return key, value;
                else
                    index = index + 1;
                    key, value = getNext();
                end
            end
        end
    end

    return setmetatable({getIterator = getIterator}, EnumerableMT);
end

--- Bypasses elements in a sequence as long as a specified condition is true and then returns the remaining elements.
--- @param predicate number @A function to test each element for a condition.
--- @return Enumerable @An {@see Enumerable} that contains the elements from the input sequence starting at the first element in the linear series that does not pass the test specified by `predicate`.
function Enumerable:SkipWhile(predicate)
    local function getIterator()
        local getNext = self.getIterator();

        local skipping = true;
        return function()
            local key, value = getNext();
            while (key ~= nil) do
                if (skipping) then
                    if (predicate(value, key, self.source)) then
                        skipping = false;
                    else
                        key, value = getNext();
                    end
                end

                if (not skipping) then return key, value; end
            end
        end
    end

    return setmetatable({getIterator = getIterator}, EnumerableMT);
end

--- Returns a specified number of contiguous elements from the start of a sequence.
--- @param count number @The number of elements to return.
--- @return Enumerable @An {@see Enumerable} that contains the specified number of elements from the start of the input sequence.
function Enumerable:Take(count)
    local function getIterator()
        local getNext = self.getIterator();

        local index = 1;
        return function()
            if (index > count) then return; end

            local key, value = getNext();
            while (key ~= nil) do
                if (index <= count) then
                    index = index + 1;
                    return key, value;
                else
                    return;
                end
            end
        end
    end

    return setmetatable({getIterator = getIterator}, EnumerableMT);
end

--- Returns elements from a sequence as long as a specified condition is true, and then skips the remaining elements.
--- @param predicate number @A function to test each element for a condition.
--- @return Enumerable @An {@see Enumerable} that contains the elements from the input sequence that occur before the element at which the test no longer passes.
function Enumerable:TakeWhile(predicate)
    local function getIterator()
        local getNext = self.getIterator();

        local taking = true;
        return function()
            if (not taking) then return; end

            local key, value = getNext();
            if (key ~= nil) then
                if (not predicate(value, key, self.source)) then
                    taking = false;
                    return;
                else
                    return key, value;
                end
            end
        end
    end

    return setmetatable({getIterator = getIterator}, EnumerableMT);
end

--- Filters a sequence of values based on a predicate.
--- @param predicate function @A function to test each element for a condition.
--- @return Enumerable @An {@see Enumerable} that contains elements from the input sequence that satify the condition.
function Enumerable:Where(predicate)
    local function getIterator()
        local getNext = self.getIterator();

        return function()
            local key, value = getNext();
            while (key ~= nil) do
                if (predicate(value, key, self.source)) then
                    return key, value;
                else
                    key, value = getNext();
                end
            end
        end
    end

    return setmetatable({getIterator = getIterator}, EnumerableMT);
end

--- Produces the set union of two sequences.
---
--- @param second table|Enumerable @An array whose distinct elements form the second set for the union.
--- @param comparer function|nil @A comparer to compare values, or nil to use the default equality comparer.
--- @return Enumerable @An {@see Enumerable} that contains the elements from both input sequences, excluding duplicates.
function Enumerable:Union(second, comparer)
    local function getIterator()
        local getNext = self.getIterator();
        local secondNext = Enumerable.IsEnumerable(second) and second:GetEnumerator() or next;

        local set = Mixin({Comparer = comparer, Length = 0, source = {}}, Set);
        local appending = false;
        local index = 0;
        local keySecond;
        return function()
            local key, value;
            repeat
                if (not appending) then
                    key, value = getNext();
                    if (key ~= nil) then
                        if (set:Add(value)) then
                            index = index + 1;
                            return index, value;
                        end
                    else
                        appending = true;
                    end
                end

                if (appending) then
                    keySecond, value = secondNext(second, keySecond);
                    if (keySecond ~= nil) then
                        if (set:Add(value)) then
                            index = index + 1;
                            return index, value;
                        end
                    else
                        -- We reached the end of both sequences
                        return;
                    end
                end
            until (key == nil and keySecond == nil)
        end
    end

    return setmetatable({getIterator = getIterator}, EnumerableMT);
end

--- Produces a sequence of tuples with elements from the two specified sequences.
--- Applies the specified function, if provided, to the resulting tuples.
--- @param second table|Enumerable @The second sequence to merge.
--- @param resultSelector function|nil @A function that specifies how to merge the elements from the two sequences, or `nil` to return the tuple.
--- @return Enumerable @An {@see Enumerable} of tuples with elements taken from the first and second sequences, in that order, or apply the given function on the elements to produce the result.
function Enumerable:Zip(second, resultSelector)
    local function getIterator()
        local getNext = self.getIterator();
        local secondNext = Enumerable.IsEnumerable(second) and second:GetEnumerator() or next;

        local index = 0;
        local keySecond, valueSecond;
        return function()
            local key, value = getNext();
            keySecond, valueSecond = secondNext(second, keySecond);
            if (key ~= nil and keySecond ~= nil) then
                index = index + 1;
                return index, resultSelector and resultSelector(value, valueSecond) or {value, valueSecond};
            end
        end
    end

    return setmetatable({getIterator = getIterator}, EnumerableMT);
end

-- =========================
-- == Immediate execution ==
-- =========================

--- Applies an accumulator function over a sequence. The specified seed value is used as the initial accumulator value.
--- @param seed any @The initial accumulator value.
--- @param func function @An accumulator function to be invoked on each element.
--- @return any @The final accumulator value.
function Enumerable:Aggregate(seed, func)
    for key, item in self:GetEnumerator() do seed = func(seed, item, key, self.source); end
    return seed;
end

--- Determines whether all elements of a sequence satisfy a condition.
--- @param predicate function @A function to test each element for a condition.
--- @return boolean @`true` if every element of the source sequence passes the test in the specified predicate, or if the sequence is empty; otherwise, `false`.
function Enumerable:All(predicate)
    for key, item in self:GetEnumerator() do if (not predicate(item, key, self.source)) then return false; end end

    return true;
end

--- Determines whether any element of a sequence exists or satisfies a condition.
--- @param predicate function|nil @A function to test each element for a condition; or nil to test if the source sequence contains any element.
--- @return boolean @`true` if any elements in the source sequence pass the test in the specified predicate; otherwise, `false`.
function Enumerable:Any(predicate)
    for key, item in self:GetEnumerator() do
        if (not predicate or predicate(item, key, self.source)) then return true; end
    end

    return false;
end

--- Computes the average of a sequence of Single values.
--- @param selector function|nil @A transform function to apply to each element, or nil to use the element itself.
--- @return number @The average of the sequence of values, or `NaN` if the sequence contains no element.
function Enumerable:Average(selector)
    local count, sum = 0, 0;
    for _, item in self:GetEnumerator() do
        count = count + 1;
        sum = sum + (selector and selector(item) or item);
    end

    return sum / count;
end

--- Determines whether a sequence contains a specified element.
--- @param value any @The value to locate in the sequence.
--- @param comparer function|nil @A comparer to compare values, or nil to use the default equality comparer.
--- @return boolean @`true` if the source sequence contains an element that has the specified value; otherwise, `false`.
function Enumerable:Contains(value, comparer)
    comparer = comparer or equalityComparer;
    for _, item in self:GetEnumerator() do if (comparer(value, item)) then return true; end end

    return false;
end

--- Returns the number of elements in a sequence or a number that represents how many elements in the specified sequence satisfy a condition.
--- @param predicate function|nil @A function to test each element for a condition, or nil to count all elements.
--- @return number @The number of elements in the input sequence or a number that represents how many elements in the sequence satisfy the condition in the predicate function.
function Enumerable:Count(predicate)
    predicate = predicate or alwaysTrue;

    local count = 0;
    for key, item in self:GetEnumerator() do if (predicate(item, key, self.source)) then count = count + 1; end end

    return count;
end

--- Returns the element at a specified index in a sequence.
--- @param index any @The one-based index of the element to retrieve.
--- @return any @The element at the specified position in the source sequence.
function Enumerable:ElementAt(index)
    assert(index >= 1, "index must be greater than zero.");

    local i = 1;
    for _, item in self:GetEnumerator() do
        if (i == index) then
            return item;
        else
            i = i + 1
        end
    end

    error("index must be lesser or equal to the number of elements in source.");
end

--- Returns the element at a specified index in a sequence or a default value if the index is out of range.
--- @param index any @The one-based index of the element to retrieve.
--- @param defaultValue any @The default value to return if the index is outside the bounds of the source sequence.
--- @return any @`defaultValue` if the index is outside the bounds of the source sequence; otherwise, the element at the specified position in the source sequence.
function Enumerable:ElementAtOrDefault(index, defaultValue)
    if (index < 1) then return defaultValue; end

    local i = 1;
    for _, item in self:GetEnumerator() do
        if (i == index) then
            return item;
        else
            i = i + 1
        end
    end

    return defaultValue;
end

--- Returns the first element of a sequence or the first element that satisfies a specified condition.
--- @param predicate function|nil @A function to test each element for a condition, or nil to return the first element.
--- @return any @The first element found in the source sequence.
function Enumerable:First(predicate)
    predicate = predicate or alwaysTrue;

    local hasElement = false;
    for key, item in self:GetEnumerator() do
        hasElement = true;
        if (predicate(item, key, self.source)) then return item; end
    end

    if (hasElement) then
        error("No element satisfy the condition.");
    else
        error("The source sequence is empty.");
    end
end

--- Returns the first element of a sequence or the first element that satisfies a specified condition, or a default value if no element is found.
--- @param defaultValue any @The default value to return if no element is found in the source sequence.
--- @param predicate function|nil @A function to test each element for a condition, or nil to return the first element.
--- @return any @The first element found in the source sequence, or `defaultValue` if no element is found.
function Enumerable:FirstOrDefault(defaultValue, predicate)
    predicate = predicate or alwaysTrue;

    for key, item in self:GetEnumerator() do if (predicate(item, key, self.source)) then return item; end end

    return defaultValue;
end

--- Returns the last element of a sequence or the last element that satisfies a specified condition.
--- @param predicate function|nil @A function to test each element for a condition, or nil to return the last element.
--- @return any @The last element found in the source sequence.
function Enumerable:Last(predicate)
    predicate = predicate or alwaysTrue;

    local hasElement = false;
    local lastKey, lastValue = nil, nil;
    for key, item in self:GetEnumerator() do
        hasElement = true;
        if (predicate(item, key, self.source)) then lastKey, lastValue = key, item; end
    end

    if (lastKey ~= nil) then return lastValue; end

    if (hasElement) then
        error("No element satisfy the condition.");
    else
        error("The source sequence is empty.");
    end
end

--- Returns the last element of a sequence or the last element that satisfies a specified condition, or a default value if no element is found.
--- @param defaultValue any @The default value to return if no element is found in the source sequence.
--- @param predicate function|nil @A function to test each element for a condition, or nil to return the last element.
--- @return any @The last element found in the source sequence, or `defaultValue` if no element is found.
function Enumerable:LastOrDefault(defaultValue, predicate)
    predicate = predicate or alwaysTrue;

    local lastKey, lastValue = nil, nil;
    for key, item in self:GetEnumerator() do
        if (predicate(item, key, self.source)) then lastKey, lastValue = key, item; end
    end

    if (lastKey ~= nil) then return lastValue; end

    return defaultValue;
end

--- Returns the maximum value in a sequence of values.
--- @param transform function @A transform function to apply to each element, or nil to use the element itself.
--- @return number @The maximum value in the sequence.
function Enumerable:Max(transform)
    transform = transform or noTransform;

    local max = nil;
    for _, item in self:GetEnumerator() do
        local value = transform(item);
        if (max == nil or value > max) then max = value; end
    end

    if (max == nil) then error("Sequence contains no elements"); end

    return max;
end

--- Returns the minimum value in a sequence of values.
--- @param transform function @A transform function to apply to each element, or nil to use the element itself.
--- @return number @The minimum value in the sequence.
function Enumerable:Min(transform)
    transform = transform or noTransform;

    local min = nil;
    for _, item in self:GetEnumerator() do
        local value = transform(item);
        if (min == nil or value < min) then min = value; end
    end

    if (min == nil) then error("Sequence contains no elements"); end

    return min;
end

--- Determines whether two sequences are equal according to an equality comparer.
--- @param second table|Enumerable @An array to compare to the first sequence.
--- @param comparer function|nil @A comparer to compare values, or nil to use the default equality comparer.
--- @return boolean @`true` if the two source sequences are of equal length and their corresponding elements compare equal; otherwise, `false`.
function Enumerable:SequenceEqual(second, comparer)
    comparer = comparer or equalityComparer;

    second = Enumerable.IsEnumerable(second) and second:ToTable() or second;

    for key, item in self:GetEnumerator() do if (not comparer(item, second[key])) then return false; end end

    return true;
end

--- Returns a single, specific element of a sequence.
--- @param predicate function|nil @A function to test each element for a condition, or nil to return any element.
--- @return any @The single element of the input sequence that satisfies a condition.
function Enumerable:Single(predicate)
    predicate = predicate or alwaysTrue;

    local hasResult = false;
    local result;
    local hasElement = false;
    for key, item in self:GetEnumerator() do
        hasElement = true;
        if (predicate(item, key, self.source)) then
            if (not hasResult) then
                hasResult = true;
                result = item;
            else
                if (predicate == alwaysTrue) then
                    error("The sequence contain more than one element.");
                else
                    error("More than one element satisfies the condition in predicate.");
                end
            end
        end
    end

    if (hasResult) then
        return result;
    elseif (hasElement) then
        error("No element satisfy the condition.");
    else
        error("The source sequence is empty.");
    end
end

--- Returns a single, specific element of a sequence, or a default value if that element is not found.
--- @param defaultValue any @The default value to return if no element is found in the source sequence.
--- @param predicate function|nil @A function to test each element for a condition, or nil to return any element.
--- @return any @The single element found in the input sequence, or `defaultValue` if no element is found.
function Enumerable:SingleOrDefault(defaultValue, predicate)
    predicate = predicate or alwaysTrue;

    local hasResult = false;
    local result;
    for key, item in self:GetEnumerator() do
        if (predicate(item, key, self.source)) then
            if (not hasResult) then
                hasResult = true;
                result = item;
            else
                if (predicate == alwaysTrue) then
                    error("The sequence contain more than one element.");
                else
                    error("More than one element satisfies the condition in predicate.");
                end
            end
        end
    end

    if (hasResult) then
        return result;
    else
        return defaultValue;
    end
end

--- Computes the sum of a sequence of numeric values.
--- @param transform function @A transform function to apply to each element, or nil to use the element itself.
--- @return number @The sum of the values in the sequence..
function Enumerable:Sum(transform)
    transform = transform or noTransform;

    local sum = 0;
    for _, item in self:GetEnumerator() do
        local value = transform(item);
        sum = value and sum + value or sum;
    end

    return sum;
end

--- Creates an index-value pairs array. The index starts at 1 and is incremented by 1 for each element.
--- @return table @An array that contains the elements from the input sequence.
function Enumerable:ToArray()
    local result = {};
    for _, item in self:GetEnumerator() do table.insert(result, item); end
    return result;
end

-- --- Creates a dictionary.
-- --- @return table @A dictionary that contains values selected from the input sequence.
-- function Enumerable:ToDictionary(keySelector, elementSelector, comparer)
-- end

--- Creates a {@see HashSet} from an {@see Enumerable}.
--- @param comparer function|nil @The function to use when comparing values in the set, or `nil` to use the default equality comparer.
--- @return HashSet @A {@see HashSet} that contains values selected from the input sequence.
function Enumerable:ToHashSet(comparer)
    assert(Linq.HashSet, "'Linq.HashSet' has not been imported.");
    return Linq.HashSet.New(self:ToArray(), comparer);
end

--- Creates a {@see List} from an {@see Enumerable}.
--- @return List @A {@see List} that contains elements from the input sequence.
function Enumerable:ToList()
    assert(Linq.List, "'Linq.List' has not been imported.");
    return Linq.List.New(self:ToArray());
end

--- Creates a key-value pairs table. Key order is unspecified.
---
--- This method tries to keep the same keys from the original table but this is not guaranteed depending on the operations that were executed previously.
--- @return table @An array that contains the elements from the input sequence.
function Enumerable:ToTable()
    local result = {};
    for key, item in self:GetEnumerator() do result[key] = item; end
    return result;
end

-- =============
-- == Statics ==
-- =============

--- Returns an empty {@see Enumerable}.
--- @return Enumerable @An empty {@see Enumerable}.
function Enumerable.Empty() return Linq.ReadOnlyCollection.New(); end

--- Returns an {@see Enumerable} using the given array.
--- @param source table|Enumerable @The array to use to initialize the {@see Enumerable}.
--- @return Enumerable @An empty {@see Enumerable}.
function Enumerable.From(source)
    assert(type(source) == "table", "source is not an array.");
    return Linq.ReadOnlyCollection.New(source);
end

--- Determines whether an object is a valid {@see Enumerable}.
--- @param object any @The object to evaluate.
--- @return boolean @`true` if the given object is an {@see Enumerable}; otherwise, `false`.
function Enumerable.IsEnumerable(object)
    return type(object) == "table" and object.GetEnumerator == Enumerable.GetEnumerator;
end

--- Generates a sequence of integral numbers within a specified range.
--- @param start number @The value of the first integer in the sequence.
--- @param count number @The number of sequential integers to generate.
--- @return Enumerable @An {@see Enumerable} that contains a range of sequential integral numbers.
function Enumerable.Range(start, count)
    assert(count >= 0, "count is less than 0.");
    local t = {};
    for i = start, start + count - 1 do table.insert(t, i); end
    return Linq.ReadOnlyCollection.New(t);
end

--- Generates a sequence that contains one repeated value.
--- @param element any @The value to be repeated.
--- @param count number @The number of times to repeat the value in the generated sequence.
--- @return Enumerable @An {@see Enumerable} that contains a repeated value.
function Enumerable.Repeat(element, count)
    assert(count >= 0, "count is less than 0.");
    local t = {};
    for _ = 1, count do table.insert(t, element); end
    return Linq.ReadOnlyCollection.New(t);
end

-- =============
-- == Private ==
-- =============

function Enumerable:_Enumerate()
    local iterator = self.getIterator();

    repeat
        local key, value = iterator();
        if (key ~= nil) then yield(key, value); end
    until (key == nil)
end

function Enumerable:GetEnumerator()
    -- Using wrap and yield as an iterator: https://www.lua.org/pil/9.3.html
    return wrap(function() self:_Enumerate(); end);
end

-- *********************************************************************************************************************
-- ** OrderedEnumerable
-- *********************************************************************************************************************

local function sortIterator(self, comparator)
    return function()
        -- This is non-streaming so we need to get all the results first
        local currentResults = self:ToArray();

        -- Apply the sort
        table.sort(currentResults, function(item1, item2) return comparator(item1, item2) < 0; end);

        -- Return the enumerator
        local count = #currentResults;
        local key = 0;
        return function()
            if (key == count) then return; end
            key = key + 1;
            return key, currentResults[key];
        end
    end
end

--- Sorts the elements of a sequence in ascending order according to a key, using the given comparer or the default sort comparer.
--- @param keySelector function @A function to extract a key from an element.
--- @param comparer function|nil @A function to compare values, or `nil` to use the default sort comparer.
--- @return OrderedEnumerable @An {@see OrderedEnumerable} whose elements are sorted according to a key.
function Enumerable:OrderBy(keySelector, comparer)
    comparer = comparer or defaultSort;

    local function comparator(item1, item2) return comparer(keySelector(item1), keySelector(item2)); end

    return setmetatable(
               {getIterator = sortIterator(self, comparator), enumerable = self, comparator = comparator},
               {__index = function(t, key, ...) return Linq.OrderedEnumerable[key]; end}
           );
end

--- Sorts the elements of a sequence in descending order according to a key, using the given comparer or the default sort comparer.
--- @param keySelector function @A function to extract a key from an element.
--- @param comparer function|nil @A function to compare values, or nil to use the default sort comparer.
--- @return OrderedEnumerable @An {@see OrderedEnumerable} whose elements are sorted according to a key.
function Enumerable:OrderByDescending(keySelector, comparer)
    comparer = comparer or defaultSort;

    local function comparator(item1, item2) return comparer(keySelector(item2), keySelector(item1)); end

    return setmetatable(
               {getIterator = sortIterator(self, comparator), enumerable = self, comparator = comparator},
               {__index = function(t, key, ...) return Linq.OrderedEnumerable[key]; end}
           );
end

--- @class OrderedEnumerable : Enumerable
local OrderedEnumerable = {};

local OrderedEnumerableMT = {__index = function(t, key, ...) return Linq.OrderedEnumerable[key]; end};

Mixin(OrderedEnumerable, Enumerable);

--- Performs a subsequent ordering of the elements in a sequence in ascending order.
--- @param keySelector function @A function to extract a key from an element.
--- @param comparer function|nil @A function to compare values, or nil to use the default equality comparer.
--- @return OrderedEnumerable @An {@see OrderedEnumerable} whose elements are sorted according to a key.
function OrderedEnumerable:ThenBy(keySelector, comparer)
    comparer = comparer or defaultSort;

    local function comparator(item1, item2)
        local prevCompare = self.comparator(item1, item2);
        if (prevCompare == 0) then
            return comparer(keySelector(item1), keySelector(item2));
        else
            return prevCompare;
        end
    end

    local enumerable = self.enumerable;

    return setmetatable(
               {getIterator = sortIterator(enumerable, comparator), enumerable = enumerable, comparator = comparator},
               OrderedEnumerableMT
           );
end

--- Performs a subsequent ordering of the elements in a sequence in descending order.
--- @param keySelector function @A function to extract a key from an element.
--- @param comparer function|nil @A function to compare values, or nil to use the default equality comparer.
--- @return OrderedEnumerable @An {@see OrderedEnumerable} whose elements are sorted according to a key.
function OrderedEnumerable:ThenByDescending(keySelector, comparer)
    comparer = comparer or defaultSort;

    local function comparator(item1, item2)
        local prevCompare = self.comparator(item1, item2);
        if (prevCompare == 0) then
            return comparer(keySelector(item2), keySelector(item1));
        else
            return prevCompare;
        end
    end

    local enumerable = self.enumerable;

    return setmetatable(
               {getIterator = sortIterator(enumerable, comparator), enumerable = enumerable, comparator = comparator},
               OrderedEnumerableMT
           );
end

-- *********************************************************************************************************************
-- ** ReadOnlyCollection
-- *********************************************************************************************************************

--- @class ReadOnlyCollection : Enumerable
local ReadOnlyCollection = {};

local ReadOnlyCollectionMT = {
    __index = function(t, key, ...) return ReadOnlyCollection[key] or Linq.Enumerable[key]; end,
};

--- Initializes a new instance of the {@see ReadOnlyCollection} class.
--- @param source table|nil
--- @return ReadOnlyCollection @The new instance of {@see ReadOnlyCollection}.
function ReadOnlyCollection.New(source)
    assert(source == nil or type(source) == "table");

    local collection = setmetatable({}, ReadOnlyCollectionMT);

    source = Enumerable.IsEnumerable(source) and source:ToTable() or source;
    collection.source = source or {};

    collection:_ArrayIterator();

    return collection;
end

--- Iterates over all the elements in an array.
function ReadOnlyCollection:_ArrayIterator()
    local function getIterator()
        local key, value;
        return function()
            key, value = next(self.source, key);
            return key, value;
        end
    end

    self.getIterator = getIterator;
end

-- *********************************************************************************************************************
-- ** Export
-- *********************************************************************************************************************

Linq.Enumerable = Enumerable;
Linq.OrderedEnumerable = OrderedEnumerable;
Linq.ReadOnlyCollection = ReadOnlyCollection;
Linq._Set = Set;

return Linq;
