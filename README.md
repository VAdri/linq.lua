# LINQ for Lua

This project is an implementation of the [LINQ](https://docs.microsoft.com/en-us/dotnet/csharp/programming-guide/concepts/linq/) system in Lua.

LINQ (Language-Integrated Query) is a library integrated in the .NET framework that adds some consitent and powerful query features on enumerable types.

The aim is to keep an API that is close to the original and to use the same [deferred execution](https://docs.microsoft.com/en-us/dotnet/csharp/programming-guide/concepts/linq/classification-of-standard-query-operators-by-manner-of-execution#deferred) methods with CPU and memory usage efficiency in mind.

## Features

### Current features

An API that is as close to the original as possible:

- `Enumerable`
- `OrderedEnumerable` (work in progress)
- `Queryable` (todo)

Implementation of the following types:

- `ReadOnlyCollection`
- `List`
- `HashSet`
- `Dictionary` (work in progress)

Chaining operations on an enumerable objects:

```lua
local admittedSudents = grades
    :Where(function (grade) return grade >= 80; end)
    :Select(function (grade) return grade.Student.Name; end)
    :ToArray();
```

Definig a query an executing it multiple times:

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

### Limitations

It is not possible to call Linq methods directly on a table object, so this will throw an error:

```lua
local t = {1, 2, 3};
t:Sum(); -- Error
```

Currently when an operation expects an array as argument it cannot get an enumberable instead:

```lua
-- This works:
local list1 = List.New({1, 2, 3});

-- But this doesn't:
local list2 = List.New(list1);
```

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
--- @type List|ReadOnlyCollection|OrderedEnumerable|Enumerable
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

## API

### Enumerable

| Name                | Immediate | Deferred | Static |
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
| Empty               |           |          |   X    |
| Except              |           |    X     |        |
| First               |     X     |          |        |
| FirstOrDefault      |     X     |          |        |
| GroupBy             |           |    X     |        |
| GroupJoin           |           |    X     |        |
| Intersect           |           |    X     |        |
| Join                |           |    X     |        |
| Last                |     X     |          |        |
| LastOrDefault       |     X     |          |        |
| Max                 |     X     |          |        |
| Min                 |     X     |          |        |
| Range               |           |          |   X    |
| Repeat              |           |          |   X    |
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
| <s>ToDictionary</s> |           |          |        |
| ToHashSet           |     X     |          |        |
| ToList              |     X     |          |        |
| <s>ToLookup</s>     |           |          |        |
| Union               |           |    X     |        |
| Where               |           |    X     |        |
| Zip                 |           |    X     |        |

### OrderedEnumerable

| Name                     | Immediate | Deferred | Static |
| ------------------------ | :-------: | :------: | :----: |
| <s>OrderBy</s>           |           |          |        |
| <s>OrderByDescending</s> |           |          |        |
| <s>ThenBy</s>            |           |          |        |
| <s>ThenByDescending</s>  |           |          |        |

### List

| Name                 | Modify | No side-effect | Static |
| -------------------- | :----: | :------------: | :----: |
| Add                  |   X    |                |        |
| AddRange             |   X    |                |        |
| Clear                |   X    |                |        |
| <s>Contains</s>      |        |                |        |
| <s>CopyTo</s>        |        |                |        |
| <s>Exists</s>        |        |                |        |
| <s>Find</s>          |        |                |        |
| <s>FindAll</s>       |        |                |        |
| <s>FindIndex</s>     |        |                |        |
| <s>FindLast</s>      |        |                |        |
| <s>FindLastIndex</s> |        |                |        |
| <s>ForEach</s>       |        |                |        |
| <s>GetEnumerator</s> |        |                |        |
| <s>GetRange</s>      |        |                |        |
| <s>IndexOf</s>       |        |                |        |
| <s>Insert</s>        |        |                |        |
| <s>InsertRange</s>   |        |                |        |
| <s>LastIndexOf</s>   |        |                |        |
| Length               |        |       X        |        |
| New                  |        |                |   X    |
| <s>Remove</s>        |        |                |        |
| <s>RemoveAll</s>     |        |                |        |
| RemoveAt             |   X    |                |        |
| <s>RemoveRange</s>   |        |                |        |
| <s>Reverse</s>       |        |                |        |
| <s>Sort</s>          |        |                |        |
| <s>ToArray</s>       |        |                |        |
| <s>TrueForAll</s>    |        |                |        |

### HashSet

| Name                      | Modify | No side-effect | Static |
| ------------------------- | :----: | :------------: | :----: |
| Add                       |   X    |                |        |
| Clear                     |   X    |                |        |
| Contains                  |        |       X        |        |
| <s>CopyTo</s>             |        |                |        |
| <s>GetEnumerator</s>      |        |                |        |
| Length                    |        |       X        |        |
| New                       |        |                |   X    |
| Remove                    |   X    |                |        |
| <s>RemoveWhere</s>        |        |                |        |
| <s>IsProperSubsetOf</s>   |        |                |        |
| <s>IsProperSupersetOf</s> |        |                |        |
| <s>IsSubsetOf</s>         |        |                |        |
| <s>IsSupersetOf</s>       |        |                |        |
| <s>Overlaps</s>           |        |                |        |
| SymmetricExceptWith       |   X    |                |        |
| <s>TryGetValue</s>        |        |                |        |
| UnionWith                 |   X    |                |        |
