--[[
    Lua Serializer (Value-To-Code)
    Author: James Heinemann
    Version: 0.2
    File: serializer.lua
    Creation Date: 10-20-2020
    Description: Adapted from another project, this module provides an API to convert Lua
                 values back into code for debugging purposes. Works with every value except
                 userdata and functions (will simply assign placeholder values).
]]

--- number of spaces to indent code
local indent = 4
local settings = {}

--- value-to-string: value, string (out), level (indentation), parent table, var name, is from tovar
function v2s(v, l, p, n, vtv, i, pt, path, tables)
    if type(v) == "number" then
        if v == math.huge then
            return "math.huge"
        end
        return tostring(v)
    elseif type(v) == "boolean" then
        return tostring(v)
    elseif type(v) == "string" then
        return formatstr(v)
    elseif type(v) == "function" then
        return f2s(v)
    elseif type(v) == "table" then
        return t2s(v, l, p, n, vtv, i, pt, path, tables)
    elseif type(v) == "userdata" then
        return "newproxy(true) --[[ Unknown userdata ]]"
    else
        return "nil --[[" .. tostring(v) .. "]]"
    end
end

--- value-to-variable
--- @param t any
function v2v(t)
    topstr = ""
    bottomstr = ""
    local ret = ""
    local count = 1
    for i, v in pairs(t) do
        if type(i) == "string" and i:match("^[%a_]+[%w_]*$") then
            ret = ret .. "local " .. i .. " = " .. v2s(v, nil, nil, i, true) .. "\n"
        elseif tostring(i):match("^[%a_]+[%w_]*$") then
            ret = ret .. "local " .. tostring(i):lower() .. "_" .. tostring(count) .. " = " .. v2s(v, nil, nil, tostring(i):lower() .. "_" .. tostring(count), true) .. "\n"
        else
            ret = ret .. "local " .. type(v) .. "_" .. tostring(count) .. " = " .. v2s(v, nil, nil, type(v) .. "_" .. tostring(count), true) .. "\n"
        end
        count = count + 1
    end
    if #topstr > 0 then
        ret = topstr .. "\n" .. ret
    end
    if #bottomstr > 0 then
        ret = ret .. bottomstr
    end
    return ret
end

