--[[
    Stores utility functions used by our game engine.
]]

-- takes a texture, width, and height of tiles and splits it into quads
-- that can be individually drawn
function generateQuads(atlas, tilewidth, tileheight)
    local sheetWidth = atlas:getWidth() / tilewidth
    local sheetHeight = atlas:getHeight() / tileheight

    local sheetCounter = 1
    local quads = {}

    for y = 0, sheetHeight - 1 do
        for x = 0, sheetWidth - 1 do
            -- this quad represents a square cutout of our atlas that we can
            -- individually draw instead of the whole atlas
            quads[sheetCounter] =
                love.graphics.newQuad(x * tilewidth, y * tileheight, tilewidth,
                tileheight, atlas:getDimensions())
            sheetCounter = sheetCounter + 1
        end
    end

    return quads
end

function contains(set, key)
    return set[key] ~= nil
end

function toboolean(expr)
    return not not(expr)
end

function any(t, k)
    k = k or true
    for i, v in ipairs(t) do
        if v == k then
            return true, i
        end
    end
    return false
end

function all(t, k)
    k = k or true
    for i, v in ipairs(t) do
        if v ~= k then
            return true, i
        end
    end
end

function getiter(t)
    if table.isarray(t) then
        return ipairs
    elseif type(t) == "table" then
        return pairs
    end
    error("expected table", 3)
end

function table.isarray(t)
    return type(t) == "table" and t[1] ~= nil
end

local ripairs_iter = function(t, i)
    i = i - 1
    local v = t[i]
    if v ~= nil then
        return i, v
    end
end

