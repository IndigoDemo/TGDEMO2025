-- Smart functions library (C) Indigo 2025
local ilib = {}


--- Easing Function

function ilib.transition(start, finish, time, duration, easingType)
    local t = math.max(0, math.min(time, duration)) / duration
    easingType = easingType or "linear"

    if easingType == "linear" then
        return start + (finish - start) * t

    elseif easingType == "easeIn" then
        return start + (finish - start) * (t^3)
        
    elseif easingType == "easeOut" then
        return start + (finish - start) * (1 - (1-t)^3)
        
    elseif easingType == "easeInOut" then
        if t < 0.5 then
            return start + (finish - start) * (4 * t^3)
        else
            return start + (finish - start) * (1 - 4 * (1-t)^3)
        end
        
    elseif easingType == "elastic" then
        local p = 0.3 -- Period
        return start + (finish - start) * (
            math.sin(13 * math.pi/2 * t) * math.pow(2, 10 * (t - 1)) + 1
        )
        
    elseif easingType == "bounce" then
        local t2 = t
        if t2 < 1/2.75 then
            return start + (finish - start) * (7.5625 * t2 * t2)
        elseif t2 < 2/2.75 then
            t2 = t2 - 1.5/2.75
            return start + (finish - start) * (7.5625 * t2 * t2 + 0.75)
        elseif t2 < 2.5/2.75 then
            t2 = t2 - 2.25/2.75
            return start + (finish - start) * (7.5625 * t2 * t2 + 0.9375)
        else
            t2 = t2 - 2.625/2.75
            return start + (finish - start) * (7.5625 * t2 * t2 + 0.984375)
        end
    end
    
    -- Fallback to linear if invalid easing type
    return start + (finish - start) * t
end

--- Indexed Palette
function ilib.createPalette()
    local palette = {}
    for i = 1, 256 do
        -- Use i-1 in calculations but store at index i (1-based)
        local j = i - 1
        local r = 0.5 + 0.5 * math.sin(j / 16.0)
        local g = 0.5 + 0.5 * math.sin(j / 20.0 + 2.1)
        local b = 0.5 + 0.5 * math.sin(j / 25.0 + 4.2)
        palette[i] = {r, g, b}
    end
    return palette
end

return ilib