--- table-to-string
--- @param t table
--- @param l number
--- @param p table
--- @param n string
--- @param vtv boolean
--- @param i any
--- @param pt table
--- @param path string
--- @param tables table
function t2s(t, l, p, n, vtv, i, pt, path, tables)
    if not path then
        path = ""
    end
    if not l then
        l = 0
        tables = {}
    end
    if not p then
        p = t
    end
    for _, v in pairs(tables) do
        if n and rawequal(v, t) then
            bottomstr = bottomstr .. "\n" .. tostring(n) .. tostring(path) .. " = " .. tostring(n) .. tostring(({v2p(v, p)})[2])
            return "{} --[[DUPLICATE]]"
        end
    end
    table.insert(tables, t)
    local s =  "{"
    local size = 0
    l = l + indent
    for k, v in pairs(t) do
        size = size + 1
        if rawequal(k, t) then -- checks if the table being iterated over is being used as an index within itself (yay, lua)
            bottomstr = bottomstr .. "\n" .. tostring(n) .. tostring(path) .. "[" .. tostring(n) .. tostring(path) .. "]" .. " = " .. (rawequal(v, k) and tostring(n) .. tostring(path) or v2s(v, l, p, n, vtv, k, t, path .. "[" .. tostring(n) .. tostring(path) .. "]", tables))
            size = size - 1
        else
            local currentPath = ""
            if type(k) == "string" and k:match("^[%a_]+[%w_]*$") then
                currentPath = "." .. k
            else
                currentPath = "[" .. v2s(k, nil, p, n, vtv, i, pt, path) .. "]"
            end
            s = s .. "\n" .. string.rep(" ", l) .. "[" .. v2s(k, l, p, n, vtv, k, t, path .. currentPath, tables) .. "] = " .. v2s(v, l, p, n, vtv, k, t, path .. currentPath, tables) .. ","
        end
    end
    if #s > 1 then
        s = s:sub(1, #s - 1)
    end
    if size > 0 then
        s = s .. "\n" .. string.rep(" ", l - indent)
    end
    return s .. "}"
end

--- function-to-string
function f2s(f)
    if debug.getinfo(f).name:match("%w") then
        return "function()end --[[" .. debug.getinfo(f).name .. "]]"
    end
    return "function()end"
end

--- value-to-path (in table)
function v2p(x, t, path, prev)
    if not path then
        path = ""
    end
    if not prev then
        prev = {}
    end
    if rawequal(x, t) then
        return true, ""
    end
    for i, v in pairs(t) do
        if rawequal(v, x) then
            if type(i) == "string" and i:match("^[%a_]+[%w_]*$") then
                return true, (path .. "." .. i)
            else
                return true, (path .. "[" .. v2s(i) .. "]")
            end
        end
        if type(v) == "table" then
            local duplicate = false
            for _, y in pairs(prev) do
                if rawequal(y, v) then
                    duplicate = true
                end
            end
            if not duplicate then
                table.insert(prev, t)
                local found
                found, p = v2p(x, v, path, prev)
                if found then
                    if type(i) == "string" and i:match("^[%a_]+[%w_]*$") then
                        return true, "." .. i .. p
                    else
                        return true, "[" .. v2s(i) .. "]" .. p
                    end
                end
            end
        end
    end
    return false, ""
end

--- Find iterator
function gfind(str, pattern)
    local start = 0
    return function()
        local findStart, findEnd = str:find(pattern, start)
        if findStart and findEnd ~= #str then
            start = findEnd + 1
            return findStart, findEnd
        else
            return nil
        end
    end
end

--- format s: string, byte encrypt (for weird symbols)
function formatstr(s)
    return '"' .. handlespecials(s) .. '"'
end

--- Adds \'s to the text as a replacement to whitespace chars and other things because string.format can't yayeet
function handlespecials(s)
    local i = 0
    repeat
        i = i + 1
        local char = s:sub(i, i)
        if string.byte(char) then
            if char == "\n" then
                s = s:sub(0, i - 1) .. "\\n" .. s:sub(i + 1, -1)
                i = i + 1
            elseif char == "\t" then
                s = s:sub(0, i - 1) .. "\\t" .. s:sub(i + 1, -1)
                i = i + 1
            elseif char == "\\" then
                s = s:sub(0, i - 1) .. "\\" .. s:sub(i + 1, -1)
                i = i + 1
            elseif char == '"' then
                s = s:sub(0, i - 1) .. '\\"' .. s:sub(i + 1, -1)
                i = i + 1
            elseif not settings.NoFormatUnknowns and (string.byte(char) > 126 or string.byte(char) < 32) then
                s = s:sub(0, i - 1) .. "\\" .. string.byte(char) .. s:sub(i + 1, -1)
                i = i + #tostring(string.byte(char))
            end
        end
    until char == ""
    return s
end

-- returns a namespace to interact with the above functions
return {
    --- Converts the provided value to a string (recommended that `valueToVar` be used instead)
    --- @param value any
    --- @return string
    valueToString = function(_, value)
        return v2s(value)
    end,
    --- Converts the provided value to a variable, `name` argument is optional
    --- @param value any
    --- @param variablename string
    --- @return string
    valueToVar = function(_, value, variablename)
        assert(variablename == nil or type(variablename) == "string", "string expected, got " .. type(variablename))
        if not variablename then
            variablename = 1
        end
        return v2v({[variablename] = value})
    end,
    --- Converts a dictionary/array of values to a variable, when using a dictionary, the key will act as the variable name
    --- @param t table
    --- @return string
    tableToVars = function(_, t)
        assert(type(t) == "table", "table expected, got " .. type(t))
        return v2v(t)
    end,
    --- Configures the specified setting to the specified value
    --- @param name string
    --- @param v any
    configureSetting = function(_, name, v)
        assert(type(name) == "string", "string expected, got " .. type(name))
        settings[name] = v
    end
}