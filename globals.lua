Mixin = Mixin or function(object, ...)
    for i = 1, select("#", ...) do
        local mixin = select(i, ...);
        for k, v in pairs(mixin) do object[k] = v; end
    end
    return object;
end;

wipe = wipe or function(table) for key, _ in pairs(table) do table[key] = nil; end end
