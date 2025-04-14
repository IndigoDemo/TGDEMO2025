local f = {}

function f.normalize(v)
    local length = math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
    return {
        x = v.x / length,
        y = v.y / length,
        z = v.z / length
    }
end

function f.toRGB(r,g,b)
    if r == 0 then r = 0.01 end
    if g == 0 then g = 0.01 end
    if b == 0 then b = 0.01 end
    local table = {r*.0039,g*.0039,b*.0039}
    return table 
end

function f.diff(a,b)
    return math.abs(a-b)
end


function f.calculateNormal(v1, v2, v3)
    local ax = v2.x - v1.x
    local ay = v2.y - v1.y
    local az = v2.z - v1.z
    
    local bx = v3.x - v1.x
    local by = v3.y - v1.y
    local bz = v3.z - v1.z
    local nx = (ay * bz) - (az * by)
    local ny = (az * bx) - (ax * bz)
    local nz = (ax * by) - (ay * bx)
    local length = math.sqrt(nx * nx + ny * ny + nz * nz)
    return {
        x = nx / length,
        y = ny / length,
        z = nz / length
    }
end

function f.project3Dto2D(x, y, z)
 
    local effectiveZ = math.max(z, 0.1)
    local perspective = 500 
    local vanishingPointY = horizonY
    local scale = perspective / effectiveZ
    local screenX = width/2 + x * scale
    local screenY = vanishingPointY + (cameraY - y) * scale
    return screenX, screenY
end


return f