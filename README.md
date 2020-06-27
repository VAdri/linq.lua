# LINQ for Lua

This project is an implementation of the [LINQ](https://docs.microsoft.com/en-us/dotnet/csharp/programming-guide/concepts/linq/) system in Lua.

LINQ (Language-Integrated Query) is a library originally in the .NET framework that adds some consitent and powerful query features on enumerable types.

The aim of this project is to keep an API that is close to the original and to use the same [deferred execution](https://docs.microsoft.com/en-us/dotnet/csharp/programming-guide/concepts/linq/classification-of-standard-query-operators-by-manner-of-execution#deferred) methods with CPU and memory usage efficiency in mind.

## Usage

### Basic usage

Here is a simple example on how to import and use the library into a project:

```lua
-- Import the "Linq" namespace
local Linq = require "linq";

-- Add the "List" class into the "Linq" namespace
require "list";

-- Creates a new instance of the "List" class that is initialized with the given array
local scores = Linq.List.New({
    {Name = "Alice", Score = 84},
    {Name = "Bob", Score = 92},
    {Name = "Cathy", Score = 88}
});

-- Execute a query
local admitted = scores
    :Where(function(s) return s.Score >= 85; end)
    :Select(function(s) return s.Name; end)
    :ToArray();

-- admitted: {"Bob", "Cathy"}
```

You can also use [`LibStub`](https://www.wowace.com/projects/libstub) to use this library in an addon for the game World of Warcraft:

```bash
# MyAddon.toc

## Interface: 80300
## Title: MyAddon
## Author: Draghos
## Version: 0.0.1

# You need LibStub first
Libs/LibStub/LibStub.lua

# Import linq.lua
Libs/Linq/linq.lua

# Then import optional collections
Libs/Linq/list.lua
Libs/Linq/hashSet.lua

# Lastly import the files in which you want to use Linq
MyAddon.lua
```

```lua
-- MyAddon.lua

-- Import Linq using LibStub
local Linq = LibStub("Linq");

-- You can now use the collections you have imported and Enumerable operations
local list = Linq.List.New(Linq.Enumerable.Range(1, 5));
```

### Type inference

To get type inference, you need to install [EmmyLua](https://github.com/EmmyLua) (available on IntelliJ and VSCode) and use the following line just after the `require` statements:

```lua
local Linq = require "linq";
require "hashSet";

--- @type HashSet
local HashSet = Linq.HashSet;

-- ... use HashSet instead of Linq.HashSet
```

Sometimes EmmyLua doesn't detect inheritance, in which case you need to declare it yourself:

```lua
--- @type List|ReadOnlyCollection|Enumerable
local List = Linq.List;
```

### Defining and executing a query

The execution of queries is deferred until an operation that actually returns a result is called, and only the elements that are needed in the final result are processed.

For instance, in the following example the first `Select` is called six times (from index 1 until the end of the iteration at index 6), even though the source array has ten items, and the second `Select` is called only three times, because it is executed after the `Skip` and `Take` operations:

```lua
local initialEnumeration = 0;
local finalEnumeration = 0;

local query = Enumerable.Range(1, 10)
    :Select(function(n) initialEnumeration = initialEnumeration + 1; return n; end)
    :Skip(3)
    :Take(3)
    :Select(function(n) finalEnumeration = finalEnumeration + 1; return n; end);

-- initialEnumeration: 0
-- finalEnumeration: 0

local results = query:ToArray();

-- initialEnumeration: 6
-- finalEnumeration: 3
-- results: {4, 5, 6}
```

You can also extend and execute a query multiple times after declaring it:

```lua
local query = List.New({1, 2, 3, 4, 5})
    :Where(function(i) return i >= 2; end)
    :Skip(1);

local result;

result = query:ToArray();
-- result: {3, 4, 5}

result = query:Reverse():ToArray();
-- result: {5, 4, 3}

result = query:Skip(1):Take(1):ToArray();
-- result: {4}

result = query:Sum();
-- result: 12
```

It is possible to use another enumerable as an argument for an operation:

```lua
local first = List.New({1, 2, 3, 4, 5});
local second = List.New({6, 7, 8});

local query = Enumerable.From(first):Concat(second);

local result;

result = query:ToArray();
-- result: {1, 2, 3, 4, 5, 6, 7, 8}

second:Add(9);
result = query:ToArray();
-- result: {1, 2, 3, 4, 5, 6, 7, 8, 9}
```

### Using collections

Several collections implementing the Linq operations are provided. Each type of collection has its pros and cons but all of them can be used as enumerables.

#### ReadOnlyCollection

This is the base collection that is used when calling a method like `Linq.Enumerable.From`.

This `ReadOnlyCollection` takes a table as source and use it to perform operations but it is not possible to add, remove or modify items on it.

#### List

The `List` inherits from `ReadOnlyCollection` except that it uses a shallow copy of the source sequence and it contains some operations that allow to modify it. The source sequence is not modified by the actions performed on the list (for instance, when calling `list:Add(item)` it will add the item on the `list` instance but not on the table that was used to create the list).

#### HashSet

A `HashSet` is a collection that contains no duplicate items. The duplicate items are determined by using the equality operator (`==`) or by using a given function used as a comparator (but in this case it will be slower). The items in the set are in no particular order.

This type provides some interesting mathematical methods to add or remove items such as set additions (unions) or substractions (excepts).

#### Dictionary

The `Dictionary` is a collection of key/value pairs in which the order of elements is respected as they are added into the collection. Each key must be unique according to the default equality operator (`==`) or a comparison function.

**Note:** You need to import `List` in order to use the `Dictionary`.

### Limitations

It is not possible to call Linq methods directly on a table object, so this will throw an error:

```lua
local t = {1, 2, 3};
t:Sum(); -- Error
Enumerable.From(t):Sum(); -- Use this instead
```

## API

### Enumerable

| Name                | Immediate | Deferred |  Type  |
| ------------------- | :-------: | :------: | :----: |
| Aggregate           |     X     |          |        |
| All                 |     X     |          |        |
| Any                 |     X     |          |        |
| <s>AsEnumerable</s> |           |          |        |
| Average             |     X     |          |        |
| Concat              |           |    X     |        |
| Contains            |     X     |          |        |
| Count               |     X     |          |        |
| DefaultIfEmpty      |           |    X     |        |
| Distinct            |           |    X     |        |
| ElementAt           |     X     |          |        |
| ElementAtOrDefault  |     X     |          |        |
| Empty               |           |          | Static |
| Except              |           |    X     |        |
| First               |     X     |          |        |
| FirstOrDefault      |     X     |          |        |
| From                |           |          | Static |
| GroupBy             |           |    X     |        |
| GroupJoin           |           |    X     |        |
| Intersect           |           |    X     |        |
| Join                |           |    X     |        |
| Last                |     X     |          |        |
| LastOrDefault       |     X     |          |        |
| Max                 |     X     |          |        |
| Min                 |     X     |          |        |
| OrderBy             |           |    X     |        |
| OrderByDescending   |           |    X     |        |
| Range               |           |          | Static |
| Repeat              |           |          | Static |
| Reverse             |           |    X     |        |
| Select              |           |    X     |        |
| SelectMany          |           |    X     |        |
| Single              |     X     |          |        |
| SingleOrDefault     |     X     |          |        |
| Skip                |           |    X     |        |
| SkipWhile           |           |    X     |        |
| Sum                 |     X     |          |        |
| Take                |           |    X     |        |
| TakeWhile           |           |    X     |        |
| ToArray             |     X     |          |        |
| ToDictionary        |     X     |          |        |
| ToHashSet           |     X     |          |        |
| ToList              |     X     |          |        |
| <s>ToLookup</s>     |           |          |        |
| Union               |           |    X     |        |
| Where               |           |    X     |        |
| Zip                 |           |    X     |        |

### OrderedEnumerable

| Name             | Immediate | Deferred | Type |
| ---------------- | :-------: | :------: | :--: |
| ThenBy           |           |    X     |      |
| ThenByDescending |           |    X     |      |

### List

| Name                 | Side-effect |   Type   |
| -------------------- | :---------: | :------: |
| Add                  |     Yes     |          |
| AddRange             |     Yes     |          |
| Clear                |     Yes     |          |
| <s>Contains</s>      |             |          |
| <s>CopyTo</s>        |             |          |
| <s>Exists</s>        |             |          |
| <s>Find</s>          |             |          |
| <s>FindAll</s>       |             |          |
| <s>FindIndex</s>     |             |          |
| <s>FindLast</s>      |             |          |
| <s>FindLastIndex</s> |             |          |
| <s>ForEach</s>       |             |          |
| <s>GetRange</s>      |             |          |
| <s>IndexOf</s>       |             |          |
| <s>Insert</s>        |             |          |
| <s>InsertRange</s>   |             |          |
| <s>LastIndexOf</s>   |             |          |
| Length               |             | Property |
| New                  |             |  Static  |
| <s>Remove</s>        |             |          |
| <s>RemoveAll</s>     |             |          |
| RemoveAt             |     Yes     |          |
| <s>RemoveRange</s>   |             |          |
| <s>Reverse</s>       |             |          |
| <s>Sort</s>          |             |          |
| <s>ToArray</s>       |             |          |
| <s>TrueForAll</s>    |             |          |

### HashSet

| Name                      | Side-effect |   Type   |
| ------------------------- | :---------: | :------: |
| Add                       |     Yes     |          |
| Clear                     |     Yes     |          |
| Contains                  |             |          |
| Comparer                  |             | Property |
| <s>CopyTo</s>             |             |          |
| Length                    |             | Property |
| New                       |             |  Static  |
| Remove                    |     Yes     |          |
| <s>RemoveWhere</s>        |             |          |
| <s>IsProperSubsetOf</s>   |             |          |
| <s>IsProperSupersetOf</s> |             |          |
| <s>IsSubsetOf</s>         |             |          |
| <s>IsSupersetOf</s>       |             |          |
| <s>Overlaps</s>           |             |          |
| SymmetricExceptWith       |     Yes     |          |
| <s>TryGetValue</s>        |             |          |
| UnionWith                 |     Yes     |          |

### Dictionary

| Name          | Side-effect |   Type   |
| ------------- | :---------: | :------: |
| Add           |     Yes     |          |
| Clear         |     Yes     |          |
| ContainsKey   |             |          |
| ContainsValue |             |          |
| Comparer      |             | Property |
| Length        |             | Property |
| New           |             |  Static  |
| Keys          |             | Property |
| Remove        |     Yes     |          |
| TryAdd        |     Yes     |          |
| TryGetValue   |             |          |
| Values        |             | Property |
