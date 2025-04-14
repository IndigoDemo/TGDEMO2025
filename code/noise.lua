
local noise = {}

local p = {}
local perm = {}

function noise.init(seed)
    math.randomseed(seed or os.time())
    
    
    for i = 0, 255 do
        p[i] = i
    end
    
   
    for i = 255, 1, -1 do
        local j = math.floor(math.random() * (i + 1))
        p[i], p[j] = p[j], p[i]
    end
    
    for i = 0, 255 do
        perm[i] = p[i % 256]
        perm[i + 256] = p[i % 256]
    end
end

noise.init()


local function fade(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end


local function lerp(t, a, b)
    return a + t * (b - a)
end


local function grad(hash, x, y, z)
    local h = hash % 16
    local u = h < 8 and x or y
    local v = h < 4 and y or ((h == 12 or h == 14) and x or z)
    return ((h % 2) == 0 and u or -u) + ((h % 3) == 0 and v or -v)
end


function noise.perlin2(x, y)
    local X = math.floor(x) % 256
    local Y = math.floor(y) % 256
    x = x - math.floor(x)
    y = y - math.floor(y)
    local u = fade(x)
    local v = fade(y)
    local A = perm[X] + Y
    local B = perm[X + 1] + Y
    
    return lerp(v, 
               lerp(u, grad(perm[A], x, y, 0), 
                      grad(perm[B], x-1, y, 0)),
               lerp(u, grad(perm[A + 1], x, y-1, 0),
                      grad(perm[B + 1], x-1, y-1, 0)))
end


function noise.perlin3(x, y, z)
    
    local X = math.floor(x) % 256
    local Y = math.floor(y) % 256
    local Z = math.floor(z) % 256
    
   
    x = x - math.floor(x)
    y = y - math.floor(y)
    z = z - math.floor(z)
    
   
    local u = fade(x)
    local v = fade(y)
    local w = fade(z)
    
   
    local A = perm[X] + Y
    local AA = perm[A] + Z
    local AB = perm[A + 1] + Z
    local B = perm[X + 1] + Y
    local BA = perm[B] + Z
    local BB = perm[B + 1] + Z
    
   
    return lerp(w, 
               lerp(v, 
                   lerp(u, grad(perm[AA], x, y, z),
                          grad(perm[BA], x-1, y, z)),
                   lerp(u, grad(perm[AB], x, y-1, z),
                          grad(perm[BB], x-1, y-1, z))),
               lerp(v, 
                   lerp(u, grad(perm[AA + 1], x, y, z-1),
                          grad(perm[BA + 1], x-1, y, z-1)),
                   lerp(u, grad(perm[AB + 1], x, y-1, z-1),
                          grad(perm[BB + 1], x-1, y-1, z-1))))
end

function noise.octavePerlin2(x, y, octaves, persistence)
    local total = 0
    local frequency = 1
    local amplitude = 1
    local maxValue = 0
    
    for i = 1, octaves do
        total = total + noise.perlin2(x * frequency, y * frequency) * amplitude
        maxValue = maxValue + amplitude
        amplitude = amplitude * persistence
        frequency = frequency * 2
    end
    
    return total / maxValue
end

return noise