function table.ripairs(t)
    return ripairs_iter, t, (#t + 1)
end

function table_remove(t, x)
    local iter = getiter(t)
    for i, v in iter(t) do
        if v == x then
            if table.isarray(t) then
                table.remove(t, i)
                break
            else
                t[i] = nil
                break
            end
        end
    end
    return x
end

function table.push(t, ...)
    local n = select("#", ...)
    for i = 1, n do
        t[#t + 1] = select(i, ...)
    end
    return ...
end

function table.update(t, ot)
    return table.push(t, (unpack or table.unpack)(ot))
end

function table.sub(tab, start, stop)
    local res = {}
    if not stop then stop, start = start, 0 end
    step = (start > stop) and -1 or 1
    for i = start, stop, step do
        table.insert(res, tab[i])
    end
    return res
end

function table.keys(tab)
    local keys = {}
    local iter = getiter(tab)
    for key in iter(tab) do
        table.insert(keys, key)
    end
    return keys
end

function table.find(t, value, ci)
    local iter = getiter(t)
    for k, v in iter(t) do
        if ci then
            v, value = string.lower(v), string.lower(value)
        end
        if v == value then return k end
    end
    return nil
end

function table.filter(t, fn, retainkeys)
    fn = iteratee(fn)
    local iter = getiter(t)
    local rtn = {}
    if retainkeys then
        for k, v in iter(t) do
            if fn(v) then rtn[k] = v end
        end
    else
        for _, v in iter(t) do
            if fn(v) then rtn[#rtn + 1] = v end
        end
    end
    return rtn
end

function table.match(t, fn)
    fn = iteratee(fn)
    local iter = getiter(t)
    for k, v in iter(t) do
        if fn(v) then return v, k end
    end
    return nil
end

function table.count(t, fn)
    local count = 0
    local iter = getiter(t)
    if fn then
        fn = iteratee(fn)
        for _, v in iter(t) do
            if fn(v) then count = count + 1 end
        end
    else
        if table.isarray(t) then
            return #t
        end
        for _ in iter(t) do count = count + 1 end
    end
    return count
end

function table.new(...)
    return {...}
end

local lambda_cache = {}

function lambda(str)
    if not lambda_cache[str] then
        local args, body = str:match([[^([%w,_ ]-)%->(.-)$]])
        assert(args and body, "bad string lambda")
        local s = "return function(" .. args .. ")\nreturn " .. body .. "\nend"
        lambda_cache[str] = dostring(s)
    end
    return lambda_cache[str]
end

function dostring(str)
    return assert((loadstring or load)(str))()
end

function table.each(t, fn, ...)
    local iter = getiter(t)
    if type(fn) == "string" then
        for _, v in iter(t) do v[fn](v, ...) end
    else
        for _, v in iter(t) do fn(v, ...) end
    end
    return t
end

function table.map(t, fn)
    fn = iteratee(fn)
    local iter = getiter(t)
    local rtn = {}
    for k, v in iter(t) do rtn[k] = fn(v) end
    return rtn
end

function table.all(t, fn)
    fn = iteratee(fn)
    local iter = getiter(t)
    for _, v in iter(t) do
        if not fn(v) then return false end
    end
    return true
end

function table.any(t, fn)
    fn = iteratee(fn)
    local iter = getiter(t)
    for k, v in iter(t) do
        if fn(v) then return k end
    end
    return false
end

function concat(...)
    local rtn = {}
    for i = 1, select("#", ...) do
        local t = select(i, ...)
        if t ~= nil then
            local iter = getiter(t)
            for _, v in iter(t) do
                rtn[#rtn + 1] = v
            end
        end
    end
    return rtn
end

function wideLineSegment(w, x1, y1, x2, y2)
    local x, y = vector.normalize(vector.perpendicular(x1 - x2, y1 - y2))

	local dx, dy = x * w / 2, y * w / 2
	return x1 - dx, y1 - dy,
	       x2 - dx, y2 - dy,
	       x1 + dx, y1 + dy,
	       x2 + dx, y2 + dy
end

function printCentered(text, x, y, width, height)
    local fw = love.graphics.getFont():getWidth(text)
    local fh = love.graphics.getFont():getHeight()
    love.graphics.print(text, x + width / 2 - fw / 2, y + height / 2 - fh / 2)
end

function table.invert(t)
    local rtn = {}
    for k, v in pairs(t) do rtn[v] = k end
    return rtn
end

function table.unique(t)
    local rtn = {}
    for k in pairs(table.invert(t)) do
        rtn[#rtn + 1] = k
    end
    return rtn
end

function fn(fn, ...)
    assert(iscallable(fn), "expected a function as the first argument")
    local args = {...}
    return function(...)
        local a = concat(args, {...})
        return fn(unpack(a))
    end
end

function iscallable(x)
    if type(x) == "function" then return true end
    local mt = getmetatable(x)
    return mt and mt.__call ~= nil
end

function iteratee(x)
    if x == nil then return function(x) return x end end
    if iscallable(x) then return x end
    if type(x) == "table" then
        return function(z)
            for k, v in pairs(x) do
                if z[k] ~= v then return false end
            end
            return true
        end
    end
    return function(z) return z[x] end
end

function table.extend(t, ...)
    for i = 1, select("#", ...) do
        local x = select(i, ...)
        if x then
            for k, v in pairs(x) do
                t[k] = v
            end
        end
    end
    return t
end

function table.contains(t, value, ci)
    return table.find(t, value, ci)
end

function release(tab)
    if type(tab) ~= 'table' then
        tab = {tab}
    end
    for _, v in pairs(tab) do
        if v.release then
            v:release()
        elseif v.collider.release then
            v.collider:release()
        end
    end
end

function get_distance(collider1, collider2)
    local fixture1 = collider1:getFixtures()[1]
    local fixture2 = collider2:getFixtures()[1]
    return love.physics.getDistance(fixture1, fixture2)
end

function math.get_distance(x1, y1, x2, y2)
    return math.sqrt(math.pow(x1 - x2, 2) + math.pow(y1 - y2, 2))
end

function table.maximum(iterable, key)
    local max = iterable[1]
    key = key or function(v) return v end
    for k, v in ipairs(iterable) do
        if key(iterable[k]) > key(max) then
            max = iterable[k]
        end
    end
    return max
end

function table.pairs_update(t1, t2)
    for k, v in pairs(t2) do
        t1[k] = v
    end
    return t1
end

function table.pairs_add(t1, t2)
    local t = {}
    for i, v in pairs(t1) do
        t[i] = v
    end
    for i, v in pairs(t2) do
        t[i] = v
    end
    return t
end

function table.add(t1, t2)
    local t = {}
    for _, v in ipairs(t1) do
        table.insert(t, v)
    end
    for _, v in ipairs(t2) do
        table.insert(t, v)
    end
    return t
end

function round(x, increment)
    if increment then return round(x / increment) * increment end
    return x >= 0 and math.floor(x + .5) or math.ceil(x - .5)
end

function table.minimum(iterable, key)
    local min = iterable[1]
    key = key or function(v) return v end
    for k, v in ipairs(iterable) do
        if key(iterable[k]) < key(min) then
            min = iterable[k]
        end
    end
    return min
end

function once(fn, ...)
    local f = fn(fn, ...)
    local done = false
    return function(...)
        if done then return end
        done = true
        return f(...)
    end
end

function split(s, delimiter)
    s = tostring(s) or ''
    delimiter = delimiter or ' '
    result = {}
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

function updatePairs(t1, t2, exceptions)
    if type(exceptions) ~= 'table' then
        exceptions = {exceptions}
    end
    for k, v in pairs(t1) do
        if (t2[k] == nil) and (table.find(exceptions, k) == nil) then
            print("adding key")
            t2[k] = v
        elseif (type(v) == 'table') and (v[1] == nil) then
            updatePairs(v, t2[k])
        end
    end
    -- for k, v in pairs(t2) do
    --     if (t1[k] == nil) and (table.find(exceptions, k) == nil) then
    --         t2[k] = nil
    --     end
    -- end
end

function rgb(values)
    converted = {}
    for i, value in ipairs(values) do
        converted[i] = value / 255
    end
    return converted
end

function round(x, n)
    return tonumber(string.format("%." .. (tonumber(n) or 0) .. "f", tonumber(x)))
end

function randompoint(center_x, center_y, radius)
    local r = radius * math.sqrt(math.random())
    local theta = math.random() * math.rad(360)
    local x = center_x + r * math.cos(theta)
    local y = center_y + r * math.sin(theta)
    return x, y
end

function applyFont(font)
    if not previousFonts then
        previousFonts = {}
    end
    table.insert(previousFonts, love.graphics.getFont())
    love.graphics.setFont(font)
end

function removeFont()
    if previousFonts then
        love.graphics.setFont(previousFonts[#previousFonts])
        table.remove(previousFonts, #previousFonts)
    end
end

function withFont(font, func)
    applyFont(font)
    func()
    removeFont()
end

function math.angle(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    local theta = math.atan2(dy, dx)
    --theta = math.deg(theta)
    return theta
end

function math.gcf(numbers)
    if type(numbers) ~= 'table' then
      error('expected argument of type table but got ' .. type(numbers))
      return
    end
    
    if #numbers < 2 then
      error('expected argument to have at least 2 elements')
      return
    end
  
    local a, b, i = numbers[1], numbers[2], 3
  
    while i <= #numbers do
        a, b = numbers[i], a % numbers[i]

        if (a == 1) or (b == 1) then
            b = 1
            break
        end
        if (a == 0) then
            a, b = b, a
        end
        i = i + 1
    end
  
    while b > 1 do
        local x = b
        a, b = b, a % b
    end
  
    if (b == 0) then
        a, b = b, a
    end
  
    return b
end

function clamp(x, min, max)
return x < min and min or (x > max and max or x)
end

function packed(v, min, max)
    return (v >= min) and (v <= max)
end

function zfill(str, n)
    return string.format("%0" ..tostring(n) ..'d', tostring(str))
end

function Bar(data, value, x, y, width, height, color)
    data.value = data.value or value
    data.max = data.max or 1
    data.min = data.min or 0
    data.x = data.x or x
    data.y = data.y or y
    data.width = data.width or data.w or width
    data.height = data.height or data.h or height
    data.color = data.color or color or {1, 0, 0}
    assert(data.value, "Bar needs a value")
    assert(data.x, "Bar needs an x position")
    assert(data.y, "Bar needs a y position")
    assert(data.width, "Bar needs a width")
    assert(data.height, "Bar needs a height")
    local delta = data.max - data.min
    if #data.color == 3 then table.insert(data.color, 1) end
    data.value = clamp(data.value, data.min, data.max)
    love.graphics.setColor(data.color)
    love.graphics.rectangle("fill", data.x, data.y, data.width, data.height)
    love.graphics.setColor(data.color[1] - 0.15, data.color[2] - 0.15,
        data.color[3] - 0.15, data.color[4])
    love.graphics.rectangle("fill", data.x, data.y, data.value / delta * data.width, data.height)
    love.graphics.setColor(1, 1, 1, 1)
end

function table.equals(a, b)
    local function equaltables(t1,t2)
        if t1 == t2 then
            return true
        end
        for k, v in pairs(t1) do
            if type(t1[k]) ~= type(t2[k]) then
                return false
            end

            if type(t1[k]) == "table" then
                if not equaltables(t1[k], t2[k]) then
                    return false
                end
            else
                if t1[k] ~= t2[k] then
                    return false
                end
            end
        end
        for k, v in pairs(t2) do
            if type(t2[k]) ~= type(t1[k]) then
                return false
            end
            if type(t2[k]) == "table" then
                if not equaltables(t2[k], t1[k]) then
                    return false
                end
            else
                if t2[k] ~= t1[k] then
                    return false
                end
            end
        end
        return true
    end
    if type(a) ~= type(b) then
        return false
    end
 
    if type(a) == "table" then
        return equaltables(a,b)
    else
        return (a == b)
    end
end

function table.copy(t, scope)
    scope = scope or ""
	local copy = {}
	for k, v in pairs(t) do
		if type(v) == "table" and not scope:find('.__index') then
			v = table.copy(v, scope .. tostring(k) .. ".")
		end
		copy[k] = v
	end
	return copy
end

function table.slice(t, start, stop, step)
    local sliced = {}
    for i = start or 1, stop or #t, step or 1 do
        if i < 0 then
            i = #t + 1 + i
        end
        sliced[#sliced+1] = t[i]
    end
    return sliced
end